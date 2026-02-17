# Projeto Sistemas Inteligentes - Guia do Autor (Fontes)

Este README serve como manual de instrução para os autores que editam os notebooks em `si-md2/cap*/`. Como o projeto utiliza o **Quarto**, seguimos padrões específicos para que as referências (equações, figuras, tabelas e bibliografia) funcionem tanto no PDF quanto no HTML e IPYNB (versão do aluno).

---

## 🖋️ Padrões de Escrita nos Notebooks (.ipynb)

Para que o Quarto consiga numerar e referenciar seus elementos automaticamente tanto no PDF quanto no HTML, siga os exemplos abaixo exatamente como mostrados.

### 1. Figuras (`@fig-`)

Sempre adicione um identificador que comece com `{#fig-CAP-NUM}` ao final da legenda.

* **Como escrever:**
```markdown
![Legenda da imagem aqui](images/fig1_1.png){#fig-1-1}
```


* **Como citar no texto:**
"Como podemos observar na @fig-1-1, o fluxo de dados..."

### 2. Tabelas (`@tbl-`) - Opção 1: Tabela como Imagem

Se a tabela for uma imagem capturada, use o prefixo `{#tbl-}` para que o Quarto a trate como tabela na lista de tabelas (LOT).

* **Como escrever:**
```markdown
![Legenda da tabela aqui](images/tbl1_1.png){#tbl-1-1}
```


* **Como citar no texto:**
"Conforme os dados apresentados na @tbl-1-1..."

### 3. Tabelas (`@tbl-`) - Opção 2: Tabela em Markdown

Tabelas escritas em Markdown precisam de uma legenda iniciada por dois pontos `:` e o identificador ao final.

* **Como escrever:**
```markdown
| Algoritmo | Precisão |
|-----------|----------|
| J48       | 85%      |
| Naive     | 82%      |

: Resultados dos testes {#tbl-1-resultados}
```


* **Como citar no texto:**
"Os dados apresentados na @tbl-1-resultados indicam..."

### 4. Equações Matemáticas (`@eq-`)

Para equações numeradas, utilize blocos de cifrão duplo e adicione `{#eq-CAP-NUM}` logo após o fechamento.

* **Como escrever:**
```markdown
$$
E = mc^2
$$ {#eq-1-energia}
```


* **Como citar no texto:**
"A famosa @eq-1-energia define a relação de massa..."

---

### ⚠️ Regra de Ouro: Identificadores (ID)

Nos quatro casos (`fig`, `tbl`, `eq`), o padrão do identificador deve seguir obrigatoriamente a lógica:
**`{tipo-Capitulo-Numero/Texto}`**

* **Exemplos para o Capítulo 1:** `{#fig-1-1}`, `{#tbl-1-2}`, `{#eq-1-energia}`.
* **Exemplos para o Capítulo 2:** `{#fig-2-1}`, `{#tbl-2-2}`, `{#eq-2-1}`.

Isso garante que, ao compilar o livro completo, a numeração seja reiniciada e organizada por capítulos (ex: Figura 1.1, Figura 2.1).

### 5. Citações Bibliográficas (`@`)

As citações dependem das chaves existentes no seu arquivo `references.bib`.

* **Citação direta (entre parênteses):** "A inteligência artificial evoluiu muito [@russell2004]."
* **Citação no fluxo do texto:** "Segundo @russell2004, os agentes inteligentes..."

---

## 🚀 Fluxos de Trabalho em `si-md2`

### Workflow A: Renderizar o Livro Completo

Transforma todos os notebooks no formato final definido no `_quarto.yml`.

```bash
quarto render --to pdf   # Gera o PDF em _book/
quarto render --to html  # Gera o site em _book/
quarto render --to epub  # Gera o ePub em _book/
quarto publish gh-pages  # Publica em https://fzampirolli.github.io/si-md2/
```

### Workflow B: Gerar Versão para Alunos

O script abaixo processa os notebooks de autor, remove células indesejadas (como rascunhos ou soluções de exercícios) e formata as referências bibliográficas para os notebooks que os alunos receberão.

```bash
# Executar na raiz da pasta si-md2
python gerar_notebooks_alunos.py --batch references.bib
```

#### Como utilizar os notebooks gerados:

Para que o aluno possa praticar e executar os códigos, existem duas formas principais:

1. **Google Colab (Nuvem):** Fazer o upload ou uma cópia da pasta `notebooks_alunos` para o seu **Google Drive** e abrir os arquivos utilizando o **Google Colaboratory**.
2. **Jupyter Lab (Local):** Caso possua um ambiente Python instalado localmente, basta executar o comando abaixo para abrir um capítulo específico:

```bash
jupyter lab notebooks_alunos/cap01/cap01_aluno.ipynb
```

---

**Dica para Autores:** Sempre que você alterar uma citação no arquivo `references.bib` ou editar o conteúdo de um capítulo, lembre-se de rodar este workflow novamente para garantir que a versão do aluno esteja sincronizada com a versão do livro.

**Deseja que eu verifique se o caminho das imagens nos notebooks dos alunos está configurado corretamente para funcionar no Google Colab?**

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
* [ ] Rodou o script de notebooks dos alunos?
* [ ] Deu `git pull` antes de começar?

---

**Suporte:** Caso alguma referência não renderize, verifique se não há espaços extras entre o fechamento da chave `}` e o final da linha.