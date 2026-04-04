#!/usr/bin/env bash
# publish_all.sh atualizado para incluir PDF no GitHub Pages

set -e

# Configurações de Caminhos
EDIT_DIR="$(cd "$(dirname "$0")" && pwd)"
GIT_DIR="$(cd "$EDIT_DIR/.." && pwd)"
REPO="https://github.com/fzampirolli/si-md2.git"
BIB="references.bib"
ALUNOS_DIR="notebooks_alunos"
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
# Workflow: PDF + HTML (Integrado)
# ---------------------------------------------------------------------------
log "=== Gerando PDF e HTML para Publicação ==="

# 1. Gera o PDF primeiro
# if quarto render --to pdf; then
#     # Copia o PDF com nome simples para a pasta de edição
#     # O Quarto vai "enxergar" esse arquivo durante o render do HTML
#     cp "$BOOK_HTML/Sistemas-Inteligentes-e-Mineração-de-Dados.pdf" "livro.pdf"
#     ok "PDF preparado."
# else
#     fail "Falha ao gerar o PDF."
# fi

# 2. Gera o HTML e Publica
{
    # O render HTML agora vai incluir o 'livro.pdf' por causa do _quarto.yml
    quarto render --to html
    
    # Garante que o PDF esteja fisicamente na pasta que será enviada
    cp "livro.pdf" "$BOOK_HTML/"
    
    # Publica para a branch gh-pages
    quarto publish gh-pages --no-prompt --no-browser
    ok "Site e PDF publicados com sucesso!"
} || {
    log "${RED}Falha na publicação HTML.${NC}"
}

# ---------------------------------------------------------------------------
# Workflow 3: Notebooks para alunos
# ---------------------------------------------------------------------------
log "=== Workflow 3: Notebooks Alunos ==="
{
    python3 gerar_notebooks_alunos.py --batch "$BIB"
    ok "Notebooks de alunos gerados."
} || {
    log "${RED}Falha no Workflow C (Alunos).${NC}"
}

# ---------------------------------------------------------------------------
# Workflow 4: Git Push (Repositório Principal)
# ---------------------------------------------------------------------------
log "=== Workflow 4: GitHub Push Principal ==="
{
    cd "$GIT_DIR"
    touch ".nojekyll"
    git add -A
    MSG="Publicação automática (incluindo PDF): $(date '+%Y-%m-%d %H:%M')"
    git commit -m "$MSG" || echo "Nada para commitar."
    git push origin HEAD
    ok "Código e PDF atualizados no repositório principal."
} || {
    fail "Falha crítica no Git Push."
}

cd "$EDIT_DIR"
log "${GREEN}Processo concluído com sucesso!${NC}"
echo "URL do PDF: https://fzampirolli.github.io/si-md2/livro.pdf"