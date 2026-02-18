# Projeto Sistemas Inteligentes - Material Didático

Repositório do material didático do curso de Sistemas Inteligentes e Mineração de Dados (2ª Edição). Este projeto utiliza **Quarto** para integrar notebooks Jupyter, textos e bibliografia acadêmica.

## 📁 Estrutura do Projeto

```text
.
├── si-md1/                          # ARQUIVOS ORIGINAIS (Legado)
│   ├── Sist_Intel_final_f.pdf       # Livro completo original
│   ├── Sist_Intel_final_f.docx      # Versão editável original
│   ├── Sist_Intel_final_f.md        # Conversão para Markdown
│   ├── cap01.pdf ... cap06.pdf      # PDFs das fontes originais
│   └── media/                       # Imagens extraídas do material original
│
├── si-md2/                          # PROJETO ATIVO (Trabalhe aqui!)
│   ├── _quarto.yml                  # Configuração mestre do livro
│   ├── references.bib               # Base de dados BibTeX global
│   ├── abnt.csl                     # Estilo de citação ABNT
│   ├── index.qmd                    # Página inicial/Apresentação
│   │
│   ├── cap01/                       # Pasta do Capítulo 1
│   │   ├── cap01.ipynb              # Notebook fonte
│   │   ├── images/                  # Imagens específicas do capítulo
│   │   └── data/                    # Datasets do capítulo
│   ├── ...                          # Demais capítulos (cap02, cap03...)
│   │
│   ├── _book_*                       # LIVRO COMPILADO (Gerado) 
│   │
│   ├── notebooks_alunos/            # NOTEBOOKS PARA DISTRIBUIÇÃO (Gerado)
│   │   ├── capX/capX_aluno.ipynb    # Versão limpa com refs processadas
│   │   └── README.md
│   │
│   ├── gerar_notebooks_alunos.py    # Script de processamento de refs
│   ├── publish_all.sh               # Script de publicação completa
│   └── limpar.sh                    # Script para limpar builds e cache
│
├── create_book.sh                   # Script de criação da estrutura
└── .gitignore                       # Arquivos ignorados pelo Git
```

## 🚀 Quick Start

### Preparação do Ambiente

```bash
git clone https://github.com/fzampirolli/si-md2.git
cd si-md2
```

## 🔧 Requisitos e Pré-requisitos

* **Quarto CLI**
* **Python 3.8+**
* **VS Code** (com extensões *Quarto* e *Jupyter*)
* **TinyTeX** (para exportação em PDF via Quarto)

## 🔄 Git Workflow (Para Co-autores)

**Importante:** Nunca trabalhe diretamente na pasta `si-md1`. Todo o desenvolvimento ocorre em `si-md2`.

1. **Início:** `git pull origin main`
2. **Desenvolvimento:** Edite os arquivos `.ipynb` ou `.qmd`.
3. **Limpeza:** Antes de enviar, você pode rodar `./limpar.sh` para não enviar lixo de cache.
4. **Envio:** 

```bash
git add .
git commit -m "Descrição clara da alteração"
git push origin main
```




## ⚙️ Arquivos de Configuração Chave

* **`_quarto.yml`**: Define a ordem dos capítulos, metadados da capa e temas.
* **`references.bib`**: Arquivo central de bibliografia. Adicione novos livros aqui.
* **`chapter_references.conf`**: Configuração de referências específicas por capítulo.

## 📋 Checklist de Qualidade

* [ ] O notebook executa todas as células sem erro?
* [ ] As imagens estão salvas dentro da pasta `images/` de cada capítulo?
* [ ] As citações `@id` correspondem a entradas no `references.bib`?
* [ ] O script `gerar_notebooks_alunos.py` foi executado após a última edição?

## 🆘 Suporte

* **Documentação:** Consulte o `README.md` dentro de `si-md2`.
* **Limpeza de Build:** Se o PDF falhar, execute `./limpar.sh` e tente novamente.
* **Contato:** fzampirolli@ufabc.edu.br

---

**Nota:** Este material é de uso acadêmico. Todos os direitos reservados.
