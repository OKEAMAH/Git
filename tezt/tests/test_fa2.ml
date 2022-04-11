let hen_contract =
  {|
parameter (or
            (or
              (or
                (pair %balance_of (list %requests (pair (address %owner) (nat %token_id)))
                                  (contract %callback (list (pair
                                                              (pair %request (address %owner)
                                                                             (nat %token_id))
                                                              (nat %balance)))))
                (list %hDAO_batch (pair (nat %amount) (address %to_))))
              (or
                (pair %mint (pair (address %address) (nat %amount))
                            (pair (nat %token_id) (map %token_info string bytes)))
                (address %set_administrator)))
            (or
              (or (bool %set_pause)
                  (pair %token_metadata (list %token_ids nat)
                                        (lambda %handler
                                          (list (pair (nat %token_id) (map %token_info string bytes)))
                                          unit)))
              (or
                (list %transfer (pair (address %from_)
                                      (list %txs (pair (address %to_)
                                                       (pair (nat %token_id) (nat %amount))))))
                (list %update_operators (or
                                         (pair %add_operator (address %owner)
                                                             (pair (address %operator)
                                                                   (nat %token_id)))
                                         (pair %remove_operator (address %owner)
                                                                (pair (address %operator)
                                                                      (nat %token_id))))))));
storage (pair
          (pair (address %administrator)
                (pair (nat %all_tokens) (big_map %ledger (pair address nat) nat)))
          (pair
            (pair (big_map %metadata string bytes)
                  (big_map %operators
                    (pair (address %owner) (pair (address %operator) (nat %token_id)))
                    unit))
            (pair (bool %paused)
                  (big_map %token_metadata nat (pair (nat %token_id) (map %token_info string bytes))))));
code { DUP ;
       CDR ;
       SWAP ;
       CAR ;
       IF_LEFT
         { IF_LEFT
             { IF_LEFT
                 { SWAP ;
                   DUP ;
                   DUG 2 ;
                   CDR ;
                   CDR ;
                   CAR ;
                   IF { PUSH int 722 ; FAILWITH } {} ;
                   DUP ;
                   CAR ;
                   MAP { DIG 2 ;
                         DUP ;
                         DUG 3 ;
                         CDR ;
                         CDR ;
                         CDR ;
                         SWAP ;
                         DUP ;
                         DUG 2 ;
                         CDR ;
                         MEM ;
                         IF {} { PUSH string "FA2_TOKEN_UNDEFINED" ; FAILWITH } ;
                         DIG 2 ;
                         DUP ;
                         DUG 3 ;
                         CAR ;
                         CDR ;
                         CDR ;
                         SWAP ;
                         DUP ;
                         CDR ;
                         SWAP ;
                         DUP ;
                         DUG 3 ;
                         CAR ;
                         PAIR ;
                         MEM ;
                         IF
                           { DIG 2 ;
                             DUP ;
                             DUG 3 ;
                             CAR ;
                             CDR ;
                             CDR ;
                             SWAP ;
                             DUP ;
                             CDR ;
                             SWAP ;
                             DUP ;
                             DUG 3 ;
                             CAR ;
                             PAIR ;
                             GET ;
                             IF_NONE { PUSH int 729 ; FAILWITH } {} ;
                             SWAP ;
                             PAIR %request %balance }
                           { PUSH nat 0 ; SWAP ; PAIR %request %balance } } ;
                   NIL operation ;
                   DIG 2 ;
                   CDR ;
                   PUSH mutez 0 ;
                   DIG 3 ;
                   TRANSFER_TOKENS ;
                   CONS }
                 { SWAP ;
                   DUP ;
                   DUG 2 ;
                   CAR ;
                   CAR ;
                   SENDER ;
                   COMPARE ;
                   EQ ;
                   IF {} { PUSH int 776 ; FAILWITH } ;
                   DUP ;
                   ITER { DIG 2 ;
                          DUP ;
                          DUG 3 ;
                          CAR ;
                          CDR ;
                          CDR ;
                          PUSH nat 0 ;
                          DIG 2 ;
                          DUP ;
                          DUG 3 ;
                          CDR ;
                          PAIR ;
                          MEM ;
                          IF
                            { DIG 2 ;
                              DUP ;
                              DUG 3 ;
                              DUP ;
                              CDR ;
                              SWAP ;
                              CAR ;
                              DUP ;
                              CAR ;
                              SWAP ;
                              CDR ;
                              DUP ;
                              CAR ;
                              SWAP ;
                              CDR ;
                              DUP ;
                              PUSH nat 0 ;
                              DIG 6 ;
                              DUP ;
                              DUG 7 ;
                              CDR ;
                              PAIR ;
                              DUP ;
                              DUG 2 ;
                              GET ;
                              IF_NONE { PUSH int 781 ; FAILWITH } { DROP } ;
                              DIG 5 ;
                              DUP ;
                              DUG 6 ;
                              CAR ;
                              DIG 8 ;
                              CAR ;
                              CDR ;
                              CDR ;
                              PUSH nat 0 ;
                              DIG 8 ;
                              CDR ;
                              PAIR ;
                              GET ;
                              IF_NONE { PUSH int 781 ; FAILWITH } {} ;
                              ADD ;
                              SOME ;
                              SWAP ;
                              UPDATE ;
                              SWAP ;
                              PAIR ;
                              SWAP ;
                              PAIR ;
                              PAIR ;
                              SWAP }
                            { DIG 2 ;
                              DUP ;
                              CDR ;
                              SWAP ;
                              CAR ;
                              DUP ;
                              CAR ;
                              SWAP ;
                              CDR ;
                              DUP ;
                              CAR ;
                              SWAP ;
                              CDR ;
                              DIG 4 ;
                              DUP ;
                              DUG 5 ;
                              CAR ;
                              SOME ;
                              PUSH nat 0 ;
                              DIG 6 ;
                              CDR ;
                              PAIR ;
                              UPDATE ;
                              SWAP ;
                              PAIR ;
                              SWAP ;
                              PAIR ;
                              PAIR ;
                              SWAP } ;
                          SWAP ;
                          DUP ;
                          DUG 2 ;
                          CDR ;
                          CDR ;
                          CDR ;
                          PUSH nat 0 ;
                          MEM ;
                          IF
                            {}
                            { SWAP ;
                              DUP ;
                              CAR ;
                              SWAP ;
                              CDR ;
                              DUP ;
                              CAR ;
                              SWAP ;
                              CDR ;
                              DUP ;
                              CAR ;
                              SWAP ;
                              CDR ;
                              EMPTY_MAP string bytes ;
                              PUSH string "ipfs://QmSVsfwH8es7Ur2eqto9hVpcd2dfWASmEaNxTPpcymuJzg" ;
                              PACK ;
                              SOME ;
                              PUSH string "" ;
                              UPDATE ;
                              PUSH nat 0 ;
                              PAIR %token_id %token_info ;
                              SOME ;
                              PUSH nat 0 ;
                              UPDATE ;
                              SWAP ;
                              PAIR ;
                              SWAP ;
                              PAIR ;
                              SWAP ;
                              PAIR ;
                              SWAP } } ;
                   DROP ;
                   NIL operation } }
             { IF_LEFT
                 { SWAP ;
                   DUP ;
                   DUG 2 ;
                   CAR ;
                   CAR ;
                   SENDER ;
                   COMPARE ;
                   EQ ;
                   IF {} { PUSH int 820 ; FAILWITH } ;
                   SWAP ;
                   DUP ;
                   DUG 2 ;
                   DUP ;
                   CDR ;
                   SWAP ;
                   CAR ;
                   DUP ;
                   CAR ;
                   SWAP ;
                   CDR ;
                   CDR ;
                   DIG 4 ;
                   CAR ;
                   CDR ;
                   CAR ;
                   DUP ;
                   PUSH nat 1 ;
                   DIG 6 ;
                   DUP ;
                   DUG 7 ;
                   CDR ;
                   CAR ;
                   ADD ;
                   DUP ;
                   DUG 2 ;
                   COMPARE ;
                   LE ;
                   IF { DROP } { SWAP ; DROP } ;
                   PAIR ;
                   SWAP ;
                   PAIR ;
                   PAIR ;
                   DUP ;
                   DUG 2 ;
                   CAR ;
                   CDR ;
                   CDR ;
                   SWAP ;
                   DUP ;
                   CDR ;
                   CAR ;
                   SWAP ;
                   DUP ;
                   DUG 3 ;
                   CAR ;
                   CAR ;
                   PAIR ;
                   MEM ;
                   IF
                     { SWAP ;
                       DUP ;
                       DUG 2 ;
                       DUP ;
                       CDR ;
                       SWAP ;
                       CAR ;
                       DUP ;
                       CAR ;
                       SWAP ;
                       CDR ;
                       DUP ;
                       CAR ;
                       SWAP ;
                       CDR ;
                       DUP ;
                       DIG 5 ;
                       DUP ;
                       CDR ;
                       CAR ;
                       SWAP ;
                       DUP ;
                       DUG 7 ;
                       CAR ;
                       CAR ;
                       PAIR ;
                       DUP ;
                       DUG 2 ;
                       GET ;
                       IF_NONE { PUSH int 832 ; FAILWITH } { DROP } ;
                       DIG 5 ;
                       DUP ;
                       DUG 6 ;
                       CAR ;
                       CDR ;
                       DIG 7 ;
                       CAR ;
                       CDR ;
                       CDR ;
                       DIG 7 ;
                       DUP ;
                       CDR ;
                       CAR ;
                       SWAP ;
                       DUP ;
                       DUG 9 ;
                       CAR ;
                       CAR ;
                       PAIR ;
                       GET ;
                       IF_NONE { PUSH int 832 ; FAILWITH } {} ;
                       ADD ;
                       SOME ;
                       SWAP ;
                       UPDATE ;
                       SWAP ;
                       PAIR ;
                       SWAP ;
                       PAIR ;
                       PAIR ;
                       SWAP }
                     { SWAP ;
                       DUP ;
                       CDR ;
                       SWAP ;
                       CAR ;
                       DUP ;
                       CAR ;
                       SWAP ;
                       CDR ;
                       DUP ;
                       CAR ;
                       SWAP ;
                       CDR ;
                       DIG 4 ;
                       DUP ;
                       DUG 5 ;
                       CAR ;
                       CDR ;
                       SOME ;
                       DIG 5 ;
                       DUP ;
                       CDR ;
                       CAR ;
                       SWAP ;
                       DUP ;
                       DUG 7 ;
                       CAR ;
                       CAR ;
                       PAIR ;
                       UPDATE ;
                       SWAP ;
                       PAIR ;
                       SWAP ;
                       PAIR ;
                       PAIR ;
                       SWAP } ;
                   SWAP ;
                   DUP ;
                   DUG 2 ;
                   CDR ;
                   CDR ;
                   CDR ;
                   SWAP ;
                   DUP ;
                   DUG 2 ;
                   CDR ;
                   CAR ;
                   MEM ;
                   IF
                     { DROP }
                     { SWAP ;
                       DUP ;
                       CAR ;
                       SWAP ;
                       CDR ;
                       DUP ;
                       CAR ;
                       SWAP ;
                       CDR ;
                       DUP ;
                       CAR ;
                       SWAP ;
                       CDR ;
                       DIG 4 ;
                       DUP ;
                       CDR ;
                       CDR ;
                       SWAP ;
                       DUP ;
                       DUG 6 ;
                       CDR ;
                       CAR ;
                       PAIR %token_id %token_info ;
                       SOME ;
                       DIG 5 ;
                       CDR ;
                       CAR ;
                       UPDATE ;
                       SWAP ;
                       PAIR ;
                       SWAP ;
                       PAIR ;
                       SWAP ;
                       PAIR } }
                 { SWAP ;
                   DUP ;
                   DUG 2 ;
                   CAR ;
                   CAR ;
                   SENDER ;
                   COMPARE ;
                   EQ ;
                   IF {} { PUSH int 805 ; FAILWITH } ;
                   SWAP ;
                   DUP ;
                   CDR ;
                   SWAP ;
                   CAR ;
                   CDR ;
                   DIG 2 ;
                   PAIR ;
                   PAIR } ;
               NIL operation } }
         { IF_LEFT
             { IF_LEFT
                 { SWAP ;
                   DUP ;
                   DUG 2 ;
                   CAR ;
                   CAR ;
                   SENDER ;
                   COMPARE ;
                   EQ ;
                   IF {} { PUSH int 814 ; FAILWITH } ;
                   SWAP ;
                   DUP ;
                   CAR ;
                   SWAP ;
                   CDR ;
                   DUP ;
                   CAR ;
                   SWAP ;
                   CDR ;
                   CDR ;
                   DIG 3 ;
                   PAIR ;
                   SWAP ;
                   PAIR ;
                   SWAP ;
                   PAIR }
                 { SWAP ;
                   DUP ;
                   DUG 2 ;
                   CDR ;
                   CDR ;
                   CAR ;
                   IF { PUSH int 855 ; FAILWITH } {} ;
                   DUP ;
                   CDR ;
                   SWAP ;
                   DUP ;
                   DUG 2 ;
                   CAR ;
                   MAP { DIG 3 ; DUP ; DUG 4 ; CDR ; CDR ; CDR ; SWAP ; GET ; IF_NONE { PUSH int 865 ; FAILWITH } {} } ;
                   DIG 2 ;
                   DROP ;
                   EXEC ;
                   DROP } }
             { IF_LEFT
                 { SWAP ;
                   DUP ;
                   DUG 2 ;
                   CDR ;
                   CDR ;
                   CAR ;
                   IF { PUSH int 679 ; FAILWITH } {} ;
                   DUP ;
                   ITER { DUP ;
                          CDR ;
                          ITER { DIG 3 ;
                                 DUP ;
                                 DUG 4 ;
                                 CAR ;
                                 CAR ;
                                 SENDER ;
                                 COMPARE ;
                                 EQ ;
                                 IF
                                   { PUSH bool True }
                                   { SENDER ; DIG 2 ; DUP ; DUG 3 ; CAR ; COMPARE ; EQ } ;
                                 IF
                                   { PUSH bool True }
                                   { DIG 3 ;
                                     DUP ;
                                     DUG 4 ;
                                     CDR ;
                                     CAR ;
                                     CDR ;
                                     SWAP ;
                                     DUP ;
                                     DUG 2 ;
                                     CDR ;
                                     CAR ;
                                     SENDER ;
                                     PAIR %operator %token_id ;
                                     DIG 3 ;
                                     DUP ;
                                     DUG 4 ;
                                     CAR ;
                                     PAIR %owner ;
                                     MEM } ;
                                 IF {} { PUSH string "FA2_NOT_OPERATOR" ; FAILWITH } ;
                                 DIG 3 ;
                                 DUP ;
                                 DUG 4 ;
                                 CDR ;
                                 CDR ;
                                 CDR ;
                                 SWAP ;
                                 DUP ;
                                 DUG 2 ;
                                 CDR ;
                                 CAR ;
                                 MEM ;
                                 IF {} { PUSH string "FA2_TOKEN_UNDEFINED" ; FAILWITH } ;
                                 DUP ;
                                 CDR ;
                                 CDR ;
                                 PUSH nat 0 ;
                                 COMPARE ;
                                 LT ;
                                 IF
                                   { DUP ;
                                     CDR ;
                                     CDR ;
                                     DIG 4 ;
                                     DUP ;
                                     DUG 5 ;
                                     CAR ;
                                     CDR ;
                                     CDR ;
                                     DIG 2 ;
                                     DUP ;
                                     DUG 3 ;
                                     CDR ;
                                     CAR ;
                                     DIG 4 ;
                                     DUP ;
                                     DUG 5 ;
                                     CAR ;
                                     PAIR ;
                                     GET ;
                                     IF_NONE { PUSH int 706 ; FAILWITH } {} ;
                                     COMPARE ;
                                     GE ;
                                     IF {} { PUSH string "FA2_INSUFFICIENT_BALANCE" ; FAILWITH } ;
                                     DIG 3 ;
                                     DUP ;
                                     DUG 4 ;
                                     DUP ;
                                     CDR ;
                                     SWAP ;
                                     CAR ;
                                     DUP ;
                                     CAR ;
                                     SWAP ;
                                     CDR ;
                                     DUP ;
                                     CAR ;
                                     SWAP ;
                                     CDR ;
                                     DUP ;
                                     DIG 5 ;
                                     DUP ;
                                     DUG 6 ;
                                     CDR ;
                                     CAR ;
                                     DIG 7 ;
                                     DUP ;
                                     DUG 8 ;
                                     CAR ;
                                     PAIR ;
                                     DUP ;
                                     DUG 2 ;
                                     GET ;
                                     IF_NONE { PUSH int 710 ; FAILWITH } { DROP } ;
                                     DIG 5 ;
                                     DUP ;
                                     DUG 6 ;
                                     CDR ;
                                     CDR ;
                                     DIG 9 ;
                                     CAR ;
                                     CDR ;
                                     CDR ;
                                     DIG 7 ;
                                     DUP ;
                                     DUG 8 ;
                                     CDR ;
                                     CAR ;
                                     DIG 9 ;
                                     DUP ;
                                     DUG 10 ;
                                     CAR ;
                                     PAIR ;
                                     GET ;
                                     IF_NONE { PUSH int 710 ; FAILWITH } {} ;
                                     SUB ;
                                     ISNAT ;
                                     IF_NONE { PUSH int 710 ; FAILWITH } {} ;
                                     SOME ;
                                     SWAP ;
                                     UPDATE ;
                                     SWAP ;
                                     PAIR ;
                                     SWAP ;
                                     PAIR ;
                                     PAIR ;
                                     DUP ;
                                     DUG 4 ;
                                     CAR ;
                                     CDR ;
                                     CDR ;
                                     SWAP ;
                                     DUP ;
                                     CDR ;
                                     CAR ;
                                     SWAP ;
                                     DUP ;
                                     DUG 3 ;
                                     CAR ;
                                     PAIR ;
                                     MEM ;
                                     IF
                                       { DIG 3 ;
                                         DUP ;
                                         DUG 4 ;
                                         DUP ;
                                         CDR ;
                                         SWAP ;
                                         CAR ;
                                         DUP ;
                                         CAR ;
                                         SWAP ;
                                         CDR ;
                                         DUP ;
                                         CAR ;
                                         SWAP ;
                                         CDR ;
                                         DUP ;
                                         DIG 5 ;
                                         DUP ;
                                         CDR ;
                                         CAR ;
                                         SWAP ;
                                         DUP ;
                                         DUG 7 ;
                                         CAR ;
                                         PAIR ;
                                         DUP ;
                                         DUG 2 ;
                                         GET ;
                                         IF_NONE { PUSH int 713 ; FAILWITH } { DROP } ;
                                         DIG 5 ;
                                         DUP ;
                                         DUG 6 ;
                                         CDR ;
                                         CDR ;
                                         DIG 9 ;
                                         CAR ;
                                         CDR ;
                                         CDR ;
                                         DIG 7 ;
                                         DUP ;
                                         CDR ;
                                         CAR ;
                                         SWAP ;
                                         CAR ;
                                         PAIR ;
                                         GET ;
                                         IF_NONE { PUSH int 713 ; FAILWITH } {} ;
                                         ADD ;
                                         SOME ;
                                         SWAP ;
                                         UPDATE ;
                                         SWAP ;
                                         PAIR ;
                                         SWAP ;
                                         PAIR ;
                                         PAIR ;
                                         DUG 2 }
                                       { DIG 3 ;
                                         DUP ;
                                         CDR ;
                                         SWAP ;
                                         CAR ;
                                         DUP ;
                                         CAR ;
                                         SWAP ;
                                         CDR ;
                                         DUP ;
                                         CAR ;
                                         SWAP ;
                                         CDR ;
                                         DIG 4 ;
                                         DUP ;
                                         DUG 5 ;
                                         CDR ;
                                         CDR ;
                                         SOME ;
                                         DIG 5 ;
                                         DUP ;
                                         CDR ;
                                         CAR ;
                                         SWAP ;
                                         CAR ;
                                         PAIR ;
                                         UPDATE ;
                                         SWAP ;
                                         PAIR ;
                                         SWAP ;
                                         PAIR ;
                                         PAIR ;
                                         DUG 2 } }
                                   { DROP } } ;
                          DROP } ;
                   DROP }
                 { DUP ;
                   ITER { IF_LEFT
                            { DUP ;
                              CAR ;
                              SENDER ;
                              COMPARE ;
                              EQ ;
                              IF
                                { PUSH bool True }
                                { DIG 2 ; DUP ; DUG 3 ; CAR ; CAR ; SENDER ; COMPARE ; EQ } ;
                              IF {} { PUSH int 758 ; FAILWITH } ;
                              DIG 2 ;
                              DUP ;
                              CAR ;
                              SWAP ;
                              CDR ;
                              DUP ;
                              CDR ;
                              SWAP ;
                              CAR ;
                              DUP ;
                              CAR ;
                              SWAP ;
                              CDR ;
                              PUSH (option unit) (Some Unit) ;
                              DIG 5 ;
                              DUP ;
                              CDR ;
                              CDR ;
                              SWAP ;
                              DUP ;
                              DUG 7 ;
                              CDR ;
                              CAR ;
                              PAIR %operator %token_id ;
                              DIG 6 ;
                              CAR ;
                              PAIR %owner ;
                              UPDATE ;
                              SWAP ;
                              PAIR ;
                              PAIR ;
                              SWAP ;
                              PAIR ;
                              SWAP }
                            { DUP ;
                              CAR ;
                              SENDER ;
                              COMPARE ;
                              EQ ;
                              IF
                                { PUSH bool True }
                                { DIG 2 ; DUP ; DUG 3 ; CAR ; CAR ; SENDER ; COMPARE ; EQ } ;
                              IF {} { PUSH int 765 ; FAILWITH } ;
                              DIG 2 ;
                              DUP ;
                              CAR ;
                              SWAP ;
                              CDR ;
                              DUP ;
                              CDR ;
                              SWAP ;
                              CAR ;
                              DUP ;
                              CAR ;
                              SWAP ;
                              CDR ;
                              NONE unit ;
                              DIG 5 ;
                              DUP ;
                              CDR ;
                              CDR ;
                              SWAP ;
                              DUP ;
                              DUG 7 ;
                              CDR ;
                              CAR ;
                              PAIR %operator %token_id ;
                              DIG 6 ;
                              CAR ;
                              PAIR %owner ;
                              UPDATE ;
                              SWAP ;
                              PAIR ;
                              PAIR ;
                              SWAP ;
                              PAIR ;
                              SWAP } } ;
                   DROP } } ;
           NIL operation } ;
       PAIR }
|}

