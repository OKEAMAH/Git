
case $1 in

  compute)
    echo
    (dune exec tezt/tests/main.exe -- --verbose --file sc_rollup.ml --title="Alpha: wasm_2_0_0 - node advances PVM state with messages")
    ;;
  commit)
    echo
    (dune exec tezt/tests/main.exe -- --file sc_rollup.ml --title="Alpha: wasm_2_0_0 - rollup node - correct handling of commitments (operator_publishes)")
    ;;

  *)
    echo -n "scoru-test: unknown command"
    echo
    ;;
esac



