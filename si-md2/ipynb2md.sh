#!/bin/bash

# Verifica se o arquivo foi passado como argumento
if [ -z "$1" ]; then
    echo "Uso: ./ipynb2md.sh arquivo.ipynb"
    exit 1
fi

FILE_IN="$1"
# Define o nome de saída trocando .ipynb por .md
FILE_MD="${FILE_IN%.ipynb}.md"
FILE_TMP="${FILE_IN%.ipynb}_tmp.md"

echo "Convertendo $FILE_IN para Markdown..."

# 1. Converte IPYNB para MD usando nbconvert
# --no-input remove as células de código se você quiser apenas o texto
jupyter nbconvert --to markdown "$FILE_IN" --output "$FILE_TMP"

echo "Removendo quebras de linha indesejadas..."

# 2. Processamento para remover quebras de linha simples
# Esta lógica mantém quebras de linha duplas (\n\n) mas une linhas simples
# Também remove o hífen de fim de linha (separação silábica)
python3 -c "
import re, sys
with open('$FILE_TMP', 'r', encoding='utf-8') as f:
    # Divide o texto por parágrafos (linhas em branco)
    paragraphs = f.read().split('\n\n')

cleaned_paragraphs = []
for p in paragraphs:
    # Remove hifens de quebra de linha (ex: inteli- \n gentes)
    p = re.sub(r'(\w+)-\s*\n\s*(\w+)', r'\1\2', p)
    # Substitui quebras de linha simples por espaço
    p = p.replace('\n', ' ')
    # Remove espaços duplos
    p = re.sub(r' +', ' ', p)
    cleaned_paragraphs.append(p.strip())

with open('$FILE_MD', 'w', encoding='utf-8') as f:
    f.write('\n\n'.join(cleaned_paragraphs))
"

# 3. Limpeza
rm "$FILE_TMP"

