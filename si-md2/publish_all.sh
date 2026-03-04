#!/usr/bin/env bash
# publish_all.sh com tratamento de erros (try/except style)

set -e

# Configurações de Caminhos
EDIT_DIR="$(cd "$(dirname "$0")" && pwd)"
GIT_DIR="$(cd "$EDIT_DIR/.." && pwd)"
REPO="https://github.com/fzampirolli/si-md2.git"
BIB="references.bib"
ALUNOS_DIR="notebooks_alunos"
BOOK_PDF="_book_pdf"
BOOK_HTML="_book"

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*"; }
ok()   { echo -e "${GREEN}✔ $*${NC}"; }
fail() { echo -e "${RED}✘ ERRO: $*${NC}"; exit 1; }

cd "$EDIT_DIR"

# ---------------------------------------------------------------------------
# Workflow A: HTML + GitHub Pages
# ---------------------------------------------------------------------------
log "=== Workflow A: HTML ==="
{
    quarto render --to html
    quarto publish gh-pages --no-prompt --no-browser
    ok "HTML publicado com sucesso."
} || {
    log "${RED}Falha no Workflow A (HTML). Continuando para os demais...${NC}"
}

# ---------------------------------------------------------------------------
# Workflow C: Notebooks para alunos
# ---------------------------------------------------------------------------
log "=== Workflow C: Notebooks Alunos ==="
{
    python3 gerar_notebooks_alunos.py --batch "$BIB"
    ok "Notebooks de alunos gerados."
} || {
    log "${RED}Falha no Workflow C (Alunos).${NC}"
}

# ---------------------------------------------------------------------------
# Workflow D: PDF (Simplificado e Seguro)
# ---------------------------------------------------------------------------
log "=== Workflow D: PDF ==="

if quarto render --to pdf; then
    # O Quarto gera o PDF baseado na configuração do _quarto.yml
    # Geralmente ele já sai no destino correto, mas se precisar mover:
    rm -rf "$BOOK_PDF" 
    mv "$BOOK_HTML" "$BOOK_PDF" 
    ok "PDF gerado com sucesso."
else
    log "${RED}Erro durante o render do PDF.${NC}"
fi

# ---------------------------------------------------------------------------
# Workflow E: Git Push
# ---------------------------------------------------------------------------
log "=== Workflow E: GitHub Push ==="
{
    cd "$GIT_DIR"
    git add -A
    MSG="Publicação automática: $(date '+%Y-%m-%d %H:%M')"
    git commit -m "$MSG" || echo "Nada para commitar."
    git push origin HEAD
    ok "Repositório atualizado."
} || {
    fail "Falha crítica no Workflow E (Git)."
}

cd "$EDIT_DIR"
log "${GREEN}Processo finalizado.${NC}"
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Todos os workflows concluídos com sucesso!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  HTML     : $EDIT_DIR/$BOOK_HTML/"
echo "  PDF      : $EDIT_DIR/$BOOK_PDF/"
echo "  Alunos   : $EDIT_DIR/$ALUNOS_DIR/"
echo "  Site     : https://fzampirolli.github.io/si-md2/"
echo "  GitHub   : $REPO"