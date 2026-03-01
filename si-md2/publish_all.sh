#!/usr/bin/env bash
# publish_all.sh
# Executa todos os workflows do livro si-md2:
#   A. Renderiza HTML -> publica no GitHub Pages
#   B. Gera EPUB com referências por capítulo -> move para _book_epub/
#   C. Gera notebooks para alunos (Jupyter/Colab)
#   D. Renderiza PDF -> move para _book_pdf/  
#   E. Commit e push para o GitHub
#
# O PDF é gerado por último porque requer limpar os outputs de células de
# download cacheados nos notebooks. O script clean_download_cells.py faz
# isso automaticamente, restaurando tudo após o render.
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
[ -f "$BIB" ]                   || fail "$BIB não encontrado"
[ -f "_quarto.yml" ]            || fail "_quarto.yml não encontrado"
[ -f "clean_download_cells.py" ] || fail "clean_download_cells.py não encontrado"
ok "Dependências OK"

# ---------------------------------------------------------------------------
# Workflow A: HTML + GitHub Pages (fica em _book/)
# ---------------------------------------------------------------------------
log "=== Workflow A: Renderizando HTML ==="
quarto render --to html
ok "HTML gerado em $BOOK_HTML/"

log "=== Workflow A: Publicando no GitHub Pages ==="
quarto publish gh-pages --no-prompt --no-browser
ok "Publicado em https://fzampirolli.github.io/si-md2/"

# ---------------------------------------------------------------------------
# Workflow B: EPUB -> _book_epub/
# ---------------------------------------------------------------------------
# FORMATAÇÃO DE TEXTO - NÃO FUNCIONA NO EPUB
# ---------------------------------------------------------------------------
# log "=== Workflow B: Pré-processando notebooks para EPUB ==="
# python3 gerar_notebooks_alunos.py --epub "$BIB" --out-dir "$EPUB_DIR"
# ok "Notebooks EPUB gerados em $EPUB_DIR/"

# log "=== Workflow B: Renderizando EPUB ==="
# ./render_epub.sh
# rm -rf "$BOOK_EPUB"
# mkdir -p "$BOOK_EPUB"
# mv "$BOOK_HTML"/*.epub "$BOOK_EPUB/" 2>/dev/null || true
# ok "EPUB movido para $BOOK_EPUB/"

# ---------------------------------------------------------------------------
# Workflow C: Notebooks para alunos (Jupyter/Colab)
# ---------------------------------------------------------------------------
log "=== Workflow C: Gerando notebooks para alunos ==="
python3 gerar_notebooks_alunos.py --batch "$BIB"
ok "Notebooks gerados em $ALUNOS_DIR/"

# ---------------------------------------------------------------------------
# Workflow D: PDF -> _book_pdf/  ← SEMPRE POR ÚLTIMO
# ---------------------------------------------------------------------------
# O PDF é gerado por último porque células de download cacheadas nos
# notebooks causariam a exibição de "<IPython.core.display.HTML object>"
# no documento. O script clean_download_cells.py limpa esses outputs
# antes do render e os restaura automaticamente em seguida.
# ---------------------------------------------------------------------------
log "=== Workflow D: Limpando células de download para PDF ==="
python3 clean_download_cells.py limpar
ok "Células de download limpas"

log "=== Workflow D: Renderizando PDF ==="
quarto render --to pdf
rm -rf "$BOOK_PDF"
mv "$BOOK_HTML" "$BOOK_PDF"
ok "PDF movido para $BOOK_PDF/"

log "=== Workflow D: Restaurando células de download ==="
python3 clean_download_cells.py restaurar
ok "Células de download restauradas"

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

cd "$EDIT_DIR"


# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Todos os workflows concluídos com sucesso!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  HTML     : $EDIT_DIR/$BOOK_HTML/"
echo "  PDF      : $EDIT_DIR/$BOOK_PDF/"
echo "  EPUB     : $EDIT_DIR/$BOOK_EPUB/"
echo "  Alunos   : $EDIT_DIR/$ALUNOS_DIR/"
echo "  Site     : https://fzampirolli.github.io/si-md2/"
echo "  GitHub   : $REPO"