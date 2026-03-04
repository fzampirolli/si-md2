# Projeto Sistemas Inteligentes - Guia do Autor (Fontes)

Este README serve como manual de instruções para os autores que editam os notebooks em `si-md2/cap*/`. Como o projeto utiliza o **[Quarto](https://quarto.org/)**, seguimos padrões específicos para que as referências (equações, figuras, tabelas e bibliografia) funcionem corretamente no PDF, no HTML e no IPYNB (versão do aluno).

Versão *online* do livro (em construção):  
https://fzampirolli.github.io/si-md2

---

## 📐 Padronização de Referências no Quarto

**Regra fundamental:** Todo label **deve** conter o número do capítulo. Isso garante referências únicas e organizadas em documentos longos.

---

### 🖋️ Prefixos Obrigatórios
Para numeração automática em PDF/HTML, use:
- `fig-` → Figuras
- `tbl-` → Tabelas  
- `eq-` → Equações

**Formato do label:** `{#prefixo-capítulo-identificador}`  
*Exemplos:* `{#fig-3-grafico}`, `{#tbl-2-resultados}`, `{#eq-1-calor}`

---

### 📊 Figuras e Tabelas (como imagem)
Sintaxe única para qualquer imagem. O label **sempre** inclui o capítulo:

```markdown
![Legenda descritiva](caminho/arquivo.png){#fig-3-nome-significativo}
```

**Exemplo prático:**
```markdown
![Gráfico de dispersão dos dados coletados](imagens/dispersao.png){#fig-3-dispersao}
```

---

### 📋 Tabelas em Markdown
Legenda e label **após** a tabela, iniciados com `:`:

```markdown
| Algoritmo | Precisão |
|-----------|----------|
| J48       | 85%      |
| RandomForest | 92%  |

: Comparação de algoritmos {#tbl-3-algoritmos}
```

---

### ➗ Equações
Bloco `$$` com label **imediatamente após**:

```markdown
$$ \hat{y} = \beta_0 + \beta_1x $$ {#eq-3-regressao}
```

---

### 🔗 Como Citar (Referências Cruzadas)

O padrão **sempre** referencia o label completo, mas a formatação final varia conforme a sintaxe:

| Objetivo | Sintaxe | Resultado Esperado |
|----------|---------|-------------------|
| **Referência completa** | `@fig-3-dispersao` | "Figura 3.1" (numeração automática) |
| **Apenas o número** | `[-@fig-3-dispersao]` | "3.1" |
| **Rótulo customizado** | `[Gráfico @fig-3-dispersao]` | "Gráfico 3.1" |
| **Múltiplas referências** | `[@fig-3-1; @fig-3-2]` | "(Figura 3.1; Figura 3.2)" |

**Observação:** O número após o capítulo (ex: "1" em `fig-3-1`) é gerado automaticamente pelo Quarto. Você só define o identificador único dentro do capítulo.

---

### 📚 Citações Bibliográficas
Baseadas no arquivo `.bib`:

| Tipo | Sintaxe | Resultado |
|------|---------|-----------|
| Indireta (parênteses) | `[@russell2004]` | (Russell, 2004) |
| Direta (no texto) | `@russell2004` | Russell (2004) |

---

### ⚠️ Regras de Ouro para Labels

| Requisito | Correto | Incorreto |
|-----------|---------|-----------|
| **Incluir capítulo** | `#fig-3-dispersao` | `#fig-dispersao` |
| **Minúsculas** | `#tbl-2-resultados` | `#tbl-2-Resultados` |
| **Sem acentos** | `#eq-3-calor` | `#eq-3-calor` ✅ *(já está correto)* |
| **Hífens como separadores** | `#fig-3-analise-final` | `#fig_3_analise_final` |
| **Espaçamento** | Uma linha em branco antes/depois | Bloco colado ao texto |

---

### 🎯 Resumo Visual

```markdown
# Inserção (sempre com capítulo)
![Legenda](img.png){#fig-3-dispersao}

# Citação (variações)
@fig-3-dispersao          → Figura 3.1
[-@fig-3-dispersao]       → 3.1
[Graf. @fig-3-dispersao]  → Graf. 3.1
```

---

### 🎨 Estilização de Texto e Cores

Para destacar termos técnicos ou estruturas lógicas mantendo a compatibilidade entre PDF, HTML e o Google Colab (via MathJax), utilize preferencialmente a sintaxe LaTeX dentro de delimitadores matemáticos:

**Destaque Inline (Ex: Regras de Associação em azul):**

```markdown
$\textcolor{blue}{\textbf{Regra de Associação}}$
```

**Estruturas Lógicas em Bloco:**

```markdown
$$
\textcolor{red}{\textbf{If }} 
(\text{Conjunto } \mathbf{X} \text{ de Itens})
\;\textcolor{red}{\textbf{ then }}\;
(\text{Conjunto } \mathbf{Y} \text{ de Itens}),
\quad \text{sendo } \mathbf{X} \cap \mathbf{Y} = \varnothing
$$
```

Ou, para numerar equações, use "[Regra @eq-2-1]" ou "@eq-2-1", com:

$$
\textcolor{red}{\textbf{If }} 
(\text{Temperatura} = \text{Baixa})
\;\textcolor{red}{\textbf{ then }}\;
(\text{Umidade} = \text{Normal})
$$ {#eq-2-1}

---

### 📥 Botões de Download de Arquivos

Células que geram botões de download (arquivos `.arff`, `.csv`, etc.) **não devem aparecer no PDF**. Para isso, siga o padrão abaixo em toda célula com botão de download:

**Cabeçalho obrigatório da célula** (sem `output: false`, sem `quarto-raw: true`):

```python
#| label: download-nome-descritivo
#| code-fold: true
#| code-summary: "Exibir Código Python"
#| echo: false
```

**Estrutura obrigatória do código:**

```python
import os
import base64
from IPython.display import display, HTML

quarto_format = os.environ.get('QUARTO_FORMAT', '')

# Processamento que deve aparecer em todos os formatos
# (ex: exibir tabela via Markdown) fica FORA do if

# Botão de download: apenas HTML e Jupyter/VS Code
if quarto_format in ('html', ''):
    conteudo = "..."   # conteúdo do arquivo
    b64 = base64.b64encode(conteudo.encode()).decode()
    display(HTML(f"""
    <div style="margin-top:20px; margin-bottom:20px;">
        <a href="data:application/octet-stream;base64,{b64}" download="arquivo.ext"
           style="background-color:#1b5e20; color:white; padding:10px 18px;
                  text-decoration:none; border-radius:8px; font-family:sans-serif;
                  font-size:14px; font-weight:bold; display:inline-block;
                  box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            📥 Baixar Arquivo arquivo.ext
        </a>
    </div>
    """))
```

**Por que funciona:**

| Contexto | `QUARTO_FORMAT` | Comportamento |
|---|---|---|
| VS Code / Jupyter interativo | `None` → `''` | Exibe botão ✅ |
| `quarto render --to html` | `'html'` | Exibe botão ✅ |
| `quarto render --to pdf` | `'latex'` | Não exibe ✅ |

> ⚠️ **Nunca use `#| output: false`** em células de botão — isso suprime o output em **todos** os formatos, inclusive HTML.

> ⚠️ **Nunca use `#| quarto-raw: true`** — essa diretiva não existe no Quarto e causa comportamento imprevisível.

---

## 🚀 Fluxos de Trabalho em `si-md2`

### Publicação Completa (todos os workflows de uma vez)

Para executar todos os workflows em sequência — HTML, notebooks para alunos, PDF e push para o GitHub — use o script principal:

```bash
chmod +x publish_all.sh   # apenas na primeira vez
./publish_all.sh
```

O script detecta automaticamente a pasta de edição e a raiz do repositório git, rodando cada ferramenta no diretório correto.

> ℹ️ **O PDF é gerado por último** de forma intencional: o script limpa os outputs de células de download antes do render PDF e os restaura em seguida, garantindo que o HTML e os notebooks dos alunos sejam gerados com os botões intactos.

---

### Workflow A: Renderizar HTML + Publicar

Gera o site e publica no GitHub Pages:

```bash
quarto render --to html          # Gera o site em _book/
quarto publish gh-pages          # Publica em https://fzampirolli.github.io/si-md2/
```

---

### Workflow B: Gerar Versão para Alunos (Jupyter/Colab)

O script processa os notebooks de autor, resolve citações bibliográficas no formato ABNT e remove metadados do Quarto, gerando notebooks prontos para distribuição.

```bash
python gerar_notebooks_alunos.py --batch references.bib
# Gera notebooks_alunos/capXX/capXX_aluno.ipynb
```

#### Como utilizar os notebooks gerados:

1. **Google Colab (Nuvem):** Fazer upload da pasta `notebooks_alunos` para o **Google Drive** e abrir os arquivos com o **Google Colaboratory**.
2. **Abrir no Colab diretamente:** Clicar no botão ![Open in Colab](images/colab-badge.png) que aparece no canto superior esquerdo de cada capítulo.
3. **Jupyter Lab (Local):** Com um ambiente Python instalado, executar:

```bash
jupyter lab notebooks_alunos/cap01/cap01_aluno.ipynb
```

---

### Workflow C: Renderizar PDF (sempre por último)


```bash
# renderiza o PDF
quarto render --to pdf
```

Ou simplesmente execute `./publish_all.sh`, que cuida de tudo na ordem correta.

---

### Workflow D: Gerar EPUB com Referências por Capítulo

O EPUB requer pré-processamento porque o Quarto não suporta referências por capítulo nesse formato. O script resolve as citações e injeta a lista de referências em cada capítulo antes de renderizar.

**Passo 1:** Pré-processa os notebooks e gera os arquivos de configuração:

```bash
python gerar_notebooks_alunos.py --epub references.bib --out-dir _epub_src
```

Isso cria `_epub_src/capXX/capXX_epub.ipynb` com as referências já resolvidas, além de `_quarto_epub.yml` e `render_epub.sh`.

**Passo 2:** Renderiza o EPUB:

```bash
./render_epub.sh   # Gera o EPUB em _book/
```

---

## 🛠️ O que o script `gerar_notebooks_alunos.py` faz

O script pós-processa os notebooks Quarto (`.ipynb`) para distribuição, resolvendo elementos que só funcionam dentro do ecossistema Quarto:

| Elemento Quarto | Resultado no notebook gerado |
|---|---|
| `@chave` | `Autor (ano)` — citação direta ABNT |
| `[@chave]` | `(AUTOR, ano)` — citação indireta ABNT |
| `\printbibliography` | Lista de referências formatada por capítulo |
| `![alt](img){#fig-X-Y}` | `<figure>` HTML com legenda numerada |
| `@fig-X-Y` | `[Figura X.Y](#fig-X-Y)` — link interno |
| `::: {.callout-tip}` | `<blockquote>` HTML com emoji e título |
| `### Título {.unnumbered}` | `### Título` — atributos removidos |
| Células YAML `---` | Removidas |

---

## 📦 Dependências

- [Quarto](https://quarto.org/) ≥ 1.4
- Python ≥ 3.9 com `nbformat` (`pip install nbformat`)
- LaTeX com pacote `biblatex-abnt` (para geração de PDF)
- Git

---

## 🛠️ Organização da Pasta de Trabalho

* `_quarto.yml`: O cérebro do projeto. Se adicionar um capítulo novo, registre-o aqui.
* `references.bib`: Onde você deve colar o BibTeX de novas referências.
* `capXX/`: Cada capítulo é uma pasta. Mantenha os dados em `capXX/data/` e imagens em `capXX/images/`.
* `limpar.sh`: Use sempre que notar erros de cache ou arquivos fantasmas.

## 📋 Checklist antes do Push

* [ ] Verificou se as imagens estão na pasta `images/` interna do capítulo?
* [ ] O identificador da figura começa com `{#fig-}`?
* [ ] O identificador da tabela começa com `{#tbl-}`?
* [ ] Células de botão de download seguem o padrão com `if quarto_format in ('html', '')`?
* [ ] Rodou o script de notebooks dos alunos?
* [ ] Deu `git pull` antes de começar?

---

## 📄 Licença

© 2026 José Artur Quilici-Gonzalez, Francisco de Assis Zampirolli e Fábio Rezende de Souza. Todos os direitos reservados.