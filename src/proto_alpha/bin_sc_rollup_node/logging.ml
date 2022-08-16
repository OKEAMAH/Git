let append : filename:string -> string -> unit Lwt.t =
 fun ~filename data ->
  let oc = open_out_gen [Open_creat; Open_text; Open_append] 0o640 filename in
  output_string oc data ;
  close_out oc ;
  Lwt.return ()

(* Example:
   let* () = Logging.append (Printf.sprintf "Feeding input: %d\n" 0) in
*)
let append : string -> unit Lwt.t =
 fun str -> append ~filename:"scoru-node-debug-log.txt" str

let append_result : string -> (unit, 'e) result Lwt.t =
 fun str ->
  let open Lwt_syntax in
  let* () = append str in
  return (Ok ())
