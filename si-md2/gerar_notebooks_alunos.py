#!/usr/bin/env python3
"""
quarto_ipynb_refs.py
--------------------
Pos-processa notebooks Quarto (.ipynb) para distribuicao no Colab/Jupyter.
Resolve citacoes bibliograficas @key, referencias cruzadas de figuras @fig-*,
tabelas @tbl-* e equacoes @eq-*, injeta lista de referencias e copia imagens.
Zero dependencias externas.

--- MODO UNICO ---
    python quarto_ipynb_refs.py <notebook.ipynb> <references.bib> [-o saida.ipynb]

--- MODO BATCH ---
    python quarto_ipynb_refs.py --batch <references.bib> [--out-dir notebooks_alunos]

Sintaxe Quarto suportada:
    Citacao direta:          @russell2004              -> Russell e Norvig (2004)
    Citacao indireta:        [@russell2004]            -> (RUSSELL; NORVIG, 2004)
    Multiplas indiretas:     [@han2008; @tan2009]      -> (HAN; KAMBER, 2008; TAN et al., 2009)
    Ref de figura:           @fig-1-1                  -> [Figura 1.1](#fig-1-1)
    Def de figura:           ![alt](img){#fig-X-Y}     -> <figure> com legenda
    Ref de tabela:           @tbl-2-1                  -> [Tabela 2.1](#tbl-2-1)
    Def tabela-imagem:       ![alt](img){#tbl-X-Y}     -> <figure> com legenda "Tabela"
    Def tabela Markdown:     | col |...{#tbl-X-Y}      -> <div> com legenda "Tabela"
    Ref de equacao:          @eq-1-1                   -> [Equacao 1.1](#eq-1-1)
    Def de equacao:          $$ ... $$ {#eq-X-Y}       -> HTML com numero (X.Y)
    Callout/div Quarto:      ::: {.callout-tip} ... ::: -> blockquote HTML
    Div generico:            ::: {.qualquer} ... :::    -> conteudo sem marcas
"""

import json
import re
import shutil
import argparse
import glob
from pathlib import Path


# ---------------------------------------------------------------------------
# 1. Parser BibTeX
# ---------------------------------------------------------------------------

def parse_bib(bib_path: str) -> dict:
    text = Path(bib_path).read_text(encoding="utf-8")
    entries = {}
    entry_re = re.compile(r'@\w+\s*\{\s*([^,]+),\s*(.*?)\n\}', re.DOTALL)
    field_re = re.compile(r'(\w+)\s*=\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}', re.DOTALL)
    for m in entry_re.finditer(text):
        key  = m.group(1).strip()
        body = m.group(2)
        fields = {f.group(1).lower(): f.group(2).strip()
                  for f in field_re.finditer(body)}
        entries[key] = fields
    return entries


# ---------------------------------------------------------------------------
# 2. Formatador ABNT
# ---------------------------------------------------------------------------

def format_authors(raw: str) -> str:
    authors = [a.strip() for a in raw.split(" and ")]
    out = []
    for author in authors:
        parts = author.split(",")
        if len(parts) == 2:
            out.append(f"{parts[0].strip().upper()}, {parts[1].strip()}")
        else:
            tokens = author.split()
            if tokens:
                iniciais = ". ".join(t[0] for t in tokens[:-1]) + "."
                out.append(f"{tokens[-1].upper()}, {iniciais}")
            else:
                out.append(author)
    return "; ".join(out)


def format_entry(key: str, fields: dict) -> str:
    parts = []
    if "author" in fields:
        parts.append(format_authors(fields["author"]))
    parts.append(f"**{fields.get('title', 'Sem titulo')}**")
    pub = [fields[k] for k in ("address", "publisher", "year") if k in fields]
    if pub:
        parts.append(", ".join(pub))
    return ". ".join(parts) + "."




# ---------------------------------------------------------------------------
# 2b. Formatadores de citacao ABNT no texto
# ---------------------------------------------------------------------------

def _last_names(raw_author: str) -> list:
    """
    Extrai lista de sobrenomes de um campo 'author' do BibTeX.
    Suporta 'Sobrenome, Nome' e 'Nome Sobrenome'.
    """
    surnames = []
    for author in raw_author.split(" and "):
        author = author.strip()
        if "," in author:
            # "Forouzan, B." -> "Forouzan"
            surnames.append(author.split(",")[0].strip())
        else:
            # "Behrouz Forouzan" -> "Forouzan"
            parts = author.split()
            if parts:
                surnames.append(parts[-1].strip())
    return surnames


def cite_direct(fields: dict) -> str:
    """
    Citacao DIRETA: autor no texto, ano entre parenteses.
    ABNT NBR 10520:
      1 autor:  Forouzan (2011)
      2 autores: Forouzan e Mosharraf (2011)
      3+ autores: Tan et al. (2009)
    """
    year = fields.get("year", "s.d.")
    surnames = _last_names(fields.get("author", ""))

    if not surnames:
        return f"({year})"

    if len(surnames) == 1:
        name_part = surnames[0]
    elif len(surnames) == 2:
        name_part = f"{surnames[0]} e {surnames[1]}"
    else:
        name_part = f"{surnames[0]} et al."

    return f"{name_part} ({year})"


def cite_indirect(fields: dict) -> str:
    """
    Citacao INDIRETA: autor e ano entre parenteses, sobrenome em caixa alta.
    ABNT NBR 10520:
      1 autor:  (FOROUZAN, 2011)
      2 autores: (FOROUZAN; MOSHARRAF, 2011)
      3+ autores: (TAN et al., 2009)
    """
    year = fields.get("year", "s.d.")
    surnames = _last_names(fields.get("author", ""))

    if not surnames:
        return f"({year})"

    upper = [s.upper() for s in surnames]

    if len(upper) == 1:
        name_part = upper[0]
    elif len(upper) == 2:
        name_part = f"{upper[0]}; {upper[1]}"
    else:
        name_part = f"{upper[0]} et al."

    return f"({name_part}, {year})"

# ---------------------------------------------------------------------------
# 3. Utilitarios de source Jupyter
# ---------------------------------------------------------------------------

def source_to_str(source) -> str:
    if isinstance(source, list):
        return "".join(source)
    return source or ""


def str_to_source(text: str) -> list:
    if not text:
        return []
    return text.splitlines(keepends=True)


# ---------------------------------------------------------------------------
# 4. Prefixos de cross-references Quarto (nao sao citacoes bibliograficas)
# ---------------------------------------------------------------------------

CROSSREF_RE = re.compile(
    r'^(fig|tbl|sec|eq|lst|thm|lem|cor|prp|def|exm|exr|rem)-'
)


# ---------------------------------------------------------------------------
# 5. Padroes de definicao Quarto
# ---------------------------------------------------------------------------

# ![alt](path){#fig-X-Y ...}  ou  ![alt](path){#tbl-X-Y ...}
IMG_DEF_RE = re.compile(
    r'!\[([^\]]*)\]\(([^)\s"\']+)[^)]*\)\{#((fig|tbl)-[\w-]+)[^}]*\}'
)

