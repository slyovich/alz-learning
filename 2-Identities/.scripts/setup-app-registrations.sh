#!/usr/bin/env bash
###############################################################################
# setup-app-registrations.sh
#
# Automatise la création et la configuration des App Registrations Entra ID
# décrites dans le document "Lab — Identities & App Registrations".
#
# Prérequis :
#   - Azure CLI (az) installé et connecté : az login
#   - jq installé (brew install jq)
#   - Droits suffisants sur Entra ID (Application Administrator ou Global Admin)
#
# Usage :
#   chmod +x setup-app-registrations.sh
#   ./setup-app-registrations.sh
#
# Le script génère un fichier .env.setup avec toutes les valeurs produites.
###############################################################################
set -euo pipefail

API_NAME="hello-api"
CLIENT_NAME="hello-client"
SPA_NAME="hello-angular"

# ─── Couleurs ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${NC}"; }
error()   { echo -e "${RED}❌ $*${NC}"; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════════════${NC}"; echo -e "${BOLD}${CYAN}  $*${NC}"; echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════${NC}\n"; }

# ─── Vérifications ───────────────────────────────────────────────────────────
command -v az >/dev/null 2>&1  || error "Azure CLI (az) n'est pas installé."
command -v jq >/dev/null 2>&1  || error "jq n'est pas installé. Installez-le avec : brew install jq"

# Vérifier que l'utilisateur est connecté
az account show >/dev/null 2>&1 || error "Vous n'êtes pas connecté à Azure CLI. Exécutez : az login"

# ─── Récupération du Tenant ID ──────────────────────────────────────────────
TENANT_ID=$(az account show --query tenantId -o tsv)
info "Tenant ID détecté : ${BOLD}${TENANT_ID}${NC}"

# ─── Fichier de sortie ──────────────────────────────────────────────────────
OUTPUT_FILE="$(dirname "$0")/.env.setup"
echo "# Généré par setup-app-registrations.sh le $(date -Iseconds)" > "$OUTPUT_FILE"
echo "AZURE_TENANT_ID=${TENANT_ID}" >> "$OUTPUT_FILE"

###############################################################################
# PARTIE 1 — App Registration : Hello World API
###############################################################################
header "📦 PARTIE 1 — App Registration : Hello World API"

# ── Étape 1.1 — Créer l'App Registration ────────────────────────────────────
info "Étape 1.1 — Création de l'App Registration 'Hello World API'..."

API_APP=$(az ad app create \
  --display-name $API_NAME \
  --sign-in-audience "AzureADMyOrg" \
  --output json)

API_CLIENT_ID=$(echo "$API_APP" | jq -r '.appId')
API_OBJECT_ID=$(echo "$API_APP" | jq -r '.id')

success "App Registration créée : $API_NAME"
info "  Application (client) ID : ${BOLD}${API_CLIENT_ID}${NC}"
info "  Object ID               : ${BOLD}${API_OBJECT_ID}${NC}"

echo "API_CLIENT_ID=${API_CLIENT_ID}" >> "$OUTPUT_FILE"
echo "API_OBJECT_ID=${API_OBJECT_ID}" >> "$OUTPUT_FILE"

# ── Étape 1.2 — Configurer de l'api (Access Tokens v2 + Scopes) ─────────────────────────────
info "Étape 1.2 — Configuration de l'api (Access Tokens v2 + Scopes)"

API_IDENTIFIER_URI="api://${API_CLIENT_ID}"

SCOPE_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
API=$(cat <<EOF
{
  "acceptMappedClaims": null,
  "knownClientApplications": [],
  "requestedAccessTokenVersion": 2,
  "oauth2PermissionScopes": [
    {
      "adminConsentDescription": "Allow the application to access Hello API on behalf of the signed-in user",
      "adminConsentDisplayName": "Access Hello API",
      "id": "${SCOPE_ID}",
      "isEnabled": true,
      "type": "User",
      "userConsentDescription": "Allow the application to access Hello API on your behalf",
      "userConsentDisplayName": "Access Hello API",
      "value": "access_as_user"
    }
  ],
  "preAuthorizedApplications": []
}
EOF
)

az ad app update \
  --id "$API_OBJECT_ID" \
  --identifier-uris "$API_IDENTIFIER_URI" \
  --set api="$API"

success "Access Token version configurée à v2"
success "Scope délégué 'access_as_user' créé"
info "  Scope ID         : ${BOLD}${SCOPE_ID}${NC}"
info "  Application URI  : ${BOLD}${API_IDENTIFIER_URI}${NC}"

echo "API_IDENTIFIER_URI=${API_IDENTIFIER_URI}" >> "$OUTPUT_FILE"
echo "SCOPE_ID=${SCOPE_ID}" >> "$OUTPUT_FILE"

