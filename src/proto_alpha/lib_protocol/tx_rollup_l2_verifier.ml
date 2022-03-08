module Verifier_storage :
  Tx_rollup_l2_storage_sig.STORAGE
    with type t = Context.tree
     and type 'a m = ('a, error) result Lwt.t = struct
  type t = Context.tree

  type 'a m = ('a, error) result Lwt.t

  module Syntax = struct
    let ( let* ) = ( >>=? )

    let ( let+ ) = ( >|=? )

    let return = return

    let fail e = Lwt.return (Error e)

    let catch (m : 'a m) k h = m >>= function Ok x -> k x | Error e -> h e

    let list_fold_left_m = List.fold_left_es
  end

  let path k = [Bytes.to_string k]

  let get store key = Context.Tree.find store (path key) >>= return

  let set store key value = Context.Tree.add store (path key) value >>= return

  let remove store key = Context.Tree.remove store (path key) >>= return
end

module Verifier_context = Tx_rollup_l2_context.Make (Verifier_storage)
module Verifier_apply = Tx_rollup_l2_apply.Make (Verifier_context)

let verify_message message expected_before expected_after proof =
  Context.verify_stream_proof proof (fun tree ->
      let before = Context.Tree.hash tree in
      assert (Context_hash.(before = expected_before)) ;
      (Verifier_apply.apply_message tree message >>= function
       | Ok (tree, message_result) -> Lwt.return (tree, Some message_result)
       | Error e ->
           Logging.(
             log Info "Got error: %a\n" pp_trace (Error_monad.trace_of_error e)) ;

           Lwt.return (tree, None))
      >>= fun (tree, message_result) ->
      let after = Context.Tree.hash tree in
      Lwt.return (tree, (after, message_result)))
  >>= function
  | Ok (_, (after, message_result)) ->
      let withdraw =
        match message_result with
        | Some (_message_result, withdrawals) ->
            Alpha_context.Tx_rollup_withdraw.hash_list withdrawals
        | None -> Alpha_context.Tx_rollup_withdraw.hash_list []
      in
      let result =
        Alpha_context.Tx_rollup_commitment.batch_commitment
          (Context_hash.to_bytes after)
          withdraw
      in
      fail_unless
        Alpha_context.Tx_rollup_commitment_message_result_hash.(
          equal expected_after result)
        Alpha_context.Tx_rollup_errors.Invalid_proof
      >>=? fun () -> return result
  | Error _ ->
      fail
        (Alpha_context.Tx_rollup_errors.Internal_error
           "Something went wrong while verifying a proof")
