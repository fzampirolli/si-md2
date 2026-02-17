#!/usr/bin/env bash
# render_epub.sh - Gerado por gerar_notebooks_alunos.py --epub
# Substitui temporariamente _quarto.yml pelo config EPUB, renderiza e restaura.
set -e
ORIGINAL="_quarto.yml"
EPUB_CFG="_quarto_epub.yml"
BACKUP="_quarto_backup.yml"
if [ ! -f "$EPUB_CFG" ]; then
  echo "Erro: $EPUB_CFG nao encontrado. Rode primeiro:"
  echo "  python gerar_notebooks_alunos.py --epub references.bib"
  exit 1
fi
echo "Salvando $ORIGINAL -> $BACKUP"
cp "$ORIGINAL" "$BACKUP"
echo "Ativando config EPUB..."
cp "$EPUB_CFG" "$ORIGINAL"
echo "Renderizando EPUB..."
quarto render --to epub
STATUS=$?
echo "Restaurando $BACKUP -> $ORIGINAL"
cp "$BACKUP" "$ORIGINAL"
rm "$BACKUP"
if [ $STATUS -eq 0 ]; then
  echo ""; echo "EPUB gerado com sucesso em _book/"
else
  echo ""; echo "Erro (codigo $STATUS). _quarto.yml restaurado."
  exit $STATUS
fi
