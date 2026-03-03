#!/usr/bin/env bash
###############################################################################
# cleanup-app-registrations.sh
#
# Supprime les App Registrations créées par setup-app-registrations.sh.
# Utile pour repartir de zéro ou pour nettoyer après le lab.
#
# Usage :
#   ./cleanup-app-registrations.sh
###############################################################################
set -euo pipefail

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
command -v az >/dev/null 2>&1 || error "Azure CLI (az) n'est pas installé."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env.setup"

if [ ! -f "$ENV_FILE" ]; then
  error "Fichier .env.setup introuvable. Rien à nettoyer."
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

header "🧹 Nettoyage des App Registrations"

echo -e "${RED}${BOLD}⚠️  ATTENTION : Cette action est irréversible !${NC}"
echo ""
echo "Les App Registrations suivantes seront supprimées :"
echo "  • Hello World API  (${API_CLIENT_ID:-inconnu})"
echo "  • Hello API Client (${CLIENT_CLIENT_ID:-inconnu})"
echo "  • hello-angular    (${SPA_CLIENT_ID:-inconnu})"
echo ""
read -rp "Confirmez-vous la suppression ? (oui/non) : " CONFIRM

if [ "$CONFIRM" != "oui" ]; then
  info "Annulé."
  exit 0
fi

# ── Supprimer hello-angular ──────────────────────────────────────────────────
if [ -n "${SPA_OBJECT_ID:-}" ]; then
  info "Suppression de 'hello-angular'..."
  az ad app delete --id "$SPA_OBJECT_ID" 2>/dev/null \
    && success "hello-angular supprimée" \
    || warn "Échec de la suppression de hello-angular (peut-être déjà supprimée)"
fi

# ── Supprimer Hello API Client ───────────────────────────────────────────────
if [ -n "${CLIENT_OBJECT_ID:-}" ]; then
  info "Suppression de 'Hello API Client'..."
  az ad app delete --id "$CLIENT_OBJECT_ID" 2>/dev/null \
    && success "Hello API Client supprimée" \
    || warn "Échec de la suppression de Hello API Client (peut-être déjà supprimée)"
fi

# ── Supprimer Hello World API ────────────────────────────────────────────────
if [ -n "${API_OBJECT_ID:-}" ]; then
  info "Suppression de 'Hello World API'..."
  az ad app delete --id "$API_OBJECT_ID" 2>/dev/null \
    && success "Hello World API supprimée" \
    || warn "Échec de la suppression de Hello World API (peut-être déjà supprimée)"
fi

# ── Nettoyer les fichiers ────────────────────────────────────────────────────
info "Nettoyage des fichiers de configuration générés..."

[ -f "${SCRIPT_DIR}/hello-api/.env" ]                && rm "${SCRIPT_DIR}/hello-api/.env" && success "hello-api/.env supprimé"
[ -f "${SCRIPT_DIR}/hello-client/.env" ]              && rm "${SCRIPT_DIR}/hello-client/.env" && success "hello-client/.env supprimé"
[ -f "${SCRIPT_DIR}/hello-angular/public/config.json" ] && rm "${SCRIPT_DIR}/hello-angular/public/config.json" && success "hello-angular/public/config.json supprimé"
rm "$ENV_FILE" && success ".env.setup supprimé"

echo ""
success "🏁 Nettoyage terminé."
echo ""
echo -e "${YELLOW}Note : Les App Registrations supprimées restent dans la corbeille${NC}"
echo -e "${YELLOW}Entra ID pendant 30 jours. Pour les supprimer définitivement :${NC}"
echo -e "${YELLOW}  Azure Portal → Entra ID → App registrations → Deleted applications${NC}"
echo ""