# Tabela Markdown: aceita AMBAS as sintaxes:
#   Sintaxe antiga:  | col |...\n{#tbl-X-Y}
#   Sintaxe Quarto:  | col |...\n\n: Legenda {#tbl-X-Y}
# Grupos: (1) bloco tabela  (2) legenda Quarto  (3) id Quarto  (4) id antiga
# TBL_MD_RE = re.compile(
#     r'((?:[ \t]*\|[^\n]+\n)+)'           # bloco de linhas | col |
#     r'(?:'
#         r'\n?[ \t]*: ([^\n{]*?)\s*\{#(tbl-[\w-]+)[^}]*\}'  # Quarto: : Legenda {#tbl-X}
#         r'|'
#         r'[ \t]*\{#(tbl-[\w-]+)[^}]*\}'  # antiga: {#tbl-X} direto
#     r')',
#     re.MULTILINE
# )
# Tabela Markdown: busca o ID {#tbl- explicitamente para não confundir com LaTeX \frac{}{}
TBL_MD_RE = re.compile(
    r'((?:[ \t]*\|[^\n]+\n)+)'           # bloco de linhas | col |
    r'(?:'
        r'\n?[ \t]*: (.*?)\s*\{#(tbl-[\w-]+)[^}]*\}'  # Quarto: : Legenda {#tbl-X}
        r'|'
        r'[ \t]*\{#(tbl-[\w-]+)[^}]*\}'  # antiga: {#tbl-X} direto
    r')',
    re.MULTILINE | re.DOTALL
)

# Equacao: $$ ... $$ (possivelmente multiline) seguida de {#eq-X-Y}
# Usa [\s\S]*? em vez de .*? com re.DOTALL para nao ser guloso
# entre multiplos blocos $$ na mesma celula
EQ_DEF_RE = re.compile(
    r'(\$\$[\s\S]*?\$\$)'       # bloco $$ ... $$ (multiline, nao guloso)
    r'[ \t]*\n?[ \t]*'
    r'\{#(eq-[\w-]+)[^}]*\}',    # {#eq-X-Y}
)

# ---------------------------------------------------------------------------
# Callouts e divs Quarto:  ::: {.callout-*}  ...  :::
# Suporta callout-note, callout-tip, callout-warning, callout-important,
# callout-caution, e divs genericos ::: {.qualquer-classe}
# ---------------------------------------------------------------------------

# Mapeamento de tipo de callout -> emoji + titulo padrao
CALLOUT_STYLE = {
    "callout-note":      ("📝", "Nota"),
    "callout-tip":       ("💡", "Dica"),
    "callout-warning":   ("⚠️", "Atenção"),
    "callout-important": ("❗", "Importante"),
    "callout-caution":   ("🔔", "Cuidado"),
}

# Regex para abertura de bloco div/callout: ::: {.classe ...} ou ::: {#id .classe}
DIV_OPEN_RE = re.compile(
    r'^:::+\s*\{([^}]*)\}\s*$',
    re.MULTILINE
)

def md_inline_to_html(text: str) -> str:
    """
    Converte Markdown inline e blocos simples para HTML puro, necessario dentro
    de blocos HTML (como <blockquote>) onde o Jupyter/Colab nao processa Markdown.
      > texto          ->  conteudo sem o '> ' (ja esta num blockquote)
      **[texto](url)** ->  <strong><a href="url">texto</a></strong>
      *[texto](url)*   ->  <em><a href="url">texto</a></em>
      [texto](url)     ->  <a href="url">texto</a>
      **texto**        ->  <strong>texto</strong>
      *texto*          ->  <em>texto</em>
      `codigo`         ->  <code>codigo</code>
    """
    # Remove marcas de blockquote Markdown (> ) — ja estamos dentro de um <blockquote>
    text = re.sub(r'^> ?', '', text, flags=re.MULTILINE)

    # Negrito + link: **[texto](url)**
    text = re.sub(
        r'\*\*\[([^\]]+)\]\(([^)]+)\)\*\*',
        r'<strong><a href="\2">\1</a></strong>', text)
    # Italico + link: *[texto](url)*
    text = re.sub(
        r'\*\[([^\]]+)\]\(([^)]+)\)\*',
        r'<em><a href="\2">\1</a></em>', text)
    # Link simples: [texto](url)
    text = re.sub(
        r'\[([^\]]+)\]\(([^)]+)\)',
        r'<a href="\2">\1</a>', text)
    # Negrito: **texto**
    text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
    # Italico: *texto*
    text = re.sub(r'\*(.+?)\*', r'<em>\1</em>', text)
    # Codigo inline: `texto`
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    return text


def convert_callouts_old(text: str) -> str:
    """
    Converte blocos ::: {.callout-*} ... ::: e ::: {.classe} ... :::
    para Markdown/HTML compativel com Jupyter/Colab.

    Callouts conhecidos viram um blockquote com emoji e titulo em negrito.
    Divs genericos têm as marcas ::: removidas, mantendo apenas o conteudo.

    Suporta aninhamento simples.
    """
    lines = text.split('\n')
    out   = []
    i     = 0

    while i < len(lines):
        line = lines[i]
        m = re.match(r'^(:::+)\s*\{([^}]*)\}\s*$', line)

        if m:
            fence_len = len(m.group(1))   # numero de : (3, 4, ...)
            attrs     = m.group(2).strip()
            # Verifica se é um bloco de figura agrupada: {#fig-X layout-ncol=2}
            fig_group_m = re.search(r'#(fig-[\w-]+)', attrs)

            # Determina tipo de callout e titulo customizado (### Titulo)
            callout_type = None
            for ct in CALLOUT_STYLE:
                if ct in attrs:
                    callout_type = ct
                    break

            # Coleta linhas ate o ::: de fechamento correspondente
            i += 1
            depth   = 1
            inner   = []
            title_override = None

            while i < len(lines) and depth > 0:
                l = lines[i]
                # Fechamento: mesma ou maior quantidade de :
                if re.match(r'^:{' + str(fence_len) + r',}\s*$', l):
                    depth -= 1
                    if depth == 0:
                        i += 1
                        break
                # Abertura aninhada
                elif re.match(r'^:::+\s*\{', l):
                    depth += 1
                    inner.append(l)
                else:
                    # Titulo customizado dentro do callout (### Titulo)
                    # Aceita em qualquer posicao, desde que seja o primeiro heading
                    hm = re.match(r'^#{1,4}\s+(.+)$', l)
                    if hm and title_override is None and callout_type:
                        title_override = hm.group(1).strip()
                    else:
                        inner.append(l)
                i += 1

            inner_text = '\n'.join(inner).strip()

            if callout_type:
                emoji, default_title = CALLOUT_STYLE[callout_type]
                title = title_override or default_title
                # Converte Markdown inline para HTML (links, negrito, italico)
                # para que o Colab/Jupyter renderize corretamente dentro do bloco HTML
                inner_html = md_inline_to_html(inner_text)
                inner_html = inner_html.replace('\n', '<br />\n')
                block = (
                    f'<blockquote style="border-left: 4px solid #aaa; '
                    f'padding: 0.5em 1em; margin: 1em 0; background: #f9f9f9;">\n'
                    f'<strong>{emoji} {title}</strong><br />\n'
                    f'{inner_html}\n'
                    f'</blockquote>'
                )
                out.append(block)
            else:
                # Div generico: descarta as marcas ::: e mantem o conteudo
                if inner_text:
                    out.append(inner_text)
        else:
            out.append(line)
            i += 1

    return '\n'.join(out)

