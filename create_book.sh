#!/bin/bash

# ============================================
# Script para criação e manutenção do livro
# Sistemas Inteligentes e Mineração de Dados
# ============================================

# 1. Cria o projeto (se não existir)
if [ ! -d "si-md2" ]; then
    quarto create project book si-md2
fi

REPO_DIR="si-md2"
CONF_FILE="chapter_references.conf"

# 1. Garantir que o diretório e o Git estejam atualizados
if [ ! -d "$REPO_DIR" ]; then
    echo "Diretório não encontrado. Criando projeto Quarto..."
    quarto create project book "$REPO_DIR"
fi

cd "$REPO_DIR" || exit

echo "Sincronizando com o GitHub antes de iniciar..."
git pull origin main

# 2. Carregar referências do arquivo de configuração (se existir)
if [ -f "$CONF_FILE" ]; then
    echo "Carregando referências de $CONF_FILE..."
    source "$CONF_FILE"
else
    echo "Aviso: $CONF_FILE não encontrado. Usando referências padrão do script."
    # Fallback caso o arquivo suma
    CAP01="forouzan2011 goldschmidt2005 han2008 padhy2010 pinheiro2008 rezende2005 russell2004 tan2009 witten2005"
    CAP02="han2008 tan2009 witten2005 goldschmidt2005"
    CAP03="russell2004 rezende2005 padhy2010"
    CAP04="goldschmidt2005 pinheiro2008 tan2009"
    CAP05="witten2005 han2008 forouzan2011"
    CAP06="tan2009 russell2004 rezende2005"
fi

