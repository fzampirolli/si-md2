#!/usr/bin/env bash
# publish_all.sh
# Executa todos os workflows do livro si-md2:
#   A. Renderiza PDF e HTML, publica no GitHub Pages
#   B. Gera EPUB com referências por capítulo
#   C. Gera notebooks para alunos (Jupyter/Colab)
#   D. Commit e push para o GitHub
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
# Workflow A: PDF + HTML + GitHub Pages
# ---------------------------------------------------------------------------
log "=== Workflow A: Renderizando PDF ==="
quarto render --to pdf
ok "PDF gerado em _book/"

log "=== Workflow A: Renderizando HTML ==="
quarto render --to html --no-clean
ok "HTML gerado em _book/"

log "=== Workflow A: Publicando no GitHub Pages ==="
quarto publish gh-pages --no-prompt --no-browser
ok "Publicado em https://fzampirolli.github.io/si-md2/"

# ---------------------------------------------------------------------------
# Workflow B: EPUB com referências por capítulo
# ---------------------------------------------------------------------------
log "=== Workflow B: Pré-processando notebooks para EPUB ==="
python3 gerar_notebooks_alunos.py --epub "$BIB" --out-dir "$EPUB_DIR"
ok "Notebooks EPUB gerados em $EPUB_DIR/"

log "=== Workflow B: Renderizando EPUB ==="
./render_epub.sh
ok "EPUB gerado em _book/"

# ---------------------------------------------------------------------------
# Workflow C: Notebooks para alunos (Jupyter/Colab)
# ---------------------------------------------------------------------------
log "=== Workflow C: Gerando notebooks para alunos ==="
python3 gerar_notebooks_alunos.py --batch "$BIB"
ok "Notebooks gerados em $ALUNOS_DIR/"

# ---------------------------------------------------------------------------
# Workflow D: Commit e push para o GitHub (na raiz do repositório)
# ---------------------------------------------------------------------------
log "=== Workflow D: Enviando para o GitHub ==="
cd "$GIT_DIR"

# Garante que o remote está configurado
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
echo "  PDF/HTML : $EDIT_DIR/_book/"
echo "  EPUB     : $EDIT_DIR/_book/*.epub"
echo "  Alunos   : $EDIT_DIR/$ALUNOS_DIR/"
echo "  Site     : https://fzampirolli.github.io/si-md2/"
