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

let get_balance_callback = 
  {|
parameter (list (pair
                  (pair %request (address %owner)
                                 (nat %token_id))
                  (nat %balance)));
storage   (list (pair
                  (pair %request (address %owner)
                                 (nat %token_id))
                  (nat %balance)));
code  { CAR;
        NIL operation;
        PAIR
      }
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

let fail_contract = 
  {|
parameter unit;
storage unit;
code { PUSH string "TESTERROR" ; FAILWITH }
|}

let hen_test_sto = Format.sprintf "{{%S; {709141; {Elt {%S;0} 100}}}; {{{}; {}}; {False; {Elt 0 {0;{}}}}}}" Constant.bootstrap1.public_key_hash Constant.bootstrap2.public_key_hash

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
  let* storage =
  Client.run_script
    ~source:{|tz1f1S7V2hZJ3mhj47djb5j1saek8c2yB2Cx|}
    ~prg:hen_contract
    ~storage:hen_test_sto
    ~input:(Format.sprintf {|%S|} bootstrap1.public_key_hash)
    ~entrypoint:"set_administrator"
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
      ~dest:"minicontract"
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



let test_fail ~protocol () =
  let* (node, client) = Client.init_with_protocol `Client ~protocol () in
  let data_dir = Node.data_dir node in

  let wait_injection = Node.wait_for_request ~request:`Inject node in
  let* contract_hash =
    Client.originate_contract
      ~init:"Unit"
      ~alias:"failcontract"
      ~amount:Tez.zero
      ~src:"bootstrap1"
      ~prg:fail_contract
      ~burn_cap:Tez.one
      client
  in
  let* () = wait_injection in
  let* () = Client.bake_for ~context_path:(data_dir // "context") client in

  Format.printf "TEST FAIL\n";

  (* let wait_injection = Node.wait_for_request ~request:`Inject node in *)
  let process =
  Client.spawn_transfer
    ~arg:"Unit"
    ~amount:Tez.zero
    ~giver:"bootstrap1"
    ~receiver:contract_hash
    client
  in
  let* std_err =
    Process.wait_and_read_stderr process
  in


  Format.printf "ERROR: &&&%s&&&\n" std_err;

  unit

let print_balances ~client ~contract_hash ~callback_hash  =
  let process =
    Client.spawn_transfer
      ~entrypoint:"balance_of"
      ~arg:(Format.sprintf "{{{%S; 0}; {%S; 0}}; %S}" Constant.bootstrap2.public_key_hash Constant.bootstrap3.public_key_hash callback_hash)
      ~amount:Tez.zero
      ~giver:"bootstrap2"
      ~receiver:contract_hash
      ~burn_cap:(Tez.of_int 10)
      client
  in
  let* () = Process.check process in
  let* balances = Client.contract_storage "callback" client
  in
  Format.printf "balances: %s\n" balances;
  unit

let json_micheline_to_pair json =
  let arg_list = JSON.(json |-> "args" |> as_list) in 
  match arg_list with 
  | [a1;a2] -> (a1,a2)
  | _ -> raise @@ Invalid_argument "expected a pair"

let json_micheline_to_int json = 
  JSON.(json |-> "int" |> as_int)

let json_micheline_to_string json = 
  JSON.(json |-> "string" |> as_string)

let get_balances ~client ~callback_hash =
  let process =
    Client.spawn_transfer
      ~entrypoint:"balance_of"
      ~arg:(Format.sprintf "{{{%S; 0}; {%S; 0}; {%S; 0}; {%S; 0}; {%S; 0}}; %S}" 
        Constant.bootstrap1.public_key_hash 
        Constant.bootstrap2.public_key_hash 
        Constant.bootstrap3.public_key_hash 
        Constant.bootstrap4.public_key_hash 
        Constant.bootstrap5.public_key_hash 
        callback_hash)
      ~amount:Tez.zero
      ~giver:"bootstrap2"
      ~receiver:"contract"
      ~burn_cap:(Tez.of_int 10)
      client
  in
  let* () = Process.check process in
  let* s = Client.contract_storage "callback" client in
  let* json = Client.convert_data_to_json ~data:s client in
  let json = JSON.annotate ~origin:"tezos-client convert data" json in
  Format.printf "json %s\n" @@ JSON.encode json;

  let json_list = JSON.as_list json in 
  let parse json =
    let pair, amount = json_micheline_to_pair json in 
    let account, token_id = json_micheline_to_pair pair in 
    ((json_micheline_to_string account, json_micheline_to_int token_id),
      json_micheline_to_int amount) in
  return @@ List.map parse json_list
  
let check_balances ~client ~callback_hash ~error_msg expected = 
  match expected with 
  | [b1; b2; b3; b4; b5] ->
      let* balances = get_balances ~client ~callback_hash in
      Check.((List.assoc (Constant.bootstrap1.public_key_hash, 0) balances = b1) int ~error_msg);
      Check.((List.assoc (Constant.bootstrap2.public_key_hash, 0) balances = b2) int ~error_msg);
      Check.((List.assoc (Constant.bootstrap3.public_key_hash, 0) balances = b3) int ~error_msg);
      Check.((List.assoc (Constant.bootstrap4.public_key_hash, 0) balances = b4) int ~error_msg);
      Check.((List.assoc (Constant.bootstrap5.public_key_hash, 0) balances = b5) int ~error_msg);
      unit
    

  | _ -> raise @@ Invalid_argument "expected a 5 element list"


  (* let json_micheline_to_int json = JSON.(json |-> "int" |> as_int) in
  let (parsed : int list) =
    JSON.(json |> as_list |> List.map json_micheline_to_int)
  in

  let balances_string = Option.get (balances_string =~* rex "{\\s*(.*)\\s*}") in 
  let balances_strings = String.split_on_char ';' balances_string in
  return @@ List.map 
    (fun s -> let (a,b,c) = Option.get (s =~*** (rex {|\\s*Pair \\(Pair "(\w+)" (\\d+)\\) (\\d+)\\s*|})) in ((a,b),c))
    balances_strings *)
  
(* let print_storage ~client =
  let* storage = Client.contract_storage "contract" client
  in
  Format.printf "TEST FA2\n";
  Format.printf "STO: %s\n" storage;
  unit *)

let check_entrypoint_type ~entrypoint ~client ~expected_type =
  let* output =
  Client.get_contract_entrypoint_type
    ~entrypoint
    ~contract:"contract"
    client
  in
  begin match output with 
  | None -> Format.printf "No %s entrypoint\n\n" entrypoint
  | Some typ -> 
    if typ = expected_type
      (* "(pair (list (pair address nat)) (contract (list (pair (pair address nat) nat))))" *)
    then 
      Format.printf "%s entrypoint has correct type\n\n" entrypoint
    else
      Format.printf "%s entrypoint has type\n%s\ninstead of\n%s\n\n" entrypoint typ expected_type
    end;
    unit

let test_fa2 ~protocol ~contract ~storage () =

  Format.printf "TEST FA2\n\n";

  let* client = Client.init_mockup ~protocol () in
  Format.printf "TEST FA2\n\n";

  let* contract_hash =
    Client.originate_contract
      ~init:storage
      ~alias:"contract"
      ~amount:Tez.zero
      ~src:"bootstrap1"
      ~prg:contract
      ~burn_cap:(Tez.of_int 10)
      client
  in
  Format.printf "Contract originated\n\n";

  let* callback_hash =
    Client.originate_contract
      ~init:"{}"
      ~alias:"callback"
      ~amount:Tez.zero
      ~src:"bootstrap1"
      ~prg:get_balance_callback
      ~burn_cap:(Tez.of_int 10)
      client
  in

  Format.printf "Callback originated\n\n";

  let* () = 
    check_entrypoint_type
      ~entrypoint:"balance_of"
      ~expected_type:"(pair (list (pair address nat)) (contract (list (pair (pair address nat) nat))))"
      ~client
  in
  let* () = 
  check_entrypoint_type
    ~entrypoint:"transfer"
    ~expected_type:"(list (pair address (list (pair address nat nat))))"
    ~client
  in
  let* () = 
  check_entrypoint_type
    ~entrypoint:"update_operators"
    ~expected_type:"(list (or (pair address address nat) (pair address address nat)))"
    ~client
  in
  
  let* () = print_balances ~client ~contract_hash ~callback_hash in

  let process =
    Client.spawn_transfer
      ~entrypoint:"transfer"
      ~arg:(Format.sprintf "{{%S; {{%S; 0; 100}}}}" Constant.bootstrap2.public_key_hash Constant.bootstrap3.public_key_hash)
      ~amount:Tez.zero
      ~giver:"bootstrap2"
      ~receiver:contract_hash
      ~burn_cap:(Tez.of_int 10)
      client
  in
  (* let* std_err =
    Process.check_and_read_stderr ~expect_failure:false process
  in *)
  let* () = Process.check process in

  Format.printf "Transferred 100 tokens from bootstrap 2 to bootstrap 3\n";

  let* () = check_balances [0;0;100;0;0] ~error_msg:"list of transfers in order" ~client ~callback_hash in

  let process =
    Client.spawn_transfer
      ~entrypoint:"transfer"
      ~arg:(Format.sprintf "{{%S; {{%S; 0; 100}}}; {%S; {{%S; 0; 100}}}; {%S; {{%S; 0; 100}}}}" 
        Constant.bootstrap3.public_key_hash Constant.bootstrap4.public_key_hash
        Constant.bootstrap4.public_key_hash Constant.bootstrap5.public_key_hash
        Constant.bootstrap5.public_key_hash Constant.bootstrap1.public_key_hash
      )
      ~amount:Tez.zero
      ~giver:"bootstrap1"
      ~receiver:contract_hash
      ~burn_cap:(Tez.of_int 10)
      client
  in
  (* let* std_err =
    Process.check_and_read_stderr ~expect_failure:false process
  in *)
  let* () = Process.check process in

  Format.printf "Transferred 100 tokens from bootstrap 3 to bootstrap 4 then 100 from bootstrap 4 to bootstrap 5 then 100 from bootstrap 5 to bootstrap 1\n";

  let* () = check_balances [100;0;0;0;0] ~error_msg:"list of transfers in order" ~client ~callback_hash in

  unit

let make_for ~protocol () =
  List.iter
    (fun (title, f) ->
      Test.register ~__FILE__ ~title ~tags:["test_test"] f)
    [
      (* ( "test_bake", test_bake ~protocol ); *)
      (* ( "test_mockup", test_mockup ~protocol ); *)
      ( "test_fa2", test_fa2 ~protocol ~contract:hen_contract ~storage:hen_test_sto);
      (* ( "test_fail", test_fail ~protocol); *)

    ]

let register ~protocols =
  List.iter
    (function
      | Protocol.Alpha as protocol -> make_for ~protocol ()
      | Protocol.Hangzhou | Protocol.Ithaca -> ())
    protocols
    