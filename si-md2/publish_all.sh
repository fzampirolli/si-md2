#!/usr/bin/env bash
# publish_all.sh atualizado para incluir PDF no GitHub Pages

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
# Workflow 1: Gerar PDF Primeiro
# ---------------------------------------------------------------------------
log "=== Workflow 1: Gerar PDF ==="
if quarto render --to pdf; then
    # O Quarto renderiza para _book, então movemos para _book_pdf conforme sua estrutura
    rm -rf "$BOOK_PDF"
    mv "$BOOK_HTML" "$BOOK_PDF"
    
    FILE_NAME="Sistemas-Inteligentes-e-Mineração-de-Dados.pdf"
    SOURCE_PATH="$BOOK_PDF/$FILE_NAME"
    
    if [ -f "$SOURCE_PATH" ]; then
        # Copia para a raiz do EDIT_DIR para ser capturado pelo render do HTML
        cp "$SOURCE_PATH" "livro.pdf"
        # Copia para a raiz do GIT_DIR para o histórico do GitHub
        cp "$SOURCE_PATH" "$GIT_DIR/livro.pdf"
        ok "PDF gerado e preparado."
    else
        fail "PDF não encontrado após renderização."
    fi
else
    fail "Erro no render do PDF."
fi

# ---------------------------------------------------------------------------
# Workflow 2: HTML + GitHub Pages
# ---------------------------------------------------------------------------
log "=== Workflow 2: Publicar HTML + PDF ==="
{
    # Renderiza o HTML (isso incluirá o livro.pdf se ele estiver listado no _quarto.yml)
    quarto render --to html
    
    # IMPORTANTE: Copia o livro.pdf para dentro da pasta que será publicada
    cp "livro.pdf" "$BOOK_HTML/"
    
    # Publica o conteúdo de _book (que agora contém o livro.pdf)
    quarto publish gh-pages --no-prompt --no-browser
    ok "Site e PDF publicados no GitHub Pages."
} || {
    log "${RED}Falha na publicação das páginas.${NC}"
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