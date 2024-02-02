#!/bin/bash

OBJDUMP="/opt/homebrew/opt/binutils/bin/objdump"
AWK="gawk"

INPUT_DIR="../../../tezt/tests/riscv-tests/generated"
OUTPUT_DIR="tests"

for file in "$INPUT_DIR"/*; do
    OUTPUT_FILE="${OUTPUT_DIR}/$(basename -- "$file")-objdump"
    $OBJDUMP --disassemble -M no-aliases,numeric -D "$file" | $AWK -F '\t' '
    /^Disassembly of section .text/ {processing = 1; next}
    /^Disassembly of section/ {processing = 0}
    processing && NF>2 {
        split($3, opcode_parts, " ");
        opcode = opcode_parts[1];
        line = "";
        for (i=3; i<=NF; i++) line = line $i " ";
        sub(/[ \t]+$/, "", line);
        if (opcode ~ /^(beq|bne|blt|bge|bltu|bgeu|jal|jalr)$/) {
            n = split($(NF), a, ",");
            immediate = a[n];
            address = strtonum("0x" substr($1, 5, length($1)-1));
            immediate_value = strtonum("0x" immediate);
            result = immediate_value - address;
            print line result;
        } else {
            print line;
        }
    }' | sed -e 's/#[^#]*$//' -e 's/<[^>]*>//g' > "$OUTPUT_FILE"

    echo "Output saved to $OUTPUT_FILE"
done
