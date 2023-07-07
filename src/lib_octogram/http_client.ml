open Uri
module SMap = Map.Make (String)

type t = {mutable pending_download : string Lwt.t SMap.t}

let create () = {pending_download = SMap.empty}

let local_path_from_agent_uri ?(keep_name = false) ?(exec = true) client =
  function
  | Owned {name = res} -> return res
  | Remote {endpoint} -> (
      let handler =
        if keep_name then Filename.basename endpoint
        else
          let (`Hex handler) =
            Tezos_crypto.Blake2B.(hash_string [endpoint] |> to_hex)
          in
          handler
      in
      match SMap.find_opt handler client.pending_download with
      | Some promise -> promise
      | None ->
          let promise, u = Lwt.task () in
          client.pending_download <-
            SMap.add handler promise client.pending_download ;
          Lwt.async (fun () ->
              let* path = Helpers.download endpoint handler in
              let* () =
                if exec then
                  let* () = Lwt_unix.chmod path 0o777 in
                  unit
                else unit
              in
              Lwt.wakeup u path ;
              unit) ;
          promise)