# ── Étape 1.3 — Définir les App Roles ───────────────────────────────────────
info "Étape 1.3 — Création des App Roles..."

# Générer des UUID pour les rôles
HELLO_READ_ROLE_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
USER_READ_ROLE_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

APP_ROLES_JSON=$(cat <<EOF
[
  {
    "allowedMemberTypes": ["User", "Application"],
    "description": "Can call the hello endpoints",
    "displayName": "Hello Reader",
    "isEnabled": true,
    "value": "Hello.Read",
    "id": "${HELLO_READ_ROLE_ID}"
  },
  {
    "allowedMemberTypes": ["User", "Application"],
    "description": "Can call the /me endpoint",
    "displayName": "User Profile Reader",
    "isEnabled": true,
    "value": "User.Read",
    "id": "${USER_READ_ROLE_ID}"
  }
]
EOF
)

az ad app update \
  --id "$API_OBJECT_ID" \
  --app-roles "$APP_ROLES_JSON"

success "App Roles créés :"
info "  Hello.Read (${HELLO_READ_ROLE_ID})"
info "  User.Read  (${USER_READ_ROLE_ID})"

echo "HELLO_READ_ROLE_ID=${HELLO_READ_ROLE_ID}" >> "$OUTPUT_FILE"
echo "USER_READ_ROLE_ID=${USER_READ_ROLE_ID}" >> "$OUTPUT_FILE"

# ── Créer le Service Principal pour l'API ────────────────────────────────────
info "Création du Service Principal pour '$API_NAME'..."

API_SP=$(az ad sp create --id "$API_CLIENT_ID" --output json 2>/dev/null || true)
if [ -z "$API_SP" ] || [ "$API_SP" = "" ]; then
  API_SP=$(az ad sp show --id "$API_CLIENT_ID" --output json)
fi
API_SP_OBJECT_ID=$(echo "$API_SP" | jq -r '.id')

success "Service Principal créé pour $API_NAME"
info "  SP Object ID : ${BOLD}${API_SP_OBJECT_ID}${NC}"

echo "API_SP_OBJECT_ID=${API_SP_OBJECT_ID}" >> "$OUTPUT_FILE"

###############################################################################
# PARTIE 2 — App Registration : Hello API Client (Service Principal)
###############################################################################
header "📦 PARTIE 2 — App Registration : $CLIENT_NAME"

# ── Étape 1.4 — Créer l'App Registration du Client ──────────────────────────
info "Étape 1.4 — Création de l'App Registration '$CLIENT_NAME'..."

CLIENT_APP=$(az ad app create \
  --display-name $CLIENT_NAME \
  --sign-in-audience "AzureADMyOrg" \
  --output json)

CLIENT_CLIENT_ID=$(echo "$CLIENT_APP" | jq -r '.appId')
CLIENT_OBJECT_ID=$(echo "$CLIENT_APP" | jq -r '.id')

success "App Registration créée : $CLIENT_NAME"
info "  Application (client) ID : ${BOLD}${CLIENT_CLIENT_ID}${NC}"
info "  Object ID               : ${BOLD}${CLIENT_OBJECT_ID}${NC}"

echo "CLIENT_CLIENT_ID=${CLIENT_CLIENT_ID}" >> "$OUTPUT_FILE"
echo "CLIENT_OBJECT_ID=${CLIENT_OBJECT_ID}" >> "$OUTPUT_FILE"

# ── Créer un Client Secret ──────────────────────────────────────────────────
info "Création du client secret pour '$CLIENT_NAME'..."

CLIENT_SECRET_JSON=$(az ad app credential reset \
  --id "$CLIENT_OBJECT_ID" \
  --display-name "Lab secret" \
  --years 1 \
  --output json)

CLIENT_SECRET=$(echo "$CLIENT_SECRET_JSON" | jq -r '.password')

success "Client Secret créé"
warn "Valeur du secret : ${BOLD}${CLIENT_SECRET}${NC}"
warn "⚠️  COPIEZ CETTE VALEUR ! Elle ne sera plus accessible après."

echo "CLIENT_SECRET=${CLIENT_SECRET}" >> "$OUTPUT_FILE"

# ── Créer le Service Principal pour le Client ────────────────────────────────
info "Création du Service Principal pour '$CLIENT_NAME'..."

CLIENT_SP=$(az ad sp create --id "$CLIENT_CLIENT_ID" --output json 2>/dev/null || true)
if [ -z "$CLIENT_SP" ] || [ "$CLIENT_SP" = "" ]; then
  CLIENT_SP=$(az ad sp show --id "$CLIENT_CLIENT_ID" --output json)
