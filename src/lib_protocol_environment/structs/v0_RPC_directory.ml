include Tezos_rpc.RPC_directory

let merge : 'a directory -> 'a directory -> 'a directory =
 fun d1 d2 -> merge ?strategy:None d1 d2
