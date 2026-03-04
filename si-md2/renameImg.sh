#!/bin/bash

# ==========================================
# DEFINA O NÚMERO DO CAPÍTULO AQUI
CAP="03"
# ==========================================

FOLDER="cap${CAP}"
IMG_DIR="${FOLDER}/images"
NOTEBOOK="${FOLDER}/${FOLDER}.ipynb"

# Remove o zero à esquerda (ex: 03 -> 3)
CAP_NUM=$(echo $CAP | sed 's/^0//')

# Padrão de saída oficial: fig-3-
PREFIX_NOVO="fig-${CAP_NUM}-"

echo "Iniciando padronização do Capítulo ${CAP}..."

# 1. Renomear arquivos físicos
if [ -d "$IMG_DIR" ]; then
    cd "$IMG_DIR"
    
    # Procuramos por arquivos que comecem com figX_ OU figX-
    # mas que ainda não estejam no formato novo fig-X-
    for file in fig${CAP_NUM}_* fig${CAP_NUM}-*; do
        
        # Pula se o arquivo não existir (evita erro de wildcard)
        [ -e "$file" ] || continue
        
        # Se o arquivo já estiver no formato novo (ex: fig-3-1.png), pula
        [[ "$file" == fig-${CAP_NUM}-* ]] && continue

        # Gera o novo nome trocando o separador antigo pelo padrão fig-X-
        # Isso cobre fig3_10.png e fig3-10.png -> fig-3-10.png
        novo_nome=$(echo "$file" | sed -E "s/^fig${CAP_NUM}[_-]/$PREFIX_NOVO/")
        
        if [ "$file" != "$novo_nome" ]; then
            echo "Renomeando: $file -> $novo_nome"
            mv "$file" "$novo_nome"
        fi
    done
    cd - > /dev/null
else
    echo "Erro: Pasta $IMG_DIR não encontrada."
fi

# 2. Atualizar o notebook (.ipynb)
if [ -f "$NOTEBOOK" ]; then
    echo "Atualizando referências em: $NOTEBOOK"
    
    # Troca fig3_ por fig-3-
    sed -i "s/fig${CAP_NUM}_/${PREFIX_NOVO}/g" "$NOTEBOOK"
    
    # Troca fig3- por fig-3- (mas evita duplicar se já estiver correto)
    # Procuramos especificamente por figX- que não seja precedido por um hífen
    sed -i -E "s/fig${CAP_NUM}-/${PREFIX_NOVO}/g" "$NOTEBOOK"
    
    # Limpeza de possíveis duplicatas como fig--3-
    sed -i "s/fig--/fig-/g" "$NOTEBOOK"

    echo "Notebook atualizado."
fi

echo "Concluído para o Capítulo ${CAP}!"