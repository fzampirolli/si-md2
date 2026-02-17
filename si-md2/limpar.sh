#!/bin/bash
rm -rf .quarto/
find . -name "*_cache" -type d -exec rm -rf {} +
rm -f *.bcf *.bbl *.blg *.run.xml *.out *.log *.toc *.aux *.lof *.lot