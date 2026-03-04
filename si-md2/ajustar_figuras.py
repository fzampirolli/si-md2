import json
import re
import os

# Configurações
CAP = "02"
NOTEBOOK_PATH = f"cap{CAP}/cap{CAP}.ipynb"

def transformar_figura(match):
    legenda = match.group(1)
    path = match.group(2)
    label = match.group(3)
    
    # Novo formato solicitado (Bloco Div com ID)
    novo_formato = (
        f"::: {{#{label}}}\n\n"
        f"![]( {path} ){{width=80% fig-align=\"center\"}}\n\n"
        f"{legenda}\n"
        f":::"
    )
    return novo_formato

def processar_notebook():
    if not os.path.exists(NOTEBOOK_PATH):
        print(f"Erro: Arquivo {NOTEBOOK_PATH} não encontrado.")
        return

    with open(NOTEBOOK_PATH, 'r', encoding='utf-8') as f:
        nb = json.load(f)

    # Regex para capturar: ![Legenda](Caminho){#Label}
    padrao = re.compile(r'!\[(.*?)\]\((.*?)\)\{#(.*?)\}')

    alterou = False
    for cell in nb['cells']:
        if cell['cell_type'] == 'markdown':
            novo_conteudo = []
            for linha in cell['source']:
                # Aplica a transformação na linha
                nova_linha = padrao.sub(transformar_figura, linha)
                if nova_linha != linha:
                    alterou = True
                novo_conteudo.append(nova_linha)
            cell['source'] = novo_conteudo

    if alterou:
        with open(NOTEBOOK_PATH, 'w', encoding='utf-8') as f:
            json.dump(nb, f, ensure_ascii=False, indent=1)
        print(f"Sucesso: Figuras do {NOTEBOOK_PATH} foram atualizadas.")
    else:
        print("Nenhuma figura no padrão antigo foi encontrada.")

if __name__ == "__main__":
    processar_notebook()
