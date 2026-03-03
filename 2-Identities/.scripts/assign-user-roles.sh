#!/usr/bin/env bash
###############################################################################
# assign-user-roles.sh
#
# Assigne les App Roles (Hello.Read, User.Read) à un utilisateur sur le
# Service Principal de Hello World API.
#
# Correspond à l'étape 3.6 du lab : "Assigner les App Roles aux utilisateurs"
#
# Prérequis :
#   - Azure CLI (az) installé et connecté
#   - jq installé
#   - Le script setup-app-registrations.sh doit avoir été exécuté (fichier .env.setup)
#
# Usage :
#   ./assign-user-roles.sh <USER_EMAIL>
#
# Exemple :
#   ./assign-user-roles.sh john.doe@contoso.com
###############################################################################
set -euo pipefail

API_NAME="Hello World API"
CLIENT_NAME="Hello API Client"
SPA_NAME="hello-angular"

# ─── Couleurs ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${NC}"; }
error()   { echo -e "${RED}❌ $*${NC}"; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════════════${NC}"; echo -e "${BOLD}${CYAN}  $*${NC}"; echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════${NC}\n"; }

# ─── Vérifications ───────────────────────────────────────────────────────────
command -v az >/dev/null 2>&1  || error "Azure CLI (az) n'est pas installé."
command -v jq >/dev/null 2>&1  || error "jq n'est pas installé."

if [ $# -lt 1 ]; then
  echo -e "${BOLD}Usage:${NC} $0 <USER_EMAIL>"
  echo -e "  Exemple : $0 john.doe@contoso.com"
  exit 1
fi

USER_EMAIL="$1"

# ─── Charger le fichier .env.setup ───────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env.setup"

if [ ! -f "$ENV_FILE" ]; then
  error "Fichier .env.setup introuvable. Exécutez d'abord setup-app-registrations.sh"
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

header "👤 Assignation des App Roles pour : ${USER_EMAIL}"

# ─── Récupérer l'ID de l'utilisateur ────────────────────────────────────────
info "Recherche de l'utilisateur dans Entra ID..."

USER_OBJECT_ID=$(az ad user show --id "$USER_EMAIL" --query id -o tsv 2>/dev/null) \
  || error "Utilisateur '${USER_EMAIL}' introuvable dans Entra ID."

success "Utilisateur trouvé"
info "  Email     : ${BOLD}${USER_EMAIL}${NC}"
info "  Object ID : ${BOLD}${USER_OBJECT_ID}${NC}"

# ─── Vérifier les variables nécessaires ──────────────────────────────────────
[ -z "${API_SP_OBJECT_ID:-}" ]    && error "API_SP_OBJECT_ID manquant dans .env.setup"
[ -z "${HELLO_READ_ROLE_ID:-}" ]  && error "HELLO_READ_ROLE_ID manquant dans .env.setup"
[ -z "${USER_READ_ROLE_ID:-}" ]   && error "USER_READ_ROLE_ID manquant dans .env.setup"

info "Service Principal de l'API : ${BOLD}${API_SP_OBJECT_ID}${NC}"

# ─── Assigner Hello.Read ────────────────────────────────────────────────────
info "Assignation du rôle 'Hello.Read' (Hello Reader)..."

az rest \
  --method POST \
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/${API_SP_OBJECT_ID}/appRoleAssignedTo" \
  --headers "Content-Type=application/json" \
  --body "{
    \"principalId\": \"${USER_OBJECT_ID}\",
    \"resourceId\": \"${API_SP_OBJECT_ID}\",
    \"appRoleId\": \"${HELLO_READ_ROLE_ID}\"
  }" \
  --output none 2>/dev/null \
  && success "Rôle 'Hello.Read' assigné" \
  || warn "Le rôle 'Hello.Read' est peut-être déjà assigné (ou une erreur s'est produite)"

# ─── Assigner User.Read ─────────────────────────────────────────────────────
info "Assignation du rôle 'User.Read' (User Profile Reader)..."

az rest \
  --method POST \
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/${API_SP_OBJECT_ID}/appRoleAssignedTo" \
  --headers "Content-Type=application/json" \
  --body "{
    \"principalId\": \"${USER_OBJECT_ID}\",
    \"resourceId\": \"${API_SP_OBJECT_ID}\",
    \"appRoleId\": \"${USER_READ_ROLE_ID}\"
  }" \
  --output none 2>/dev/null \
  && success "Rôle 'User.Read' assigné" \
  || warn "Le rôle 'User.Read' est peut-être déjà assigné (ou une erreur s'est produite)"

# ─── Vérification ───────────────────────────────────────────────────────────
header "🔍 Vérification des rôles assignés"

info "Récupération des assignations de rôles..."

ASSIGNMENTS=$(az rest \
  --method GET \
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/${API_SP_OBJECT_ID}/appRoleAssignedTo" \
  --output json)

echo "$ASSIGNMENTS" | jq -r --arg uid "$USER_OBJECT_ID" \
  '.value[] | select(.principalId == $uid) | "  ✅ \(.principalDisplayName) → Role ID: \(.appRoleId)"'

echo ""
success "🏁 Assignation terminée pour ${USER_EMAIL}"
echo ""
echo -e "${YELLOW}L'utilisateur peut maintenant :${NC}"
echo -e "  • Se connecter à hello-angular et accéder aux endpoints sécurisés"
echo -e "  • Ses tokens contiendront le claim 'roles' avec les rôles assignés"
echo ""
