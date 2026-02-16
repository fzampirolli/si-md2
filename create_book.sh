#!/bin/bash

# 1. Usa o comando nativo do Quarto para criar a base do projeto
# Isso garante que arquivos ocultos de configuração sejam criados corretamente
quarto create project book si-md2

cd si-md2

echo "Adaptando estrutura para o formato Notebooks + Capítulos..."

# 2. Remove os arquivos de exemplo padrão (.qmd) que o Quarto cria
# Não precisamos de intro.qmd ou summary.qmd, pois usaremos Notebooks
rm intro.qmd summary.qmd

# 3. Cria a estrutura de pastas por capítulo (Decisão estratégica para organizar imagens)
# Baseado no sumário original do livro (Fontes [1], [2], [3], [4])

# Função auxiliar para criar capítulo com Notebook
setup_chapter () {
    FOLDER=$1
    FILE=$2
    TITLE=$3
    
    mkdir -p "$FOLDER/images"
    mkdir -p "$FOLDER/data"
    
    # Cria o JSON mínimo de um Jupyter Notebook válido
    cat <<EOF > "$FOLDER/$FILE"
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# $TITLE"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "Cole aqui o texto do PDF referente a este capítulo..."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Espaço para importar pandas, sklearn ou carregar imagens"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "name": "python",
   "version": "3.8"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF
}

# Criando os capítulos específicos conforme o PDF original
setup_chapter "cap01" "cap01.ipynb" "Capítulo 1 - Sistemas Inteligentes"
setup_chapter "cap02" "cap02.ipynb" "Capítulo 2 - Mineração de Dados e Regras de Associação"
setup_chapter "cap03" "cap03.ipynb" "Capítulo 3 - Classificação e Árvores de Decisão"
setup_chapter "cap04" "cap04.ipynb" "Capítulo 4 - Classificação e Regras de Classificação"
setup_chapter "cap05" "cap05.ipynb" "Capítulo 5 - Máquina de Vetores de Suporte (SVM)"
# O Capítulo 6 é crucial para a modernização (Imagens/Deep Learning)
setup_chapter "cap06" "cap06.ipynb" "Capítulo 6 - Aplicações de SVM e Imagens"

# 4. Sobrescreve o _quarto.yml com os metadados corretos do livro
# Inclui os autores originais conforme Fonte [5]
cat <<EOT > _quarto.yml
project:
  type: book

book:
  title: "Sistemas Inteligentes e Mineração de Dados"
  subtitle: "2ª Edição: Do Weka ao Python"
  author: "José Artur Quilici-Gonzalez, Francisco de Assis Zampirolli e Fábio Rezende de Souza"
  date: "today"
  chapters:
    - index.qmd
    - cap01/cap01.ipynb
    - cap02/cap02.ipynb
    - cap03/cap03.ipynb
    - cap04/cap04.ipynb
    - cap05/cap05.ipynb
    - cap06/cap06.ipynb
    - references.qmd

bibliography: references.bib

format:
  html:
    theme: cosmo
    code-tools: true
  pdf:
    documentclass: scrreprt
    number-sections: true
EOT

# 5. Preenche o index.qmd (Prefácio) com texto base
echo "# Prefácio {.unnumbered}

Esta é a nova edição atualizada do livro clássico de 2013.
O objetivo é manter a didática visual do Weka e introduzir a prática moderna com Python." > index.qmd

echo "Concluído! Projeto 'si-md2' configurado com sucesso."