def convert_callouts(text: str, elem_map: dict) -> str:
    """
    Converte blocos ::: {.callout-*} ... ::: e blocos de figuras/tabelas agrupadas
    ::: {#fig-ID layout-ncol=2} ... ::: para HTML/Markdown compatível com Colab.
    """
    lines = text.split('\n')
    out   = []
    i     = 0

    while i < len(lines):
        line = lines[i]
        # Detecta abertura de ::: {atributos}
        m = re.match(r'^(:::+)\s*\{([^}]*)\}\s*$', line)

        if m:
            fence_len = len(m.group(1))
            attrs     = m.group(2).strip()

            # 1. Verifica se é um Callout conhecido
            callout_type = None
            for ct in CALLOUT_STYLE:
                if ct in attrs:
                    callout_type = ct
                    break

            # 2. Verifica se é um grupo de figuras/tabelas com ID e Layout
            # Ex: ::: {#fig-2-2 layout-ncol=2}
            group_id_m = re.search(r'#((?:fig|tbl)-[\w-]+)', attrs)
            has_layout = "layout-ncol" in attrs

            # Coleta o conteúdo interno do bloco ::: até o fechamento
            i += 1
            depth = 1
            inner = []
            title_override = None

            while i < len(lines) and depth > 0:
                l = lines[i]
                if re.match(r'^:{' + str(fence_len) + r',}\s*$', l):
                    depth -= 1
                    if depth == 0:
                        i += 1
                        break
                elif re.match(r'^:::+\s*\{', l):
                    depth += 1
                    inner.append(l)
                else:
                    # Captura heading como título de callout se existir
                    hm = re.match(r'^#{1,4}\s+(.+)$', l)
                    if hm and title_override is None and callout_type:
                        title_override = hm.group(1).strip()
                    else:
                        inner.append(l)
                i += 1

            inner_text = '\n'.join(inner).strip()

            # Lógica de Renderização:
            if callout_type:
                # Renderiza como Blockquote (Callout)
                emoji, default_title = CALLOUT_STYLE[callout_type]
                title = title_override or default_title
                inner_html = md_inline_to_html(inner_text)
                inner_html = inner_html.replace('\n', '<br />\n')
                block = (
                    f'<blockquote style="border-left: 4px solid #aaa; '
                    f'padding: 0.5em 1em; margin: 1em 0; background: #f9f9f9;">\n'
                    f'<strong>{emoji} {title}</strong><br />\n'
                    f'{inner_html}\n'
                    f'</blockquote>'
                )
                out.append(block)

            elif group_id_m and has_layout:
                
                # Dentro da lógica do 'elif group_id_m and has_layout:'
                elem_id = group_id_m.group(1)
                info = elem_map.get(elem_id)
                
                # Extrai as imagens internas
                img_find = re.findall(r'!\[.*?\]\((.*?)\)\{.*?width=([\d.]+)%?\}', inner_text)
                
                # A legenda costuma ser a última linha de texto puro no bloco
                caption_parts = [line for line in inner_text.split('\n') if not line.strip().startswith('!')]
                main_caption = caption_parts[-1].strip() if caption_parts else ""

                if img_find and info:
                    cols_html = ""
                    for path, width in img_find:
                        cols_html += (f'<td style="text-align:center; border:none;">'
                                    f'<img src="{path}" style="width:100%;" /></td>')
                    
                    block = (
                        f'<figure id="{elem_id}" style="text-align:center; margin:1em 0;">\n'
                        f'  <table style="width:100%; border:none;"><tr style="border:none;">{cols_html}</tr></table>\n'
                        f'  <figcaption><strong>{info["label_prefix"]}</strong> {main_caption}</figcaption>\n'
                        f'</figure>'
                    )
                    out.append(block)
                else:
                    out.append(inner_text)
            
            elif ".text-center" in attrs:
                # NOVO: Suporte para centralização
                block = f'<div style="text-align:center;">\n\n{inner_text}\n\n</div>'
                out.append(block)
            else:
                # Div genérico: apenas mantém o conteúdo
                if inner_text:
                    out.append(inner_text)
        else:
            out.append(line)
            i += 1

    return '\n'.join(out)

# ---------------------------------------------------------------------------
# 6. Extrai label -> numero de todos os elementos do notebook
# ---------------------------------------------------------------------------

def _chapter_from_id(label_id: str) -> str:
    """Extrai o numero do capitulo do id: fig-1-X -> '1', eq-2-3 -> '2', tbl-X -> ''"""
    m = re.match(r'(?:fig|tbl|eq|sec|lst)-(\d+)', label_id)
    return m.group(1) if m else ""


def build_element_map(notebook: dict) -> dict:
    """
    Varre o notebook e cria um mapa unificado de todos os elementos numerados.
    A numeracao e SEMPRE incremental por tipo (fig, tbl, eq),
    usando o numero do capitulo extraido do id como prefixo:
        tbl-1-X  ->  "1.1", "1.2", "1.3" ...  (contador proprio por tipo)
        fig-2-qualquer -> "2.1", "2.2" ...
        eq-1-abc -> "1.1", "1.2" ...
    Isso garante numeracao correta independente do sufixo do id.
    """
    counters = {"fig": 0, "tbl": 0, "eq": 0}
    elem_map = {}

    prefixes = {
        "fig": "Figura",
        "tbl": "Tabela",
        "eq":  "Equacao",
    }

    def make_num_str(kind: str, elem_id: str) -> str:
        """Gera num_str incremental: '<capitulo>.<contador>' ou '<contador>'."""
        counters[kind] += 1
        chap = _chapter_from_id(elem_id)
        return f"{chap}.{counters[kind]}" if chap else str(counters[kind])

    for cell in notebook.get("cells", []):
        if cell.get("cell_type") != "markdown":
            if cell.get("cell_type") == "code":
                src = source_to_str(cell.get("source", []))
                label_m   = re.search(r'#\|\s*label:\s*((fig|tbl)-[\w-]+)', src)
                caption_m = re.search(r'#\|\s*(?:tbl-cap|fig-cap):\s*["\']([^"\']+)["\']', src)
                if label_m:
                    elem_id = label_m.group(1)
                    kind    = label_m.group(2)   # "fig" ou "tbl"
                    caption = caption_m.group(1) if caption_m else ""
                    prefix  = "Figura" if kind == "fig" else "Tabela"
                    if elem_id not in elem_map:
                        num_str = make_num_str(kind, elem_id)
                        elem_map[elem_id] = {
                            "kind":    kind,
                            "num_str": num_str,
                            "label":   f"{prefix} {num_str}",
                            "caption": caption,   # guardado para injetar legenda
                            "from_code": True,    # sinaliza origem em célula de código
                            "alt":     None,
                            "path":    None,
                            "content": None,
                        }
            continue
        source = source_to_str(cell.get("source", []))

        # Figuras e tabelas-imagem: ![alt](path){#fig-* ou #tbl-*}
        for m in IMG_DEF_RE.finditer(source):
            alt      = m.group(1)
            path     = m.group(2)
            elem_id  = m.group(3)             # ex: fig-1-1 ou tbl-2-X
            kind     = m.group(4)             # "fig" ou "tbl"
            if elem_id not in elem_map:
                num_str = make_num_str(kind, elem_id)
                elem_map[elem_id] = {
                    "kind":    kind,
                    "num_str": num_str,
                    "label":   f"{prefixes[kind]} {num_str}",
                    "alt":     alt,
                    "path":    path,
                    "content": None,
                }

        # Tabelas Markdown: | col | ... {#tbl-*}  (sintaxe antiga ou Quarto)
        # for m in TBL_MD_RE.finditer(source):
        #     tbl_body    = m.group(1)
        #     tbl_caption = (m.group(2) or "").strip()  # legenda do : ... (pode ser vazio)
        #     elem_id     = m.group(3) or m.group(4)    # id Quarto ou id antigo
            
        #     if elem_id not in elem_map:
        #         num_str = make_num_str("tbl", elem_id)
        #         # Legenda: usa o : caption se existir, senão 'Tabela X.Y'
        #         label = f"Tabela {num_str}: {tbl_caption}" if tbl_caption \
        #             else f"Tabela {num_str}"
        #         elem_map[elem_id] = {
        #             "kind":    "tbl",
        #             "num_str": num_str,
        #             "label":   label,
        #             "alt":     None,
        #             "path":    None,
        #             "content": tbl_body.rstrip(),
        #         }

        # Tabelas Markdown: | col | ... {#tbl-*}
        for m in TBL_MD_RE.finditer(source):
            tbl_body    = m.group(1)
            tbl_caption = (m.group(2) or "").strip() 
            elem_id     = m.group(3) or m.group(4)
            
            if elem_id not in elem_map:
                num_str = make_num_str("tbl", elem_id)
                # Separamos o prefixo da legenda (caption)
                elem_map[elem_id] = {
                    "kind":    "tbl",
                    "num_str": num_str,
                    "label_prefix": f"Tabela {num_str}:",
                    "caption": tbl_caption, 
                    "content": tbl_body.rstrip(),
                }

        # Equacoes: $$ ... $$ {#eq-*}
        for m in EQ_DEF_RE.finditer(source):
            eq_body = m.group(1)
            elem_id = m.group(2)
            if elem_id not in elem_map:
                num_str = make_num_str("eq", elem_id)
                elem_map[elem_id] = {
                    "kind":    "eq",
                    "num_str": num_str,
                    "label":   f"Equacao {num_str}",
                    "alt":     None,
                    "path":    None,
                    "content": eq_body,
                }

        # Detecção de blocos de figuras agrupadas ::: {#fig-ID ...}
        for m in re.finditer(r'^:::+\s*\{#((fig|tbl)-[\w-]+)[^}]*\}', source, re.MULTILINE):
            elem_id = m.group(1)
            kind = m.group(2)
            if elem_id not in elem_map:
                num_str = make_num_str(kind, elem_id)
                prefix = "Figura" if kind == "fig" else "Tabela"
                elem_map[elem_id] = {
                    "kind": kind,
                    "num_str": num_str,
                    "label_prefix": f"{prefix} {num_str}:",
                    "caption": "", # Será preenchido na renderização
                    "from_group": True
                }

    return elem_map


