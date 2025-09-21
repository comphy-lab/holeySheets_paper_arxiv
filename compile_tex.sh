#!/bin/bash

# Script to compile LaTeX files using latexmk and clean aux files
# Preserves PDFs and .synctex.gz files

set -o pipefail

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo -e "${RED}Error: required command '$1' not found in PATH${NC}" >&2
    exit 127
  }
}

# Ensure latexmk is available
need_cmd latexmk

# Function to compile a tex file with latexmk
compile_tex() {
    local texfile=$1
    echo -e "${GREEN}Compiling ${texfile} with latexmk...${NC}"
    latexmk -pdf -bibtex -synctex=1 "${texfile}"
}

# Function to clean aux files via latexmk (keeps PDF and synctex)
clean_tex() {
    local texfile=$1
    echo "Cleaning aux files for ${texfile} (keeping PDF and synctex)..."
    latexmk -c "${texfile}"
}

echo "LaTeX Compilation Script (latexmk)"
echo "=================================="

compile_tex "ms.tex"; ms_status=$?
compile_tex "supplement.tex"; supp_status=$?

# Count words in ms.tex
echo ""
echo "Counting words in ms.tex..."
if [ -f "ms.tex" ]; then
    # Use texcount if available, otherwise use detex + wc
    if command -v texcount >/dev/null 2>&1; then
        word_count=$(texcount -sum -brief ms.tex | grep -o '[0-9]*' | tail -1)
        echo -e "${GREEN}✓ Word count (texcount): ${word_count} words${NC}"
    elif command -v detex >/dev/null 2>&1; then
        word_count=$(detex ms.tex | wc -w | tr -d ' ')
        echo -e "${GREEN}✓ Word count (detex): ${word_count} words${NC}"
    else
        # Fallback: simple grep-based count (excludes comments and commands)
        word_count=$(grep -v '^%' ms.tex | sed 's/\\[a-zA-Z]*{[^}]*}//g' | sed 's/\\[a-zA-Z]*//g' | wc -w | tr -d ' ')
        echo -e "${GREEN}✓ Word count (approximate): ${word_count} words${NC}"
    fi
else
    echo -e "${RED}Warning: ms.tex not found${NC}"
fi

# Clean aux files
echo ""
echo "Cleaning temporary files with latexmk..."
clean_tex "ms.tex"
clean_tex "supplement.tex"

# Summary
echo ""
echo "Compilation Summary:"
echo "===================="
if [ $ms_status -eq 0 ]; then
    echo -e "${GREEN}✓ ms.pdf compiled successfully${NC}"
else
    echo -e "${RED}✗ ms.pdf compilation failed${NC}"
fi

if [ $supp_status -eq 0 ]; then
    echo -e "${GREEN}✓ supplement.pdf compiled successfully${NC}"
else
    echo -e "${RED}✗ supplement.pdf compilation failed${NC}"
fi

echo ""
echo "Preserved files: PDFs and .synctex.gz (via latexmk -c)"

# Exit with error if any compilation failed
if [ $ms_status -ne 0 ] || [ $supp_status -ne 0 ]; then
    exit 1
fi

exit 0
