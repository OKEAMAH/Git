(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Prometheus

let sc_rollup_node_registry = CollectorRegistry.create ()

let namespace = Tezos_version.Node_version.namespace

let subsystem = "sc_rollup_node"

(** Registers a labeled counter in [sc_rollup_node_registry] *)
let v_labels_counter =
  Counter.v_labels ~registry:sc_rollup_node_registry ~namespace ~subsystem

(** Registers a gauge in [sc_rollup_node_registry] *)
let v_gauge = Gauge.v ~registry:sc_rollup_node_registry ~namespace ~subsystem

module Cohttp (Server : Cohttp_lwt.S.Server) = struct
  let callback _conn req _body =
    let open Cohttp in
    let open Lwt_syntax in
    let uri = Request.uri req in
    match (Request.meth req, Uri.path uri) with
    | `GET, "/metrics" ->
        let* data = CollectorRegistry.(collect sc_rollup_node_registry) in
        let body =
          Fmt.to_to_string Prometheus_app.TextFormat_0_0_4.output data
        in
        let headers =
          Header.init_with "Content-Type" "text/plain; version=0.0.4"
        in
        Server.respond_string ~status:`OK ~headers ~body ()
    | _ -> Server.respond_error ~status:`Bad_request ~body:"Bad request" ()
end

module Metrics_server = Cohttp (Cohttp_lwt_unix.Server)

let metrics_serve metrics_addr =
  let open Lwt_result_syntax in
  match metrics_addr with
  | Some metrics_addr ->
      let* addrs =
        Octez_node_config.Config_file.resolve_metrics_addrs
          ~default_metrics_port:Configuration.default_metrics_port
          metrics_addr
      in
      let*! () =
        List.iter_p
          (fun (addr, port) ->
            let host = Ipaddr.V6.to_string addr in
            let*! () = Event.starting_metrics_server ~host ~port in
            let*! ctx = Conduit_lwt_unix.init ~src:host () in
            let ctx = Cohttp_lwt_unix.Net.init ~ctx () in
            let mode = `TCP (`Port port) in
            let callback = Metrics_server.callback in
            Cohttp_lwt_unix.Server.create
              ~ctx
              ~mode
              (Cohttp_lwt_unix.Server.make ~callback ()))
          addrs
      in
      return_unit
  | None -> return_unit

let metric_type_to_string = function
  | Counter -> "Counter"
  | Gauge -> "Gauge"
  | Summary -> "Summary"
  | Histogram -> "Histogram"

let pp_label_names fmt =
  Format.pp_print_list
    ~pp_sep:(fun fmt () -> Format.fprintf fmt ";")
    (fun fmt v -> Format.fprintf fmt "%a" LabelName.pp v)
    fmt

let print_csv_metrics ppf metrics =
  let open Prometheus in
  Format.fprintf ppf "@[<v>Name,Type,Description,Labels" ;
  List.iter
    (fun (v, _) ->
      Format.fprintf
        ppf
        "@,@[%a@],%s,\"%s\",%a"
        MetricName.pp
        v.MetricInfo.name
        (metric_type_to_string v.MetricInfo.metric_type)
        v.MetricInfo.help
        pp_label_names
        v.MetricInfo.label_names)
    (Prometheus.MetricFamilyMap.to_list metrics) ;
  Format.fprintf ppf "@]@."

module Info = struct
  open Tezos_version

  let node_general_info =
    v_labels_counter
      ~help:"General information on the node"
      ~label_names:["version"; "commit_hash"; "commit_date"]
      "node_info"

  let rollup_node_info =
    let help = "Rollup node info" in
    v_labels_counter
      ~help
      ~label_names:["rollup_address"; "mode"; "genesis_level"; "pvm_kind"]
      "rollup_node_info"

  let init_rollup_node_info ~id ~mode ~genesis_level ~pvm_kind =
    let id = Tezos_crypto.Hashed.Smart_rollup_address.to_b58check id in
    let mode = Configuration.string_of_mode mode in
    let genesis_level = Int32.to_string genesis_level in
    ignore
    @@ Counter.labels rollup_node_info [id; mode; genesis_level; pvm_kind] ;
    ()

  let () =
    let version = Version.to_string Current_git_info.version in
    let commit_hash = Current_git_info.commit_hash in
    let commit_date = Current_git_info.committer_date in
    let _ =
      Counter.labels node_general_info [version; commit_hash; commit_date]
    in
    ()

  let lcc_last_update =
    v_gauge
      ~help:"Block level of the last update to the Last Cement Commitment (LCC)"
      "lcc_last_update"

  let set_lcc_last_update pt =
    Prometheus.Gauge.set lcc_last_update (Int32.to_float pt)
end

module Inbox = struct
  type t = {head_inbox_level : Gauge.t}

  let head_inbox_level =
    v_gauge ~help:"The level of the last inbox" "head_inbox_level"

  let head_internal_messages_number =
    v_gauge
      ~help:"The number of internal messages in head's inbox"
      "head_inbox_internal_messages_number"

  let head_external_messages_number =
    v_gauge
      ~help:"The number of external messages in head's inbox"
      "head_inbox_external_messages_number"

  module Stats = struct
    let set ~is_internal l =
      let internal, external_ =
        List.fold_left
          (fun (internal, external_) x ->
            if is_internal x then (internal +. 1., external_)
            else (internal, external_ +. 1.))
          (0., 0.)
          l
      in
      Prometheus.Gauge.set head_internal_messages_number internal ;
      Prometheus.Gauge.set head_external_messages_number external_
  end

  let head_process_time =
    v_gauge
      ~help:"The time the rollup node spent processing the head"
      "head_inbox_process_time"

  module Head_process_time_histogram = Histogram (struct
    (* These values define the 20 buckets of the histogram. The buckets deal
       with the time intervals [0.01 * i, 0.01 * (i + 1)) for i = 0,..., 20-1,
       so that we cover the range 0-200 ms for the inbox head processing time.
       The last bucket (i = 20) covers the range 200 ms-Infinity. *)
    let spec = Histogram_spec.of_linear 0. 0.01 20
  end)

  let head_process_time_histogram =
    Head_process_time_histogram.v
      ~registry:sc_rollup_node_registry
      ~namespace
      ~subsystem
      ~help:"The time the rollup node spent processing the head"
      "head_inbox_process_time_histogram"

  let set_process_time pt =
    let pt = Ptime.Span.to_float_s pt in
    Prometheus.Gauge.set head_process_time pt ;
    Head_process_time_histogram.observe head_process_time_histogram pt

  let set_head_inbox_level l =
    Prometheus.Gauge.set head_inbox_level (Int32.to_float l)
end

module Gc = struct
  let last_gc =
    v_gauge ~help:"Last call to the rollup node garbage collector" "last_gc"

  let set_last_gc pt = Prometheus.Gauge.set last_gc (Ptime.to_float_s pt)
end

module Wasm_2_0_0 = struct
  let level =
    v_gauge
      ~help:"Level of the L2 block, corresponds to the level of the tezos block"
      "etherlink_l2_head_level"

  let set_l2_head_level f = Prometheus.Gauge.set level (Int32.to_float f)

  let global_transactions_amount =
    v_gauge
      ~help:"Amount of transactions objects since the origination of the rollup"
      "etherlink_global_transactions_amount"

  let set_transactions_amount f =
    Prometheus.Gauge.set global_transactions_amount (Int.to_float f)
end

module Batcher = struct
  let message_queue_size =
    v_gauge ~help:"Size of Batcher's message queue" "message_queue_size"

  let set_message_queue_size s =
    Prometheus.Gauge.set message_queue_size (Int.to_float s)

  let last_batch_level = v_gauge ~help:"Level of last batch" "last_batch_level"

  let set_last_batch_level l =
    Prometheus.Gauge.set last_batch_level (Int32.to_float l)

  let last_batch_time = v_gauge ~help:"Time of last batch" "last_batch_time"

  let set_last_batch_time pt =
    Prometheus.Gauge.set last_batch_time (Ptime.to_float_s pt)
end

module Injector = struct
  let injected_operations_queue_size =
    v_gauge
      ~help:"Size of Injector's injected operations queue size"
      "injected_operations_queue_size"

  let set_injected_operations_queue_size s =
    Prometheus.Gauge.set injected_operations_queue_size (Int.to_float s)

  let included_operations_queue_size =
    v_gauge
      ~help:"Size of Injector's included operations queue size"
      "included_operations_queue_size"

  let set_included_operations_queue_size s =
    Prometheus.Gauge.set included_operations_queue_size (Int.to_float s)

  let worker_queue_size ~tag =
    v_gauge
      ~help:
        (Format.asprintf
           "Size of Injector's worker queue for operation tag %s"
           tag)
      (Format.asprintf "injector_worker_queue_size_%s" tag)

  let set_worker_queue_size : tag:string -> int -> unit =
   fun ~tag sz ->
    Prometheus.Gauge.set (worker_queue_size ~tag) (Int.to_float sz)
end