# ---------------------------------------------------------------------------
# 7. Renderers HTML para cada tipo
# ---------------------------------------------------------------------------

def render_img_element(alt: str, path: str, elem_id: str, label: str, kind: str = "fig") -> str:
    """Figura ou tabela-imagem -> <figure> com ancora e legenda.
    Tabelas: legenda acima da imagem. Figuras: legenda abaixo.
    """
    caption = f'  <figcaption><strong>{label}:</strong> {alt}</figcaption>\n'
    img     = f'  <img src="{path}" alt="{alt}" style="max-width:100%" />\n'
    if kind == "tbl":
        body = caption + img
    else:
        body = img + caption
    return f'<figure id="{elem_id}">\n' + body + '</figure>'

def render_figure_group(content: str, elem_id: str, label_prefix: str, caption: str) -> str:
    """
    Renderiza um grupo de imagens em colunas (layout-ncol=2) com uma única legenda.
    """
    # Tenta extrair as imagens do conteúdo original para colocá-las em uma tabela HTML
    img_find = re.findall(r'!\[.*?\]\((.*?)\)\{.*?width=(.*?)\%?\}', content)
    
    if img_find:
        cols_html = ""
        for path, width in img_find:
            cols_html += f'<td style="text-align:center;"><img src="{path}" style="width:{width}%" /></td>'
        
        table_html = f'<table style="width:100%; border:none;"><tr style="border:none;">{cols_html}</tr></table>'
        
        return (
            f'<figure id="{elem_id}" style="text-align:center;">\n'
            f'  {table_html}\n'
            f'  <figcaption style="margin-top:10px;"><strong>{label_prefix}</strong> {caption}</figcaption>\n'
            f'</figure>'
        )
    return content # Caso não consiga processar, retorna o original


# def render_tbl_markdown(tbl_body: str, elem_id: str, label: str) -> str:
#     """
#     Tabela Markdown -> legenda acima, ancora no id do div, tabela abaixo.
#     A tabela Markdown em si e mantida (o Jupyter renderiza normalmente).
#     """
#     return (
#         f'<p id="{elem_id}"><strong>{label}</strong></p>\n\n'
#         f'{tbl_body}'
#     )
def render_tbl_markdown(tbl_body: str, elem_id: str, label_prefix: str, caption: str) -> str:
    """
    Renderiza a tabela no Colab com prefixo em negrito e 
    permite LaTeX/Links na legenda.
    """
    # Monta a legenda: apenas o prefixo em negrito
    full_caption = f"**{label_prefix}** {caption}" if caption else f"**{label_prefix}**"
    
    # <a> invisível para o link de referência, legenda em Markdown e a tabela
    return (
        f'<a id="{elem_id}"></a>\n\n'
        f'{full_caption}\n\n'
        f'{tbl_body}\n'
    )

def render_equation(eq_body: str, elem_id: str, num_str: str) -> str:
    """
    Equacao LaTeX -> HTML com numero (X.Y) alinhado a direita.
    Usa display math do MathJax que o Jupyter/Colab ja carrega.
    """
    # Remove os $$ externos para reinserir dentro do HTML estruturado
    inner = eq_body.strip()
    if inner.startswith("$$") and inner.endswith("$$"):
        inner = inner[2:-2].strip()

    # --- ADICIONE A LINHA ABAIXO PARA MUDAR A FORMA DE COLOREAR ---
    # Transforma \textcolor{cor}{texto} em {\color{cor}{texto}}
    inner = re.sub(r'\\textcolor\{([^}]+)\}\{([^}]+)\}', r'{\\color{\1}{\2}}', inner)
    # --------------------------------------------------------------

    return (
        f'<div id="{elem_id}" style="display:flex; align-items:center; '
        f'justify-content:space-between; margin:1em 0;">\n'
        f'  <div style="flex:1; text-align:center;">\n\n'
        f'$$\n{inner}\n$$\n\n'
        f'  </div>\n'
        f'  <div style="min-width:4em; text-align:right; color:#555;">({num_str})</div>\n'
        f'</div>'
    )


# ---------------------------------------------------------------------------
# 8. Processa uma celula: substitui definicoes e referencias
# ---------------------------------------------------------------------------

