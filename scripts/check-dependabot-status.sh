#!/bin/bash
# check-dependabot-status.sh - Verifica el estado de PRs de Dependabot

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🤖 Dependabot Status Checker${NC}"
echo ""

# Verificar gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: gh CLI no está instalado${NC}"
    echo "Instala desde: https://cli.github.com/"
    exit 1
fi

# Verificar que estamos en un repo
if [ ! -d .git ]; then
    echo -e "${RED}❌ Error: No estás en un repositorio git${NC}"
    exit 1
fi

echo -e "${GREEN}📊 Dependabot PRs Status${NC}"
echo ""

# Obtener PRs de Dependabot
DEPENDABOT_PRS=$(gh pr list --author "app/dependabot" --json number,title,state,labels,url,checks --limit 50)

if [ "$DEPENDABOT_PRS" == "[]" ]; then
    echo -e "${YELLOW}No hay PRs de Dependabot abiertos${NC}"
    exit 0
fi

# Contadores
TOTAL=0
AUTO_MERGE=0
MANUAL=0
FAILED=0

echo "$DEPENDABOT_PRS" | jq -r '.[] | 
    "PR #\(.number): \(.title)\n" +
    "  URL: \(.url)\n" +
    "  State: \(.state)\n" +
    "  Labels: \(.labels | map(.name) | join(", "))\n" +
    "  Checks: \(.checks | if . then map(.conclusion) | join(", ") else "No checks" end)\n"' | while IFS= read -r line; do
    echo "$line"
done

echo ""
echo -e "${BLUE}📈 Summary${NC}"

# Contar PRs por label
AUTO_MERGE=$(echo "$DEPENDABOT_PRS" | jq '[.[] | select(.labels[].name == "automerge")] | length')
MANUAL=$(echo "$DEPENDABOT_PRS" | jq '[.[] | select(.labels[].name == "automerge" | not)] | length')
TOTAL=$(echo "$DEPENDABOT_PRS" | jq 'length')

echo -e "Total PRs: ${YELLOW}$TOTAL${NC}"
echo -e "Auto-merge: ${GREEN}$AUTO_MERGE${NC}"
echo -e "Manual review: ${YELLOW}$MANUAL${NC}"

echo ""
echo -e "${BLUE}🔍 Commands${NC}"
echo "Ver detalles de un PR:"
echo "  gh pr view <NUMBER>"
echo ""
echo "Aprobar manualmente un PR:"
echo "  gh pr review <NUMBER> --approve"
echo ""
echo "Hacer merge manual:"
echo "  gh pr merge <NUMBER> --squash"