fi
CLIENT_SP_OBJECT_ID=$(echo "$CLIENT_SP" | jq -r '.id')

success "Service Principal créé pour $CLIENT_NAME"
info "  SP Object ID : ${BOLD}${CLIENT_SP_OBJECT_ID}${NC}"

echo "CLIENT_SP_OBJECT_ID=${CLIENT_SP_OBJECT_ID}" >> "$OUTPUT_FILE"

# ── Étape 1.5 — Ajouter les API Permissions (Application permissions) ───────
info "Étape 1.5 — Ajout des permissions applicatives (Hello.Read, User.Read)..."

# Ajouter la permission Hello.Read
az ad app permission add \
  --id "$CLIENT_OBJECT_ID" \
  --api "$API_CLIENT_ID" \
  --api-permissions "${HELLO_READ_ROLE_ID}=Role"

# Ajouter la permission User.Read
az ad app permission add \
  --id "$CLIENT_OBJECT_ID" \
  --api "$API_CLIENT_ID" \
  --api-permissions "${USER_READ_ROLE_ID}=Role"

success "Permissions applicatives ajoutées (Hello.Read, User.Read)"

# ── Accorder le consentement admin ───────────────────────────────────────────
info "Accord du consentement admin..."

# Attendre quelques secondes pour la propagation
info "Attente de 10 secondes pour la propagation dans Entra ID..."
sleep 10

az ad app permission admin-consent --id "$CLIENT_OBJECT_ID"

success "Consentement admin accordé pour $CLIENT_NAME"

###############################################################################
# PARTIE 3 — App Registration : hello-angular (SPA)
###############################################################################
header "📦 PARTIE 3 — App Registration : $SPA_NAME (SPA)"

# ── Étape 3.2 — Créer l'App Registration SPA ────────────────────────────────
info "Étape 3.2 — Création de l'App Registration '$SPA_NAME'..."

SPA_APP=$(az ad app create \
  --display-name $SPA_NAME \
  --sign-in-audience "AzureADMyOrg" \
  --output json)

SPA_CLIENT_ID=$(echo "$SPA_APP" | jq -r '.appId')
SPA_OBJECT_ID=$(echo "$SPA_APP" | jq -r '.id')

# Configurer la Redirect URI en tant que SPA (pas Web)
az rest \
  --method PATCH \
  --uri "https://graph.microsoft.com/v1.0/applications/${SPA_OBJECT_ID}" \
  --headers "Content-Type=application/json" \
  --body '{
    "spa": {
      "redirectUris": ["http://localhost:4200"]
    }
  }'

success "App Registration SPA créée : $SPA_NAME"
info "  Application (client) ID : ${BOLD}${SPA_CLIENT_ID}${NC}"
info "  Object ID               : ${BOLD}${SPA_OBJECT_ID}${NC}"
info "  Redirect URI (SPA)      : ${BOLD}http://localhost:4200${NC}"

echo "SPA_CLIENT_ID=${SPA_CLIENT_ID}" >> "$OUTPUT_FILE"
echo "SPA_OBJECT_ID=${SPA_OBJECT_ID}" >> "$OUTPUT_FILE"

# ── Créer le Service Principal pour la SPA ───────────────────────────────────
info "Création du Service Principal pour '$SPA_NAME'..."

SPA_SP=$(az ad sp create --id "$SPA_CLIENT_ID" --output json 2>/dev/null || true)
if [ -z "$SPA_SP" ] || [ "$SPA_SP" = "" ]; then
  SPA_SP=$(az ad sp show --id "$SPA_CLIENT_ID" --output json)
fi

success "Service Principal créé pour $SPA_NAME"

# ── Étape 3.3 — Ajouter les permissions déléguées ───────────────────────────
info "Étape 3.3 — Ajout de la permission déléguée (access_as_user)..."

az ad app permission add \
  --id "$SPA_OBJECT_ID" \
  --api "$API_CLIENT_ID" \
  --api-permissions "${SCOPE_ID}=Scope"

success "Permission déléguée 'access_as_user' ajoutée à $SPA_NAME"

# ── Étape 3.4 — Pré-autoriser la SPA sur l'API ──────────────────────────────
info "Étape 3.4 — Pré-autorisation de $SPA_NAME sur $API_NAME..."

# La pré-autorisation se fait sur l'App Registration de l'API via MS Graph
az rest \
  --method PATCH \
  --uri "https://graph.microsoft.com/v1.0/applications/${API_OBJECT_ID}" \
  --headers "Content-Type=application/json" \
  --body "{
    \"api\": {
      \"preAuthorizedApplications\": [
        {
          \"appId\": \"${SPA_CLIENT_ID}\",
          \"delegatedPermissionIds\": [\"${SCOPE_ID}\"]
        }
      ]
    }
  }"