def process_cell(source, key_to_num: dict, elem_map: dict, bib: dict) -> list:
    """
    Aplica em ordem:
      1. Equacoes  $$ ... $$ {#eq-*}  -> HTML com numero
      2. Tabelas Markdown {#tbl-*}    -> div com legenda
      3. Imagens {#fig-*} e {#tbl-*} -> figure com legenda
      4. Referencias cruzadas @fig-*, @tbl-*, @eq-*  -> links
      5. Citacoes bibliograficas:
         @key    -> direta:   Autor (ano)          ABNT NBR 10520
         [@key]  -> indireta: (AUTOR, ano)
    """
    text = source_to_str(source)

    # 0. Converte callouts e divs Quarto (::: {.callout-*} ... :::)
    #text = convert_callouts(text)
    text = convert_callouts(text, elem_map)

    # 0b. Remove atributos Quarto de titulos: ### Titulo {.unnumbered} -> ### Titulo
    # text = re.sub(r'(#{1,6}[^\n{]+?)\s*\{[^}]*\}', r'\1', text)


    # 0b. Remove APENAS atributos Quarto ({.class} ou {#id}), ignorando comandos LaTeX como \mathbf{...}
    text = re.sub(r'(#{1,6}[^\n]+?)\s*\{([.#][^}]*)\}', r'\1', text)


    # 1. Equacoes
    def replace_eq(m):
        eq_body = m.group(1)
        elem_id = m.group(2)
        info = elem_map.get(elem_id)
        if info:
            num_str = info["num_str"]
        else:
            num_str = _chapter_from_id(elem_id) or elem_id
        return render_equation(eq_body, elem_id, num_str)

    text = EQ_DEF_RE.sub(replace_eq, text)

    # 2. Tabelas Markdown (sintaxe antiga ou Quarto)
    # def replace_tbl_md(m):
    #     tbl_body = m.group(1).rstrip()
    #     elem_id  = m.group(3) or m.group(4)
    #     info = elem_map.get(elem_id)
    #     label = info["label"] if info else f"Tabela {_chapter_from_id(elem_id) or elem_id}"
    #     return render_tbl_markdown(tbl_body, elem_id, label)
    # 2. Tabelas Markdown
    def replace_tbl_md(m):
        tbl_body = m.group(1).rstrip()
        elem_id  = m.group(3) or m.group(4)
        info = elem_map.get(elem_id)
        if info:
            return render_tbl_markdown(tbl_body, elem_id, info["label_prefix"], info["caption"])
        else:
            return render_tbl_markdown(tbl_body, elem_id, f"Tabela {_chapter_from_id(elem_id)}:", "")
        
    text = TBL_MD_RE.sub(replace_tbl_md, text)

    # 3. Imagens (fig e tbl-imagem)
    def replace_img(m):
        alt     = m.group(1)
        path    = m.group(2)
        elem_id = m.group(3)
        kind    = m.group(4)             # "fig" ou "tbl"
        info = elem_map.get(elem_id)
        label = info["label"] if info else \
            ("Figura" if kind == "fig" else "Tabela") + \
            f" {_chapter_from_id(elem_id) or elem_id}"
        return render_img_element(alt, path, elem_id, label, kind)

    text = IMG_DEF_RE.sub(replace_img, text)

    
    # # 4. Referencias cruzadas @fig-*, @tbl-*, @eq-*
    # def replace_crossref(m):
    #     elem_id = m.group(1)
    #     info = elem_map.get(elem_id)
        
    #     if info:
    #         # Reconstrói o nome amigável: Figura/Tabela + Número
    #         # Ignora o 'label' longo que contém a legenda
    #         prefix = "Tabela" if info["kind"] == "tbl" else \
    #                  "Figura" if info["kind"] == "fig" else "Equação"
    #         label_curto = f"{prefix} {info['num_str']}"
    #     else:
    #         # Fallback caso o elemento não tenha sido mapeado
    #         kind_raw = elem_id.split('-')[0]
    #         prefix = "Tabela" if kind_raw == "tbl" else \
    #                  "Figura" if kind_raw == "fig" else "Equação"
    #         label_curto = f"{prefix} {_chapter_from_id(elem_id) or elem_id}"
            
    #     return f"[{label_curto}](#{elem_id})"
    
    # text = re.sub(r'@((fig|tbl|eq)-[\w-]+)', replace_crossref, text)


    # 4. Referencias cruzadas @fig-*, @tbl-*, @eq-*
    # Suporta tres sintaxes:
    #   @fig-3-X            -> [Figura 3.1](#fig-3-X)
    #   [-@fig-3-X]         -> [3.1](#fig-3-X)          (apenas numero)
    #   [Texto @fig-3-X]    -> [Texto 3.1](#fig-3-X)    (prefixo customizado)

    def _num_str_for(elem_id: str) -> str:
        """Retorna o num_str do elemento ou fallback."""
        info = elem_map.get(elem_id)
        if info:
            return info["num_str"]
        return _chapter_from_id(elem_id) or elem_id

    def _prefix_for(elem_id: str) -> str:
        """Retorna o prefixo textual (Figura/Tabela/Equação)."""
        info = elem_map.get(elem_id)
        kind_raw = info["kind"] if info else elem_id.split('-')[0]
        return "Tabela" if kind_raw == "tbl" else \
            "Figura" if kind_raw == "fig" else "Equação"

    def replace_crossref_bracket(m):
        """[-@id] -> numero so;  [Texto @id] -> Texto numero."""
        inner   = m.group(1)           # conteudo dentro de [...]
        # Extrai o id (fig|tbl|eq)-...
        id_m = re.search(r'@((fig|tbl|eq)-[\w-]+)', inner)
        if not id_m:
            return m.group(0)          # nao e cross-ref, nao mexe
        elem_id = id_m.group(1)
        num     = _num_str_for(elem_id)
        # Parte antes do @  (ex: "Graf. " ou "-" ou vazio)
        prefix_text = inner[:id_m.start()].strip().lstrip('-').strip()
        if prefix_text:
            label_curto = f"{prefix_text} {num}"
        else:
            label_curto = num           # [-@id] -> apenas o numero
        return f"[{label_curto}](#{elem_id})"

    def replace_crossref_bare(m):
        """@id isolado (fora de []) -> [Figura/Tabela/Equação X.Y](#id)."""
        elem_id = m.group(1)
        if CROSSREF_RE.match(elem_id):
            # confirma que é cross-ref (fig|tbl|eq|sec...)
            num = _num_str_for(elem_id)
            prefix = _prefix_for(elem_id)
            return f"[{prefix} {num}](#{elem_id})"
        return m.group(0)

    # Primeiro: colchetes com @  [texto @id]  ou  [-@id]
    text = re.sub(r'\[([^\]]*@(?:fig|tbl|eq)-[\w-]+[^\]]*)\]',
                replace_crossref_bracket, text)
    # Depois: @id isolado, nao precedido de [
    text = re.sub(r'(?<!\[)@((fig|tbl|eq)-[\w-]+)', replace_crossref_bare, text)


    # 5. Citacoes bibliograficas
    #    [@key]  -> indireta: (AUTOR, ano)
    #    @key    -> direta:   Autor (ano)
    #    [@key1; @key2] -> multiplas indiretas: (AUTOR1, ano; AUTOR2, ano)

    def _fmt_key(key: str, mode: str) -> str:
        """Formata uma chave bib no modo 'direct' ou 'indirect'."""
        key = key.strip().lstrip("@")
        if key not in bib:
            return f"?{key}"
        if mode == "direct":
            return cite_direct(bib[key])
        else:
            # Indireta sem parênteses externos (serão adicionados depois)
            return cite_indirect(bib[key])

    def replace_indirect(m):
        """[@key] ou [@key1; @key2] -> (AUTOR1, ano; AUTOR2, ano)"""
        inner = m.group(1)
        keys  = [k.strip() for k in re.split(r'[;,]', inner)]
        parts = []
        for k in keys:
            k = k.lstrip("@").strip()
            if not k:
                continue
            if k not in bib:
                parts.append(f"?{k}")
                continue
            fields = bib[k]
            year     = fields.get("year", "s.d.")
            surnames = _last_names(fields.get("author", ""))
            upper    = [s.upper() for s in surnames]
            if not upper:
                parts.append(f"({year})")
            elif len(upper) == 1:
                parts.append(f"{upper[0]}, {year}")
            elif len(upper) == 2:
                parts.append(f"{upper[0]}; {upper[1]}, {year}")
            else:
                parts.append(f"{upper[0]} et al., {year}")
        return "(" + "; ".join(parts) + ")"

    def replace_direct(m):
        """@key isolado (fora de colchetes) -> Autor (ano)"""
        key = m.group(1)
        if CROSSREF_RE.match(key):
            return m.group(0)   # deixa para o passo 4 tratar
        return _fmt_key(key, "direct")

    # Indireta primeiro (evita que @key dentro de [] seja consumido pelo direto)
    text = re.sub(r'\[@([\w:;@\s,-]+)\]', replace_indirect, text)
    # Direta: @key isolado, nao precedido de [
    text = re.sub(r'(?<!\[)@([\w:-]+)', replace_direct, text)

    return str_to_source(text)