setup_chapter () {
    FOLDER=$1    # Ex: cap01
    FILE=$2      # Ex: cap01.ipynb
    TITLE=$3     # Ex: Sistemas Inteligentes
    REFS=$4      # Ex: $CAP01
    TARGET="$FOLDER/$FILE"
    
    # 1. Criar estrutura de pastas
    mkdir -p "$FOLDER/images"
    mkdir -p "$FOLDER/data"

    # 2. Copiar o selo do Colab para a pasta de imagens do capítulo
    # Assume que a imagem original está em ./images/colab-badge.png em relação à raiz do script
    if [ -f "images/colab-badge.png" ]; then
        cp "images/colab-badge.png" "$FOLDER/images/colab-badge.png"
    else
        echo "Aviso: images/colab-badge.png não encontrado para copiar para $FOLDER"
    fi

    # Formata referências: transforma "ref1 ref2" em "@ref1, @ref2"
    FORMATTED_REFS=$(echo "$REFS" | sed -E 's/([^ ]+)/@\1/g' | sed 's/ /, /g')
    
    # Criando o JSON do Notebook de forma válida
    cat <<EOF > "$TARGET"
{
 "cells": [
{
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "[![](images/colab-badge.png)](https://colab.research.google.com/github/fzampirolli/si-md2/blob/main/si-md2/notebooks_alunos/${FOLDER}/${FOLDER}_aluno.ipynb)"
   ]
  },
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
    "## Referências do Capítulo\n\n",
    "\n",
    "Tem que citar neste capítulo: $FORMATTED_REFS\n",
    "\n\n",
    "\\\\printbibliography[heading=none]"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF
}

# 3. Chamadas da função
setup_chapter "cap01" "cap01.ipynb" "Sistemas Inteligentes" "$CAP01"
setup_chapter "cap02" "cap02.ipynb" "Mineração de Dados e Regras de Associação" "$CAP02"
setup_chapter "cap03" "cap03.ipynb" "Classificação e Árvores de Decisão" "$CAP03"
setup_chapter "cap04" "cap04.ipynb" "Classificação e Regras de Classificação" "$CAP04"
setup_chapter "cap05" "cap05.ipynb" "Máquina de Vetores de Suporte (SVM)" "$CAP05"
setup_chapter "cap06" "cap06.ipynb" "Aplicações de SVM e Imagens" "$CAP06"

# 4. Configuração Quarto
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

lang: pt-BR

bibliography: references.bib
csl: abnt.csl         

format:
  html:
    theme: cosmo
    cite-method: citeproc
    code-tools: true
    toc: true
  pdf:
    cite-method: biblatex
    biblatexoptions: 
      - style=abnt          # ← pacote biblatex-abnt (requer instalação)
      - refsection=chapter  # Refs separadas por capítulo
      - defernumbers=true   # Numera refs por capítulo
    documentclass: report
    number-sections: true
    toc: true
    lof: true
    lot: true
    geometry:
      - top=15mm
      - bottom=20mm
      - left=20mm
      - right=20mm
    include-in-header:
      text: |
          \usepackage{etoolbox}
          \usepackage{titlesec}
          \usepackage{xcolor}
          \usepackage{wallpaper}

          \definecolor{darkblue}{RGB}{0, 51, 102}

          % Estilo dos Capítulos
          \titleformat{\chapter}[display]
            {\normalfont\huge\bfseries\color{darkblue}}
            {\filleft\Large\chaptertitlename\ \thechapter}
            {1ex}
            {\titlerule\vspace{2ex}\Huge\filleft}
            [\vspace{2ex}]
          \titlespacing*{\chapter}{0pt}{5pt}{20pt}

          % REMOVER o capítulo "Bibliography" do final
          \defbibheading{bibliography}{}

          \renewcommand{\maketitle}{%
            \begin{titlepage}
              \ThisCenterWallPaper{1.02}{images/capa.png}
              \vspace*{1cm}
              \begin{flushright}
                {\Huge\bfseries\color{white} Sistemas Inteligentes e Mineração de Dados}\\\\[0.5cm]
                {\Large\bfseries\color{white} 2ª Edição: Do Weka ao Python}\\\\[2cm]
                \vfill
                {\large\bfseries\color{white} José Artur Quilici-Gonzalez}\\\\
                {\large\bfseries\color{white} Francisco de Assis Zampirolli}\\\\
                {\large\bfseries\color{white} Fábio Rezende de Souza}\\\\[1cm]
                {\large\color{white} \today}
              \end{flushright}
            \end{titlepage}
            \clearpage
          }
EOT

# Criar arquivos base se não existirem
[ ! -f references.bib ] && touch references.bib

# Criar index.qmd se não existir
if [ ! -f index.qmd ]; then
    echo "📖 Criando index.qmd com prefácio..."
    
    cat > index.qmd << 'EOF'
# Prefácio {.unnumbered}

Bem-vindo à segunda edição do livro **Sistemas Inteligentes e Mineração de Dados: Do Weka ao Python**.

Esta obra representa a evolução natural de nossa experiência no ensino de inteligência artificial e mineração de dados, refletindo as mudanças significativas que ocorreram no campo nos últimos anos.

## Motivação {.unnumbered}

A primeira edição deste livro focava principalmente no uso da ferramenta Weka, uma plataforma consolidada e amplamente utilizada no ensino de mineração de dados. Com o crescimento exponencial do ecossistema Python e suas bibliotecas especializadas (scikit-learn, pandas, NumPy, entre outras), tornou-se essencial atualizar o material didático para refletir as práticas atuais da indústria e da academia.

## Estrutura do Livro {.unnumbered}

O livro está organizado em seis capítulos que cobrem desde conceitos fundamentais até técnicas avançadas:

- **Capítulo 1**: Introdução aos Sistemas Inteligentes
- **Capítulo 2**: Fundamentos de Mineração de Dados
- **Capítulo 3**: Aprendizado de Máquina Supervisionado
- **Capítulo 4**: Aprendizado Não Supervisionado
- **Capítulo 5**: Avaliação e Validação de Modelos
- **Capítulo 6**: Aplicações Práticas e Estudos de Caso

Cada capítulo inclui exemplos práticos implementados em Python, com notebooks Jupyter que podem ser executados diretamente pelo leitor.

## Público-Alvo {.unnumbered}

Este livro destina-se a:

- Estudantes de graduação em Ciência da Computação, Engenharia e áreas correlatas
- Profissionais que desejam atualizar seus conhecimentos em ciência de dados
- Pesquisadores interessados em técnicas de inteligência artificial
- Entusiastas de aprendizado de máquina e análise de dados

## Como Usar Este Livro {.unnumbered}

O material está disponível em dois formatos:

1. **PDF**: Para leitura completa e impressão
2. **Notebooks Jupyter**: Para execução interativa dos exemplos

Recomendamos que os leitores acompanhem a leitura executando os notebooks disponibilizados, experimentando modificações nos códigos e explorando os datasets fornecidos.

## Agradecimentos {.unnumbered}

Agradecemos a todos os alunos que, ao longo dos anos, contribuíram com feedback valioso que ajudou a moldar este material. Agradecemos também às nossas instituições de ensino pelo apoio contínuo à pesquisa e ao desenvolvimento deste conteúdo.

---

*Os Autores*  
*Fevereiro de 2026*
EOF
    
    echo "✅ index.qmd criado com sucesso"
else
    echo "ℹ️  index.qmd já existe, pulando..."
fi

# ============================================
# CONFIGURAÇÃO INICIAL DO AMBIENTE
# ============================================

echo ""
echo "🔧 Configurando ambiente de desenvolvimento..."

# Criar .gitignore se não existir
if [ ! -f .gitignore ]; then
    cat > .gitignore << 'EOF'
# Quarto
/.quarto/
/_site/
/.jupyter_cache/
*.html
*.pdf

# Jupyter
.ipynb_checkpoints/
*/.ipynb_checkpoints/

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
.venv/
venv/
ENV/

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF
    echo "✅ .gitignore criado"
fi

# Verificar se nbdime está instalado
if ! command -v nbdiff &> /dev/null; then
    echo ""
    echo "⚠️  nbdime não encontrado. Instalando para melhor visualização de diffs..."
    pip install nbdime --quiet
    nbdime config-git --enable --global
    echo "✅ nbdime instalado e configurado"
else
    echo "✅ nbdime já instalado"
fi

# ============================================
# FLUXO DE TRABALHO COM GIT
# ============================================

echo ""
echo "📚 Comandos para fluxo de trabalho:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 ANTES DE EDITAR (SEMPRE!)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "cd si-md2"
echo "git pull origin main"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 VISUALIZAR DIFERENÇAS EM NOTEBOOKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "# Opção 1: Interface Web (RECOMENDADO)"
echo "nbdiff-web cap01/cap01.ipynb"
echo ""
echo "# Opção 2: Diff no terminal"
echo "nbdiff cap01/cap01.ipynb"
echo ""
echo "# Opção 3: Comparar com versão específica"
echo "nbdiff HEAD:cap01/cap01.ipynb cap01/cap01.ipynb"
echo ""
echo "# Opção 4: Ver todos os notebooks modificados"
echo "git status"
echo "for file in \$(git diff --name-only '*.ipynb'); do"
echo "    echo \"Diff para: \$file\""
echo "    nbdiff HEAD:\$file \$file"
echo "done"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 DESENVOLVIMENTO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "# Editar notebooks em cap*/*.ipynb"
echo "# Usar Jupyter Lab, VS Code ou sua IDE preferida"
echo ""
echo "# Preview local (atualiza automaticamente)"
echo "quarto preview"
echo ""
echo "# Testar renderização"
echo "quarto render --to html"
echo "quarto render --to pdf"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 SALVAR ALTERAÇÕES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "# Verificar o que mudou"
echo "git status"
echo ""
echo "# Ver diferenças (notebooks com nbdiff, outros com git diff)"
echo "git diff                           # arquivos de texto"
echo "nbdiff-web cap01/cap01.ipynb      # notebooks"
echo ""
echo "# Adicionar arquivos"
echo "git add ."
echo "# ou adicionar específicos:"
echo "git add cap01/cap01.ipynb cap02/cap02.ipynb"
echo ""
echo "# Commit com mensagem descritiva"
echo "git commit -m 'feat: adiciona seção sobre SVM no cap05'"
echo ""
echo "# Convenções de commit:"
echo "#   feat: nova funcionalidade"
echo "#   fix: correção de bug"
echo "#   docs: apenas documentação"
echo "#   style: formatação, sem mudança de código"
echo "#   refactor: refatoração"
echo "#   test: adição de testes"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 PUBLICAR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "# Push para o repositório"
echo "git push origin main"
echo ""
echo "# Publicar no GitHub Pages (direto)"
echo "quarto publish gh-pages"
echo ""
echo "# Ou revisar antes de publicar"
echo "quarto publish gh-pages --no-push"
echo "git push origin gh-pages"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛠️  FERRAMENTAS ÚTEIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "# Limpar outputs antes de commitar (opcional)"
echo "jupyter nbconvert --clear-output --inplace cap*/*.ipynb"
echo ""
echo "# Ver histórico de um notebook"
echo "git log --oneline cap01/cap01.ipynb"
echo ""
echo "# Comparar com versão anterior"
echo "nbdiff HEAD~1:cap01/cap01.ipynb cap01/cap01.ipynb"
echo ""
echo "# Desfazer mudanças não commitadas"
echo "git checkout -- cap01/cap01.ipynb"
echo ""
echo "# Ver diferenças entre branches"
echo "git diff main..feature-branch cap01/cap01.ipynb | nbdiff"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Configuração concluída!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Próximos passos:"
echo "   1. cd si-md2"
echo "   2. quarto render --to pdf --execute-daemon-restart --no-cache"
echo "   3. quarto render --to html --execute-daemon-restart --no-cache"
echo "   4. quarto render cap01/cap01.ipynb --to pdf --execute-daemon-restart --no-cache"
echo "   5. open _book/Sistemas_Inteligentes_e_Mineracao_de_Dados.pdf"
echo "   6. git pull origin main"
echo "   7. Editar notebooks em cap*/"
echo "   8. nbdiff-web cap01/cap01.ipynb (ver mudanças)"
echo "   9. quarto preview (testar)"
echo "  10. git add . && git commit -m 'sua mensagem'"
echo "  11. git push origin main"
echo ""
