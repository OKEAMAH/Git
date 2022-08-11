
case $1 in

  compute)
    echo
    (make &&  dune exec tezt/tests/main.exe -- --file sc_rollup.ml --title="Alpha: wasm_2_0_0 - node advances PVM state with messages")
    ;;

  *)
    echo -n "scoru-test: unknown command"
    echo
    ;;
esac