# ---------------------------------------------------------------------------
# 9. Extrai citacoes bibliograficas (exclui cross-refs)
# ---------------------------------------------------------------------------

def extract_citations(notebook: dict) -> list:
    seen, ordered = set(), []
    cite_re = re.compile(r'@([\w:-]+)')
    for cell in notebook.get("cells", []):
        if cell.get("cell_type") != "markdown":
            continue
        source = source_to_str(cell.get("source", []))
        for m in cite_re.finditer(source):
            key = m.group(1)
            if CROSSREF_RE.match(key):
                continue
            if key not in seen:
                seen.add(key)
                ordered.append(key)
    return ordered


def extract_image_paths(notebook: dict) -> list:
    found = set()
    md_img_re   = re.compile(r'!\[.*?\]\(([^)\s"\']+)')
    html_img_re = re.compile(r'<img[^>]+src=["\']([^"\']+)["\']')
    for cell in notebook.get("cells", []):
        if cell.get("cell_type") != "markdown":
            continue
        source = source_to_str(cell.get("source", []))
        for m in md_img_re.finditer(source):
            found.add(m.group(1))
        for m in html_img_re.finditer(source):
            found.add(m.group(1))
    return sorted(p for p in found if not re.match(r'https?://|data:', p))




# ---------------------------------------------------------------------------
# 10. Limpeza do notebook para distribuicao
# ---------------------------------------------------------------------------

# Padrao para detectar celulas de secao de referencias do Quarto
REF_SECTION_RE = re.compile(
    r'##\s+Refer[eê]ncias?\s+(do\s+)?Cap[ií]tulo|'
    r'##\s+Refer[eê]ncias?\s+Bibliogr[aá]ficas?',
    re.IGNORECASE
)


def clean_notebook(notebook: dict) -> dict:
    """
    Limpa o notebook para distribuicao aos alunos:
      - Remove metadados 'quarto' do notebook
      - Remove celulas raw YAML (--- ... ---)
      - Remove celulas de codigo vazias
      - Remove celulas de secao de referencias antiga (substituida pela injetada)
    Retorna o notebook modificado in-place.
    """
    # Remove metadados quarto
    meta = notebook.get("metadata", {})
    for key in ("quarto", "quarto-version"):
        meta.pop(key, None)

    cleaned = []
    removed = {
        "yaml": 0, 
        "empty_code": 0, 
        "ref_section": 0, 
        "quarto_params": 0  # <--- Esta linha resolve o KeyError
    }

    for cell in notebook.get("cells", []):
        src = source_to_str(cell.get("source", []))
        kind = cell.get("cell_type", "")

        # Limpa parâmetros Quarto e injeta tag de ocultar no Colab
        if kind == "code":
            lines = src.splitlines(keepends=True)
            
            # 1. Verifica se deve esconder (echo: false)
            should_hide = any("echo: false" in l for l in lines)
            
            # 2. Filtra: remove linhas #| E remove qualquer # @title que já exista
            # para evitar a duplicação que você observou
            new_lines = [
                l for l in lines 
                if not l.strip().startswith("#|") and 
                not l.strip().startswith("# @title")
            ]
            
            # 3. Se houve limpeza de parâmetros Quarto
            if len(new_lines) != len(lines):
                removed["quarto_params"] += 1
                
                # Une as linhas e remove linhas em branco do topo
                src = "".join(new_lines).lstrip('\n').lstrip('\r')
                
                # 4. Injeta a tag apenas UMA vez se for echo: false
                if should_hide:
                    src = "# @title { display-mode: \"form\" }\n" + src
                
                cell["source"] = str_to_source(src)
                
                # 5. Ajusta metadados para garantir que o Colab oculte
                if should_hide:
                    if "metadata" not in cell: cell["metadata"] = {}
                    cell["metadata"]["cellView"] = "form"
                    cell["metadata"]["jupyter"] = {"source_hidden": True}

        # Celulas raw YAML (--- ... ---)
        if kind == "raw" and src.strip().startswith("---"):
            removed["yaml"] += 1
            continue

        # Celulas de codigo vazias
        if kind == "code" and not src.strip():
            removed["empty_code"] += 1
            continue

        # Secao de referencias antiga (sera substituida pela injetada)
        if kind == "markdown" and REF_SECTION_RE.search(src):
            removed["ref_section"] += 1
            continue

        cleaned.append(cell)

    notebook["cells"] = cleaned

    if any(removed.values()):
        parts = []
        if removed["yaml"]:        parts.append(f"{removed['yaml']} celulas YAML")
        if removed["empty_code"]:  parts.append(f"{removed['empty_code']} cod.vazias")
        if removed["ref_section"]: parts.append(f"{removed['ref_section']} secoes-ref antigas")
        print(f"  Limpeza: removidas {', '.join(parts)}")
        
    return notebook

# ---------------------------------------------------------------------------
# 11. Lista de referencias bibliograficas
# ---------------------------------------------------------------------------

def build_reference_list(citations: list, bib: dict) -> tuple:
    key_to_num = {}
    lines = ["## Referencias\n"]
    for i, key in enumerate(citations, start=1):
        key_to_num[key] = i
        ref_text = format_entry(key, bib[key]) if key in bib \
            else f"*Referencia nao encontrada para: {key}*"
        lines.append(ref_text)
    return "\n\n".join(lines), key_to_num


# ---------------------------------------------------------------------------
# 12b. Processa um unico notebook para EPUB
# ---------------------------------------------------------------------------

def process_notebook_epub(nb_path: Path, bib: dict, out_path: Path) -> list:
    """
    Gera versao do notebook para EPUB — identico ao modo --batch (alunos),
    pois ambos resolvem citacoes e refs em texto simples por capitulo.
    A unica diferenca e o nome do arquivo de saida (_epub.ipynb).
    """
    return process_notebook(nb_path, bib, out_path)



# ---------------------------------------------------------------------------
# 12. Processa um unico notebook
# ---------------------------------------------------------------------------