let mini_contract = 
  {|
parameter address;
storage (pair address (big_map nat nat));
code {
        UNPAIR ;
        SWAP ;
        UNPAIR ;
        SENDER ;
        COMPARE ;
        EQ ;
        IF {} { PUSH int 8; FAILWITH } ;
        SWAP;
        PAIR;
        NIL operation ;
        PAIR }
|}                         

let hen_test_sto = {|{{"tz1f1S7V2hZJ3mhj47djb5j1saek8c2yB2Cx"; {709141; {}}}; {{{}; {}}; {False; {Elt 0 {0;{}}}}}}|}

let test_mockup ~protocol () =
  let* client = Client.init_mockup ~protocol () in
  let* bootstrap1 = Client.show_address ~alias:"bootstrap1" client in
  (* let* bootstrap2 = Client.show_address ~alias:"bootstrap2" client in *)
  Format.printf "TEST MOCKUP\n";
  let* storage =
    Client.run_script
      ~source:{|tz1f1S7V2hZJ3mhj47djb5j1saek8c2yB2Cx|}
      ~prg:hen_contract
      ~storage:hen_test_sto
      ~input:(Format.sprintf {|(Left (Right (Right %S)))|} bootstrap1.public_key_hash)
      client
  in
  Format.printf "STO: %s\n" storage;
  unit


