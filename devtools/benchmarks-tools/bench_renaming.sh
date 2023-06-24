#!/bin/bash

# This is adapted from watch_regressions.sh.

# Parameters
# * INPUT_CSV_DIR is exported. Set it when launching the script if you already
#   have a copy of the CSVs (this avoids re-downloading them).
# * Substitutions must be in a file provided as the first parameter, in the
#   format:
#   new_name,old_name
#   one per line. No file means no substitution.
# * The script expects an access to the AWS storage with benchmark results.

# Run:
#   devtools/benchmarks-tools/bench_renaming.sh <file-with-renamings>
# from the root of the repository.
# There is a renaming file example in devtools/benchmarks-tools/renamings.

export INPUT_CSV_DIR
if [ "$INPUT_CSV_DIR" = "" ]
then
    INPUT_CSV_DIR="$(mktemp -d)"
    aws s3 sync s3://snoop-playground/mclaren/inference_csvs/snoop_results/ "$INPUT_CSV_DIR"/
fi

OUTPUT_CSV_DIR="$(mktemp -d)"
echo "Results will be saved to $OUTPUT_CSV_DIR."


CSVS="$INPUT_CSV_DIR"/*/*.csv

if [ ! -z "$1" ]
then
    while read line; do sed -i "s,$line,g" $CSVS; done < $1
fi

ALERT_FILE="$OUTPUT_CSV_DIR/alerts"
SELECTION_FILE="$OUTPUT_CSV_DIR/selected.csv"

LAST_DIR="$(ls "$INPUT_CSV_DIR" | tail -n 1)"
LAST_KNOWN_DIR="$(ls "$INPUT_CSV_DIR" | tail -n 2 | head -n 1)"

FIRST_DIR=_snoop_20230316_1052_v16.0-rc1-1722-g1f07d32f94

DIRS=""
for d in "$INPUT_CSV_DIR"/*
do
    d=$(basename "$d")
    if [[ "$d" > "$FIRST_DIR" || "$d" == "$FIRST_DIR" ]]
    then
        if [ -z "$DIRS" ]
        then
            DIRS="$d"
        else
            DIRS="$DIRS $d"
        fi
    fi
done

REF_DIR=_snoop_00_reference_values
DIRS="$DIRS $REF_DIR"

GPD_DIR="devtools/gas_parameter_diff"

cd "$GPD_DIR" || exit 1

dune exec gas_parameter_diff -- &> /dev/null

PREV_DIR="$LAST_KNOWN_DIR"

for f in "$INPUT_CSV_DIR/$LAST_DIR"/*
do
    b="$(basename "$f")"

    files=$(for d in $DIRS; do local="$INPUT_CSV_DIR/$d/$b"; if [ -f "$local" ]; then echo "$local"; fi; done)

    dune exec --no-build gas_parameter_diff -- ${files:+$files} > "$OUTPUT_CSV_DIR"/all_"$b" 2> /dev/null

    # Comparing with the reference and previous runs.
    for current in reference previous
    do
        CURRENT_DIR=""
        if [ "$current" = "reference" ]
        then
            CURRENT_DIR="$REF_DIR"
        else
            CURRENT_DIR="$PREV_DIR"
        fi

        dune exec --no-build --no-print-directory gas_parameter_diff -- "$INPUT_CSV_DIR"/"$CURRENT_DIR"/"$b" "$INPUT_CSV_DIR"/"$LAST_DIR"/"$b" > "$OUTPUT_CSV_DIR"/"$current"_"$b" 2> tmp
        grep -v "score\|T-value" tmp > tmp2
        if [ -s tmp2 ]
        then
            {
                echo
                echo "--------------------------------"
                echo "Warning while comparing $b between $LAST_DIR and the $current version $CURRENT_DIR"
                cat tmp2
            } >> "$ALERT_FILE"
            # Save the parameters with alerts in a file. They are in the lines
            # with a '%'.
            grep "%" tmp2 | sed 's/\.//g' | cut -d ' ' -f 4  >> tmp_selection
        fi
        rm -f tmp tmp2
    done

    if [ -s tmp_selection ]
    then
        head -n 1 "$OUTPUT_CSV_DIR"/all_"$b" >> "$SELECTION_FILE"
        for p in $(sort tmp_selection | uniq)
        do
            grep "^$p," "$OUTPUT_CSV_DIR"/all_"$b" >> "$SELECTION_FILE"
        done
    fi
    rm -f tmp_selection
done

cat "$OUTPUT_CSV_DIR"/all_*.csv > "$OUTPUT_CSV_DIR"/all.csv
cat "$OUTPUT_CSV_DIR"/reference_*.csv > "$OUTPUT_CSV_DIR"/reference.csv
cat "$OUTPUT_CSV_DIR"/previous_*.csv > "$OUTPUT_CSV_DIR"/previous.csv