def process_notebook(nb_path: Path, bib: dict, out_path: Path) -> list:
    notebook    = json.loads(nb_path.read_text(encoding="utf-8"))
    elem_map    = build_element_map(notebook)
    citations   = extract_citations(notebook)
    image_paths = extract_image_paths(notebook)

    # Log
    figs = {k: v for k, v in elem_map.items() if v["kind"] == "fig"}
    tbls = {k: v for k, v in elem_map.items() if v["kind"] == "tbl"}
    eqs  = {k: v for k, v in elem_map.items() if v["kind"] == "eq"}
    if figs: print(f"  Figuras  ({len(figs)}): {list(figs.keys())}")
    if tbls: print(f"  Tabelas  ({len(tbls)}): {list(tbls.keys())}")
    if eqs:  print(f"  Equacoes ({len(eqs)}):  {list(eqs.keys())}")
    if not citations:
        print(f"  [!] Nenhuma citacao bibliografica encontrada.")
    else:
        print(f"  Citacoes ({len(citations)}): {citations}")
    if image_paths:
        print(f"  Imagens  ({len(image_paths)}): {image_paths}")

    ref_markdown, key_to_num = build_reference_list(citations, bib)

    # Limpeza antes de processar
    notebook = clean_notebook(notebook)

    # Remove atributo 'scoped' inválido no EPUB gerado pelo pandas
    for cell in notebook.get("cells", []):
        for output in cell.get("outputs", []):
            if "text/html" in output.get("data", {}):
                html = output["data"]["text/html"]
                if isinstance(html, list):
                    html = "".join(html)
                html = html.replace("<style scoped>", "<style>")
                output["data"]["text/html"] = str_to_source(html)

    # Processa celulas
    for cell in notebook.get("cells", []):
        if cell.get("cell_type") == "markdown":
            cell["source"] = process_cell(
                cell.get("source", []), key_to_num, elem_map, bib
            )

    # Mapa fingerprint -> elem_id para células de código com #| label: fig-*/tbl-*
    # Feito ANTES do clean_notebook apagar as linhas #|
    # O fingerprint é o conteúdo sem linhas #| (que sobrevive ao clean_notebook)
    notebook_orig = json.loads(nb_path.read_text(encoding="utf-8"))
    fingerprint_to_label = {}
    for cell in notebook_orig.get("cells", []):
        if cell.get("cell_type") != "code":
            continue
        src_orig = source_to_str(cell.get("source", []))
        m = re.search(r'#\|\s*label:\s*((fig|tbl)-[\w-]+)', src_orig)
        if m:
            # Fingerprint: linhas sem #| e sem # @title, stripped
            fp_lines = [l for l in src_orig.splitlines()
                        if not l.strip().startswith("#|")]
            fp = "\n".join(fp_lines).strip()
            fingerprint_to_label[fp] = m.group(1)

    # Injeta legendas e lista de referencias
    new_cells, ref_injected = [], False
    for cell in notebook.get("cells", []):
        src = source_to_str(cell.get("source", []))

        # Injeta legenda para células fig-*/tbl-* de código:
        #   tbl (echo:false): legenda ANTES (código oculto, tabela aparece logo)
        #   fig (echo:true):  legenda DEPOIS (código visível, figura aparece após)
        legend_cell = None
        if cell.get("cell_type") == "code":
            fp_lines = [l for l in src.splitlines()
                        if not l.strip().startswith("# @title")]
            fp = "\n".join(fp_lines).strip()
            elem_id = fingerprint_to_label.get(fp)
            if elem_id:
                info = elem_map.get(elem_id)
                if info and info.get("from_code"):
                    caption = info.get("caption", "")
                    legenda = f"**{info['label']}:** {caption}" if caption \
                        else f"**{info['label']}**"
                    legend_cell = {
                        "cell_type": "markdown",
                        "metadata":  {},
                        "source":    str_to_source(legenda)
                    }
                    if info.get("kind") == "tbl":
                        new_cells.append(legend_cell)
                        legend_cell = None  # já inserida antes
                    else:
                        # fig: injeta legenda como output logo após o output de imagem
                        outputs = cell.get("outputs", [])
                        img_idx = next(
                            (i for i, o in enumerate(outputs)
                             if "image/png" in o.get("data", {})
                             or o.get("output_type") == "display_data"),
                            None
                        )
                        legend_output = {
                            "output_type": "display_data",
                            "metadata": {},
                            "data": {
                                "text/markdown": [legenda + "\n"],
                                "text/plain":    [legenda]
                            }
                        }
                        if img_idx is not None:
                            outputs.insert(img_idx + 1, legend_output)
                        else:
                            outputs.append(legend_output)
                        cell["outputs"] = outputs
                        legend_cell = None  # já inserida nos outputs

        if "\\\\printbibliography" in src:
            cell["source"] = str_to_source(ref_markdown)
            ref_injected = True
        new_cells.append(cell)


    if not ref_injected and citations:
        new_cells.append({
            "cell_type": "markdown",
            "metadata":  {},
            "source":    str_to_source(ref_markdown)
        })

    notebook["cells"] = new_cells
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps(notebook, ensure_ascii=False, indent=1),
        encoding="utf-8"
    )
    print(f"  -> Salvo: {out_path}")
    return image_paths


# ---------------------------------------------------------------------------
# 13. Copia imagens
# ---------------------------------------------------------------------------

def copy_images(nb_source_dir: Path, out_dir: Path, image_paths: list):
    for img_rel in image_paths:
        src = nb_source_dir / img_rel
        dst = out_dir / img_rel
        if src.exists() and src.resolve() != dst.resolve():
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            print(f"  -> Imagem: {img_rel}")
        elif not src.exists():
            alt_src = Path(img_rel)
            if alt_src.exists() and alt_src.resolve() != dst.resolve():
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(alt_src, dst)
                print(f"  -> Imagem (raiz): {img_rel}")
            else:
                print(f"  [!] Imagem nao encontrada: {src}")


# ---------------------------------------------------------------------------
# 14b. Modo batch EPUB
# ---------------------------------------------------------------------------

QUARTO_EPUB_YML = """\
# _quarto_epub.yml
# Gerado automaticamente por gerar_notebooks_alunos.py --epub
# Use: quarto render --config _quarto_epub.yml --to epub

project:
  type: book
  output-dir: _book

book:
  title: "Sistemas Inteligentes e Mineração de Dados"
  subtitle: "2ª Edição: Do Weka ao Python"
  author: "José Artur Quilici-Gonzalez, Francisco de Assis Zampirolli e Fábio Rezende de Souza"
  date: "today"
  chapters:
    - index.qmd
{chapters}

lang: pt-BR

format:
  epub:
    toc: true
    number-sections: true
    css: styles.css 
"""

