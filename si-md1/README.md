# Conversão de docx para markdown

```bash
pandoc Sist_Intel_final_f.docx -f docx -t markdown \
--extract-media=. \
--wrap=none \
-o Sist_Intel_final_f.md
```

Os capítulos PDFs 01 a 06 foram criados manualmente a partir do original Sist_Intel_final_f.pdf

O texto do arquivo md foi copiado e colado em ../si-md2/cap*/*.ipynb