success "$SPA_NAME est pré-autorisée sur $API_NAME"

###############################################################################
# RÉSUMÉ
###############################################################################
header "🎉 CONFIGURATION TERMINÉE"

echo -e "${BOLD}┌─────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}│                    Résumé des App Registrations                     │${NC}"
echo -e "${BOLD}├─────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BOLD}│${NC}                                                                     ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}  ${CYAN}$API_NAME${NC}                                                    ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    Client ID  : ${API_CLIENT_ID}                      ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    Token      : v2                                                   ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    App Roles  : Hello.Read, User.Read                                ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    Scope      : access_as_user                                       ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}                                                                     ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}  ${CYAN}$CLIENT_NAME${NC}                                                   ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    Client ID  : ${CLIENT_CLIENT_ID}                      ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    Secret     : ${CLIENT_SECRET:0:8}...                                         ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    Permissions: Hello.Read (App), User.Read (App)                    ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    Consent    : Admin ✅                                             ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}                                                                     ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}  ${CYAN}$SPA_NAME${NC}                                                      ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    Client ID  : ${SPA_CLIENT_ID}                      ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    Redirect   : http://localhost:4200 (SPA)                          ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    Permission : access_as_user (Delegated)                           ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}    Pre-auth   : ✅                                                   ${BOLD}│${NC}"
echo -e "${BOLD}│${NC}                                                                     ${BOLD}│${NC}"
echo -e "${BOLD}└─────────────────────────────────────────────────────────────────────┘${NC}"

echo ""
info "Toutes les valeurs ont été sauvegardées dans : ${BOLD}${OUTPUT_FILE}${NC}"
echo ""

###############################################################################
# Génération des fichiers .env pour les projets
###############################################################################
header "📝 Génération des fichiers de configuration pour les projets"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── hello-api/.env ───────────────────────────────────────────────────────────
HELLO_API_ENV="${SCRIPT_DIR}/../hello-api/.env"
if [ -d "${SCRIPT_DIR}/../hello-api" ]; then
  cat > "$HELLO_API_ENV" <<EOF
AZURE_TENANT_ID=${TENANT_ID}
AZURE_CLIENT_ID=${API_CLIENT_ID}
EOF
  success "Fichier créé : hello-api/.env"
else
  warn "Dossier hello-api/ introuvable — fichier .env non créé"
fi

# ── hello-client/.env ────────────────────────────────────────────────────────
HELLO_CLIENT_ENV="${SCRIPT_DIR}/../hello-client/.env"
if [ -d "${SCRIPT_DIR}/../hello-client" ]; then
  cat > "$HELLO_CLIENT_ENV" <<EOF
AZURE_TENANT_ID=${TENANT_ID}
AZURE_CLIENT_ID=${CLIENT_CLIENT_ID}
AZURE_CLIENT_SECRET=${CLIENT_SECRET}
API_CLIENT_ID=${API_CLIENT_ID}
API_BASE_URL=http://127.0.0.1:8000
EOF
  success "Fichier créé : hello-client/.env"
else
  warn "Dossier hello-client/ introuvable — fichier .env non créé"
fi

# ── hello-angular/public/config.json ─────────────────────────────────────────
HELLO_ANGULAR_CONFIG="${SCRIPT_DIR}/../hello-angular/public/config.json"
if [ -d "${SCRIPT_DIR}/../hello-angular/public" ]; then
  cat > "$HELLO_ANGULAR_CONFIG" <<EOF
{
  "clientId": "${SPA_CLIENT_ID}",
  "tenantId": "${TENANT_ID}",
  "apiClientId": "${API_CLIENT_ID}",
  "apiBaseUrl": "http://127.0.0.1:8000"
}
EOF
  success "Fichier créé : hello-angular/public/config.json"
else
  warn "Dossier hello-angular/public/ introuvable — fichier config.json non créé"
fi

echo ""
success "🏁 Setup complet ! Vous pouvez maintenant lancer les projets."
echo ""
echo -e "${YELLOW}Prochaines étapes :${NC}"
echo -e "  1. Lancer hello-api     :  cd ../hello-api && source .venv/bin/activate && uvicorn main:app --reload"
echo -e "  2. Lancer hello-client   :  cd ../hello-client && source .venv/bin/activate && python main.py"
echo -e "  3. Lancer hello-angular  :  cd ../hello-angular && npm start"
echo ""
echo -e "${YELLOW}Pour l'étape 3.6 (assigner les App Roles aux utilisateurs) :${NC}"
echo -e "  Exécutez le script compagnon : ${BOLD}./assign-user-roles.sh <USER_EMAIL>${NC}"
echo ""
