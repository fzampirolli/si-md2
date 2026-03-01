#!/usr/bin/env python3
import nbformat
from nbformat import NotebookNode
import json
import sys
import os
import glob

modo = sys.argv[1] if len(sys.argv) > 1 else "limpar"

notebooks = glob.glob("**/*.ipynb", recursive=True)
notebooks = [n for n in notebooks if ".ipynb_checkpoints" not in n]

MARCADORES = ["IPython.core.display.HTML", "download=", "Baixar Arquivo"]

def dict_to_node(obj):
    if isinstance(obj, dict):
        return NotebookNode({k: dict_to_node(v) for k, v in obj.items()})
    elif isinstance(obj, list):
        return [dict_to_node(item) for item in obj]
    return obj

for notebook_path in notebooks:
    backup_path = notebook_path.replace(".ipynb", "_download_backup.json")

    # Pula arquivos vazios ou corrompidos
    if os.path.getsize(notebook_path) == 0:
        print(f"[AVISO] {notebook_path}: arquivo vazio, pulando.")
        continue

    try:
        with open(notebook_path, "r", encoding="utf-8") as f:
            nb = nbformat.read(f, as_version=4)
    except Exception as e:
        print(f"[AVISO] {notebook_path}: erro ao ler ({e}), pulando.")
        continue

    if modo == "limpar":
        backup = {}
        for i, cell in enumerate(nb.cells):
            if cell.cell_type != "code":
                continue
            outputs = cell.get("outputs", [])
            if any(m in str(outputs) for m in MARCADORES):
                backup[str(i)] = {
                    "outputs": [dict(o) for o in outputs],
                    "execution_count": cell.execution_count
                }
                cell["outputs"] = []
                cell["execution_count"] = None
        if backup:
            with open(backup_path, "w", encoding="utf-8") as f:
                json.dump(backup, f, ensure_ascii=False)
            print(f"[limpar] {notebook_path}: {len(backup)} célula(s) limpas.")
        else:
            print(f"[limpar] {notebook_path}: nenhuma célula de download encontrada.")

    elif modo == "restaurar":
        if not os.path.exists(backup_path):
            print(f"[restaurar] {notebook_path}: backup não encontrado, pulando.")
            continue
        with open(backup_path, "r", encoding="utf-8") as f:
            backup = json.load(f)
        for i_str, data in backup.items():
            nb.cells[int(i_str)]["outputs"] = dict_to_node(data["outputs"])
            nb.cells[int(i_str)]["execution_count"] = data["execution_count"]
        os.remove(backup_path)
        print(f"[restaurar] {notebook_path}: {len(backup)} célula(s) restauradas.")

    with open(notebook_path, "w", encoding="utf-8") as f:
        nbformat.write(nb, f)