def run_batch_epub(bib_path: str, out_dir: str):
    """
    Gera notebooks pre-processados para EPUB em <out_dir>/capXX/capXX_epub.ipynb
    e cria _quarto_epub.yml apontando para eles.
    As refs ja estao resolvidas como texto simples por capitulo.

    Uso posterior:
        quarto render --config _quarto_epub.yml --to epub
    """
    bib      = parse_bib(bib_path)
    out_root = Path(out_dir)
    EXCLUDE  = ("_dist", "_executado", "_fixed", "_aluno", "_epub")
    notebooks = sorted([
        Path(p) for p in glob.glob("cap*/cap*.ipynb")
        if not any(s in Path(p).stem for s in EXCLUDE)
    ])
    if not notebooks:
        print("Nenhum notebook encontrado com o padrao: cap*/cap*.ipynb")
        return

    print(f"[EPUB] Encontrados {len(notebooks)} notebooks:\n")
    chapter_lines = []
    total_imgs = 0

    for nb_path in notebooks:
        cap_name   = nb_path.parent.name
        out_cap    = out_root / cap_name
        epub_name  = nb_path.stem + "_epub.ipynb"
        out_nb     = out_cap / epub_name
        print(f"[{cap_name}] {nb_path}")
        image_paths = process_notebook_epub(nb_path, bib, out_nb)
        if image_paths:
            copy_images(nb_path.parent, out_cap, image_paths)
            total_imgs += len(image_paths)
        # Caminho relativo para o _quarto_epub.yml
        chapter_lines.append(f"    - {out_nb.as_posix()}")
        print()

    # Gera _quarto_epub.yml
    yml_path = Path("_quarto_epub.yml")
    yml_content = QUARTO_EPUB_YML.format(
        chapters="\n".join(chapter_lines)
    )
    yml_path.write_text(yml_content, encoding="utf-8")
    print(f"_quarto_epub.yml gerado.")

    # Gera render_epub.sh
    sh_content = (
        "#!/usr/bin/env bash\n"
        "# render_epub.sh - Gerado por gerar_notebooks_alunos.py --epub\n"
        "# Substitui temporariamente _quarto.yml pelo config EPUB, renderiza e restaura.\n"
        "set -e\n"
        "ORIGINAL=\"_quarto.yml\"\n"
        "EPUB_CFG=\"_quarto_epub.yml\"\n"
        "BACKUP=\"_quarto_backup.yml\"\n"
        "if [ ! -f \"$EPUB_CFG\" ]; then\n"
        "  echo \"Erro: $EPUB_CFG nao encontrado. Rode primeiro:\"\n"
        "  echo \"  python gerar_notebooks_alunos.py --epub references.bib\"\n"
        "  exit 1\n"
        "fi\n"
        "echo \"Salvando $ORIGINAL -> $BACKUP\"\n"
        "cp \"$ORIGINAL\" \"$BACKUP\"\n"
        "echo \"Ativando config EPUB...\"\n"
        "cp \"$EPUB_CFG\" \"$ORIGINAL\"\n"
        "echo \"Renderizando EPUB...\"\n"
        "quarto render --to epub\n"
        "STATUS=$?\n"
        "echo \"Restaurando $BACKUP -> $ORIGINAL\"\n"
        "cp \"$BACKUP\" \"$ORIGINAL\"\n"
        "rm \"$BACKUP\"\n"
        "if [ $STATUS -eq 0 ]; then\n"
        "  echo \"\"; echo \"EPUB gerado com sucesso em _book/\"\n"
        "else\n"
        "  echo \"\"; echo \"Erro (codigo $STATUS). _quarto.yml restaurado.\"\n"
        "  exit $STATUS\n"
        "fi\n"
    )
    sh_path = Path("render_epub.sh")
    sh_path.write_text(sh_content, encoding="utf-8")
    sh_path.chmod(sh_path.stat().st_mode | 0o755)
    print(f"render_epub.sh gerado.")
    print(f"\nPara gerar o EPUB, execute:")
    print(f"  ./render_epub.sh")
    print(f"\nConcluido! {len(notebooks)} notebooks e {total_imgs} imagens em '{out_root}/'")


# ---------------------------------------------------------------------------
# 14. Modo batch (alunos)
# ---------------------------------------------------------------------------

def run_batch(bib_path: str, out_dir: str):
    bib      = parse_bib(bib_path)
    out_root = Path(out_dir)
    EXCLUDE  = ("_dist", "_executado", "_fixed")
    notebooks = sorted([
        Path(p) for p in glob.glob("cap*/cap*.ipynb")
        if not any(s in Path(p).stem for s in EXCLUDE)
    ])
    if not notebooks:
        print("Nenhum notebook encontrado com o padrao: cap*/cap*.ipynb")
        return

    print(f"Encontrados {len(notebooks)} notebooks:\n")
    total_imgs = 0
    for nb_path in notebooks:
        cap_name = nb_path.parent.name
        out_cap  = out_root / cap_name
        # Nome de saida: cap01_aluno.ipynb
        aluno_name = nb_path.stem + "_aluno.ipynb"
        out_nb   = out_cap  / aluno_name
        print(f"[{cap_name}] {nb_path}")
        image_paths = process_notebook(nb_path, bib, out_nb)
        if image_paths:
            copy_images(nb_path.parent, out_cap, image_paths)
            total_imgs += len(image_paths)
        print()

    # Gera README.md
    readme = out_root / "README.md"
    readme.write_text(
        "# Notebooks para Alunos\n\n"
        "Notebooks dos capítulos com referências bibliográficas, "
        "figuras, tabelas e equações renderizadas para Jupyter/Colab.\n\n"
        "## Estrutura\n"
        "`capXX/capXX_aluno.ipynb` — notebook do capítulo XX\n"
        "`capXX/images/` — imagens do capítulo\n\n"
        "## Como usar\n"
        "```bash\n"
        "jupyter lab cap01/cap01_aluno.ipynb\n"
        "```\n\n"
        "## Características\n"
        "- Referências bibliográficas formatadas (ABNT)\n"
        "- Figuras com legenda numerada\n"
        "- Tabelas com legenda acima\n"
        "- Equações numeradas\n"
        "- Sem metadados Quarto\n",
        encoding="utf-8"
    )
    print(f"README.md gerado em '{readme}'")

    print(
        f"Concluido! {len(notebooks)} notebooks e {total_imgs} imagens "
        f"exportados para '{out_root}/'"
    )


# ---------------------------------------------------------------------------
# 15. CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Injeta referencias em notebooks Quarto para distribuicao.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("--batch", action="store_true",
                        help="Processa todos cap*/cap*.ipynb para distribuicao (Jupyter/Colab)")
    parser.add_argument("--epub", action="store_true",
                        help="Processa todos cap*/cap*.ipynb para EPUB (refs por capitulo em texto)")
    parser.add_argument("--out-dir", default="notebooks_alunos",
                        help="Pasta de saida no modo batch/epub (padrao: notebooks_alunos)")
    parser.add_argument("notebook", nargs="?",
                        help="Caminho para o .ipynb (modo unico)")
    parser.add_argument("bib", help="Caminho para o references.bib")
    parser.add_argument("--output", "-o", help="Saida do .ipynb no modo unico")
    args = parser.parse_args()

    if args.epub:
        run_batch_epub(args.bib, args.out_dir)
    elif args.batch:
        run_batch(args.bib, args.out_dir)
    else:
        if not args.notebook:
            parser.error("Informe o notebook ou use --batch ou --epub")
        nb_path  = Path(args.notebook)
        out_path = Path(args.output) if args.output else \
                   nb_path.parent / (nb_path.stem + "_dist.ipynb")
        bib = parse_bib(args.bib)
        print(f"Processando: {nb_path}")
        image_paths = process_notebook(nb_path, bib, out_path)
        if image_paths:
            copy_images(nb_path.parent, out_path.parent, image_paths)


if __name__ == "__main__":
    main()