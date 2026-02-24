#!/usr/bin/env bash
# publish_all.sh
# Executa todos os workflows do livro si-md2:
#   A. Renderiza PDF -> move para _book_pdf/
#   B. Renderiza HTML -> publica no GitHub Pages
#   C. Gera EPUB com referências por capítulo -> move para _book_epub/
#   D. Gera notebooks para alunos (Jupyter/Colab)
#   E. Commit e push para o GitHub
#
# Estrutura esperada:
#   si-md2/           ← raiz do repositório git (.git/ está aqui)
#   └── si-md2/       ← pasta de edição (este script, _quarto.yml, etc.)

set -e  # Para em caso de erro

# Pasta de edição: onde este script está (si-md2/si-md2/)
EDIT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Raiz do repositório git: um nível acima (si-md2/)
GIT_DIR="$(cd "$EDIT_DIR/.." && pwd)"

REPO="https://github.com/fzampirolli/si-md2.git"
BIB="references.bib"
EPUB_DIR="_epub_src"
ALUNOS_DIR="notebooks_alunos"
BOOK_PDF="_book_pdf"
BOOK_EPUB="_book_epub"
BOOK_HTML="_book"

# Cores para log
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*"; }
ok()   { echo -e "${GREEN}✔ $*${NC}"; }
fail() { echo -e "${RED}✘ $*${NC}"; exit 1; }

# ---------------------------------------------------------------------------
# Garante que os comandos Quarto/Python rodam na pasta de edição
# ---------------------------------------------------------------------------
cd "$EDIT_DIR"
log "Pasta de edição : $EDIT_DIR"
log "Raiz do git     : $GIT_DIR"

# ---------------------------------------------------------------------------
# Verifica dependências
# ---------------------------------------------------------------------------
log "Verificando dependências..."
command -v quarto  >/dev/null || fail "quarto não encontrado"
command -v python3 >/dev/null || fail "python3 não encontrado"
command -v git     >/dev/null || fail "git não encontrado"
[ -f "$BIB" ]        || fail "$BIB não encontrado"
[ -f "_quarto.yml" ] || fail "_quarto.yml não encontrado"
ok "Dependências OK"

# ---------------------------------------------------------------------------
# Workflow A: PDF -> _book_pdf/
# ---------------------------------------------------------------------------
log "=== Workflow A: Renderizando PDF ==="
quarto render --to pdf
rm -rf "$BOOK_PDF"
mv "$BOOK_HTML" "$BOOK_PDF"
ok "PDF movido para $BOOK_PDF/"

# ---------------------------------------------------------------------------
# Workflow B: HTML + GitHub Pages (fica em _book/)
# ---------------------------------------------------------------------------
log "=== Workflow B: Renderizando HTML ==="
quarto render --to html
ok "HTML gerado em $BOOK_HTML/"

log "=== Workflow B: Publicando no GitHub Pages ==="
quarto publish gh-pages --no-prompt --no-browser
ok "Publicado em https://fzampirolli.github.io/si-md2/"

# ---------------------------------------------------------------------------
# Workflow C: EPUB -> _book_epub/
# ---------------------------------------------------------------------------
# FORMATAÇÃO DE TEXTO - NÃO FUNCIONA NO EPUB
# ---------------------------------------------------------------------------
# log "=== Workflow C: Pré-processando notebooks para EPUB ==="
# python3 gerar_notebooks_alunos.py --epub "$BIB" --out-dir "$EPUB_DIR"
# ok "Notebooks EPUB gerados em $EPUB_DIR/"

# log "=== Workflow C: Renderizando EPUB ==="
# ./render_epub.sh
# rm -rf "$BOOK_EPUB"
# mkdir -p "$BOOK_EPUB"
# mv "$BOOK_HTML"/*.epub "$BOOK_EPUB/" 2>/dev/null || true
# ok "EPUB movido para $BOOK_EPUB/"

# ---------------------------------------------------------------------------
# Workflow D: Notebooks para alunos (Jupyter/Colab)
# ---------------------------------------------------------------------------
log "=== Workflow D: Gerando notebooks para alunos ==="
python3 gerar_notebooks_alunos.py --batch "$BIB"
ok "Notebooks gerados em $ALUNOS_DIR/"

# ---------------------------------------------------------------------------
# Workflow E: Commit e push para o GitHub (na raiz do repositório)
# ---------------------------------------------------------------------------
log "=== Workflow E: Enviando para o GitHub ==="
cd "$GIT_DIR"

git remote get-url origin &>/dev/null || git remote add origin "$REPO"

git add -A

MSG="Publicação automática: $(date '+%Y-%m-%d %H:%M')"
git commit -m "$MSG" || { ok "Nada a commitar."; }

git push origin HEAD
ok "Push para $REPO concluído"

# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Todos os workflows concluídos com sucesso!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  PDF      : $EDIT_DIR/$BOOK_PDF/"
echo "  HTML     : $EDIT_DIR/$BOOK_HTML/"
echo "  EPUB     : $EDIT_DIR/$BOOK_EPUB/"
echo "  Alunos   : $EDIT_DIR/$ALUNOS_DIR/"
echo "  Site     : https://fzampirolli.github.io/si-md2/"
echo "  GitHub   : $REPO"