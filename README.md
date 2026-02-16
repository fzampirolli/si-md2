# Projeto Sistemas Inteligentes - Material Didático

Repositório do material didático do curso de Sistemas Inteligentes e Mineração de Dados.

## 📁 Estrutura do Projeto

```
.
├── si-md1/                          # PDFs originais dos capítulos
│   ├── Sist_Intel_final_f.pdf       # Livro completo original
│   ├── cap01.pdf                    # Capítulo 1 - PDF fonte
│   ├── cap02.pdf                    # Capítulo 2 - PDF fonte
│   ├── cap03.pdf                    # Capítulo 3 - PDF fonte
│   ├── cap04.pdf                    # Capítulo 4 - PDF fonte
│   ├── cap05.pdf                    # Capítulo 5 - PDF fonte
│   └── cap06.pdf                    # Capítulo 6 - PDF fonte
│
├── si-md2/                          # Projeto Quarto (trabalhe aqui!)
│   ├── README.md                    # Documentação completa do workflow
│   ├── _quarto.yml                  # Configuração do livro Quarto
│   ├── references.bib               # Referências bibliográficas
│   ├── chapter_references.conf      # Refs por capítulo (centralizado)
│   ├── index.qmd                    # Página inicial do livro
│   │
│   ├── cap01/                       # Capítulo 1 
│   │   ├── cap01.ipynb
│   │   ├── images/
│   │   └── data/
│   ├── ...
│   │
│   ├── _book/                       # Livro compilado (gerado)
│   │   └── Sistemas-Inteligentes-e-Mineração-de-Dados.pdf
│   │
│   ├── notebooks_alunos/            # Notebooks finais para alunos (gerado)
│   │   ├── cap01_aluno.ipynb
│   │   ├── ...
│   │   ├── images/
│   │   └── README.md
│   │
│   └── scripts/
│       ├── pdf_to_notebook.sh        # Converter PDF → Notebook
│       ├── gerar_notebooks_alunos.sh # Gerar versão para alunos
│       └── create_book.sh            # Compilar livro PDF
│
└── .gitignore                        # Arquivos ignorados pelo Git
```

## 🚀 Quick Start

### 1. Clone o Repositório

```bash
git clone https://github.com/seu-usuario/sistemas-inteligentes.git
cd sistemas-inteligentes
```

### 2. Trabalhe na Pasta `si-md2`

```bash
cd si-md2
```

### 3. Leia a Documentação Completa

```bash
# Abrir README completo com todas as instruções
cat README.md
# ou
code README.md  # no VS Code
```

## 📚 Workflows Principais

### Workflow 1: Converter PDF em Notebook (Primeira Vez)

Se está começando um capítulo novo:

```bash
cd si-md2
./pdf_to_notebook.sh
```

Isso converte os PDFs de `../si-md1/` em notebooks iniciais.

### Workflow 2: Gerar Notebooks para Alunos

Depois de editar os capítulos:

```bash
cd si-md2
./gerar_notebooks_alunos.sh
```

Gera versões limpas em `notebooks_alunos/` com referências formatadas.

### Workflow 3: Compilar Livro em PDF

```bash
cd si-md2
quarto render --to pdf
```

Gera `_book/Sistemas-Inteligentes-e-Mineração-de-Dados.pdf`

## 🔧 Configuração Inicial

### Pré-requisitos

- Git
- VS Code (recomendado)
- Python 3.8+
- Quarto CLI
- Poppler (para conversão PDF)

Veja instruções detalhadas de instalação em `si-md2/README.md`.

### Primeira Vez no Projeto

```bash
# 1. Clonar
git clone <url-do-repo>
cd sistemas-inteligentes

# 2. Entrar na pasta de trabalho
cd si-md2

# 3. Ler documentação completa
code README.md

# 4. Abrir projeto no VS Code
code .
```

## 📖 Documentação

- **`si-md2/README.md`**: Documentação COMPLETA com:
  - Instalação detalhada (Windows, Mac, Linux)
  - Setup do VS Code
  - Git/GitHub do zero
  - Workflow completo
  - Troubleshooting

## 🔄 Git Workflow

### Antes de Trabalhar (SEMPRE!)

```bash
git pull origin main
```

### Depois de Trabalhar

```bash
# Ver mudanças
git status

# Adicionar mudanças
git add .

# Commit
git commit -m "Atualiza capítulo 01: adiciona exercícios"

# Enviar
git push origin main
```

## 🎯 Organização de Pastas

### `si-md1/`
- **Propósito**: Arquivo dos PDFs originais
- **Não editar**: Apenas leitura
- **Git**: Opcional versionar (já está no `.gitignore`)

### `si-md2/`
- **Propósito**: Projeto ativo - TODO o trabalho acontece aqui!
- **Estrutura**: Quarto Book Project
- **Git**: Versionar tudo aqui

### `si-md2/cap*.ok/`
- **Propósito**: Capítulos finalizados
- **Padrão**: `cap01.ok/`, `cap02.ok/`, etc.
- **Contém**: `.ipynb`, `images/`, `data/`

### `si-md2/notebooks_alunos/`
- **Propósito**: Output final para distribuição
- **Gerado por**: `gerar_notebooks_alunos.sh`
- **Git**: Opcional versionar

### `si-md2/_book/`
- **Propósito**: Livro compilado em PDF
- **Gerado por**: `quarto render`
- **Git**: Não versionar (já no `.gitignore`)

## ⚙️ Arquivos de Configuração

### `si-md2/_quarto.yml`
Configuração do livro Quarto - define capítulos, formato, etc.

### `si-md2/references.bib`
TODAS as referências bibliográficas em formato BibTeX.

### `si-md2/chapter_references.conf`
Define quais referências aparecem em cada capítulo.

### `.gitignore`
Define o que o Git deve ignorar (temporários, builds, etc).

## 🤝 Colaboração

### Para Co-autores

1. Clone o repositório
2. **SEMPRE** faça `git pull` antes de começar
3. Trabalhe em `si-md2/`
4. Faça commits frequentes com mensagens claras
5. Push quando terminar

### Resolução de Conflitos

Se houver conflito ao fazer push:

```bash
git pull origin main
# Resolver conflitos no VS Code
git add .
git commit -m "Resolve conflito em cap01"
git push origin main
```

## 📋 Checklist de Qualidade

Antes de fazer push:

- [ ] `git pull` executado
- [ ] Notebooks testados (células executam sem erro)
- [ ] Imagens carregando corretamente
- [ ] Referências formatadas
- [ ] Commit message clara e descritiva

## 🆘 Problemas Comuns

### "File references.bib not found"
**Solução**: Execute `gerar_notebooks_alunos.sh` que copia automaticamente.

### "Permission denied" ao executar script
**Solução**: `chmod +x nome-do-script.sh`

### Conflito de merge
**Solução**: Veja seção "Trabalhando com Git e GitHub" em `si-md2/README.md`

## 📞 Suporte

- Documentação completa: `si-md2/README.md`
- Issues: [GitHub Issues](link)
- Email: seu.email@exemplo.com

## 📄 Licença

[Especificar licença]

---

**Nota**: Para instruções detalhadas sobre instalação, configuração, uso de scripts e workflows completos, consulte **`si-md2/README.md`**.