let test_bake ~protocol () =
  let* (node, client) = Client.init_with_protocol `Client ~protocol () in
  let data_dir = Node.data_dir node in

  
  Format.printf "STO: %s\n" (Format.sprintf "Pair %S {}" Constant.bootstrap1.public_key_hash);
  let storage = (Format.sprintf "Pair %S {}" Constant.bootstrap1.public_key_hash) in

  let wait_injection = Node.wait_for_request ~request:`Inject node in
  let* contract_hash =
    Client.originate_contract
      ~init:storage
      ~alias:"minicontract"
      ~amount:Tez.zero
      ~src:"bootstrap1"
      ~prg:mini_contract
      ~burn_cap:Tez.one
      client
  in
  let* () = wait_injection in
  let* () = Client.bake_for ~context_path:(data_dir // "context") client in
  let* storage = Client.contract_storage "minicontract" client
  in
  Format.printf "TEST BAKE\n";
  Format.printf "STO: %s\n" storage;

  let wait_injection = Node.wait_for_request ~request:`Inject node in
  let* (`OpHash _todo) =
    Operation.inject_contract_call
      ~amount:0
      ~source:Constant.bootstrap1
      ~dest:contract_hash
      ~entrypoint:""
      ~arg:(`Michelson (Format.sprintf "%S" Constant.bootstrap2.public_key_hash))
      client
  in
  let* () = wait_injection in
  let* () = Client.bake_for ~context_path:(data_dir // "context") client in

  let* storage = Client.contract_storage "minicontract" client
  in

  Format.printf "STO: %s\n" storage;



  let wait_injection = Node.wait_for_request ~request:`Inject node in
  let* (`OpHash _todo) =
    Operation.inject_contract_call
      ~amount:0
      ~source:Constant.bootstrap2
      ~dest:contract_hash
      ~entrypoint:""
      ~arg:(`Michelson (Format.sprintf "%S" Constant.bootstrap3.public_key_hash))
      client
  in
  let* () = wait_injection in
  let* () = Client.bake_for ~context_path:(data_dir // "context") client in

  let* storage = Client.contract_storage "minicontract" client
  in

  Format.printf "STO: %s\n" storage;

  unit

let make_for ~protocol () =
  List.iter
    (fun (title, f) ->
      Test.register ~__FILE__ ~title ~tags:["test_test"] f)
    [
      ( "test_bake",
      test_bake ~protocol );
      (* ("Run script with source and sender", test_source_and_sender ~protocol); *)
      ( "test_mockup",
      test_mockup ~protocol );
    ]

let register ~protocols =
  List.iter
    (function
      | Protocol.Alpha as protocol -> make_for ~protocol ()
      | Protocol.Hangzhou | Protocol.Ithaca -> ())
    (* Won't work prior to protocol J. *)
    protocols
    