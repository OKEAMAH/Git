open Data_encoding

type 'a ret = (case_tag -> 'a case) list

type 'err err_ret = {tag : 'err; error : error}

type ('a, 'err) entry_result = Ok' of 'a | OkErr of 'err err_ret

let return_ok v = Lwt.return @@ Ok' v

let return_err v = Lwt.return @@ OkErr v

(* tag * id *)
type 'err errs = ('err * string) list

type 'ctx entry =
  | Entry : {
      input_enc : 'a encoding;
      output_enc : 'b encoding;
      desc : string;
      cases : 'err errs;
      f : 'a -> 'ictx -> ('b, 'err) entry_result Lwt.t;
      conv : 'ctx -> 'ictx;
      path : string;
    }
      -> 'ctx entry
  | EntryPassword : {
      input_enc : 'a encoding;
      output_enc : 'b encoding;
      desc : string;
      cases : 'err errs;
      f : 'a -> 'ictx -> ('b, 'err) entry_result Lwt.t;
      conv : 'ctx -> 'ictx;
      path : string;
    }
      -> 'ctx entry

let construct_error payload_enc payload =
  Json.construct
    (obj2 (req "kind" (constant "error")) (req "error_payload" payload_enc))
    ((), payload)

let construct_ok payload_enc payload =
  Json.construct
    (obj2 (req "kind" (constant "ok")) (req "payload" payload_enc))
    ((), payload)

let entrypoint ~path ~desc ~input ~output ~cases f =
  Entry
    {
      path;
      desc;
      input_enc = input;
      output_enc = output;
      cases;
      f;
      conv = (fun x -> x);
    }

let entrypoint_password ~path ~desc ~input ~output ~cases f =
  EntryPassword
    {
      path;
      desc;
      input_enc = input;
      output_enc = output;
      cases;
      f;
      conv = (fun x -> x);
    }

let map_entrypoint f entry =
  match entry with
  | Entry e ->
      Entry {e with conv = (fun x -> e.conv (f x))}
  | EntryPassword e ->
      EntryPassword {e with conv = (fun x -> e.conv (f x))}

let wrap errors retval =
  match retval with
  | Ok v ->
      return_ok v
  | Error (error :: _) -> (
      let info = Error_monad.find_info_of_error error in
      let find err (tag, id) =
        match err with
        | Some _ ->
            err
        | None ->
            if info.id = id then Some {tag; error} else None
      in
      match List.fold_left find None errors with
      | None ->
          return_err {tag = `GenericError; error}
      | Some err ->
          return_err err )
  | _ ->
      assert false

type error += GenericError

let _ =
  register_error_kind
    `Temporary
    ~id:"generic.error"
    ~title:"Generic error"
    ~description:
      "A generic error, which was not specified in the entrypoint spec"
    unit
    (function GenericError -> Some () | _ -> None)
    (fun () -> GenericError)
