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

let set_gauge help name f =
  let m = v_gauge ~help name in
  fun x -> Gauge.set m @@ f x

module Cohttp (Server : Cohttp_lwt.S.Server) = struct
  let callback _conn req _body =
    let open Cohttp in
    let open Lwt_syntax in
    let uri = Request.uri req in
    match (Request.meth req, Uri.path uri) with
    | `GET, "/metrics" ->
        let* data_sc = CollectorRegistry.(collect sc_rollup_node_registry) in
        let* data_injector =
          CollectorRegistry.(collect Octez_injector.Metrics.registry)
        in
        let data_merged =
          MetricFamilyMap.merge
            (fun _ v1 v2 -> match v1 with Some v1 -> Some v1 | _ -> v2)
            data_sc
            data_injector
        in
        let body =
          Fmt.to_to_string Prometheus_app.TextFormat_0_0_4.output data_merged
        in
        let headers =
          Header.init_with "Content-Type" "text/plain; version=0.0.4"
        in
        Server.respond_string ~status:`OK ~headers ~body ()
    | `GET, "/test" ->
        let headers =
          Header.init_with "Content-Type" "text/plain; version=0.0.4"
        in
        let body = "bla" in
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
    (MetricFamilyMap.to_list metrics) ;
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
      ~label_names:
        ["rollup_address"; "mode"; "genesis_level"; "genesis_hash"; "pvm_kind"]
      "rollup_node_info"

  let init_rollup_node_info ~id ~mode ~genesis_level ~genesis_hash ~pvm_kind =
    let id = Tezos_crypto.Hashed.Smart_rollup_address.to_b58check id in
    let mode = Configuration.string_of_mode mode in
    let genesis_level = Int32.to_string genesis_level in
    let genesis_hash = Commitment.Hash.to_b58check genesis_hash in
    ignore
    @@ Counter.labels
         rollup_node_info
         [id; mode; genesis_level; genesis_hash; pvm_kind] ;
    ()

  let () =
    let version = Version.to_string Current_git_info.version in
    let commit_hash = Current_git_info.commit_hash in
    let commit_date = Current_git_info.committer_date in
    let _ =
      Counter.labels node_general_info [version; commit_hash; commit_date]
    in
    ()

  let set_lcc_level_l1 =
    set_gauge
      "Block level of the Last Cemented Commitment on (LCC) - L1"
      "lcc_level_l1"
      Int32.to_float

  let set_lcc_level_local =
    set_gauge
      "Block level of the Last Cemented Commitment (LCC) - Local"
      "lcc_level_local"
      Int32.to_float

  let set_lpc_level_l1 =
    set_gauge
      "Block level of the Last Published Commitment on (LCC) - L1"
      "lpc_level_l1"
      Int32.to_float

  let set_lpc_level_local =
    set_gauge
      "Block level of the Last Published Commitment (LCC) - Local"
      "lpc_level_local"
      Int32.to_float
end

module Inbox = struct
  let set_head_level =
    set_gauge "Level of last inbox" "inbox_level" Int32.to_float

  let internal_messages_number =
    v_gauge
      ~help:"Number of internal messages in inbox"
      "inbox_internal_messages_number"

  let external_messages_number =
    v_gauge
      ~help:"Number of external messages in inbox"
      "inbox_external_messages_number"

  let set_messages ~is_internal l =
    let internal, external_ =
      List.fold_left
        (fun (internal, external_) x ->
          if is_internal x then (internal +. 1., external_)
          else (internal, external_ +. 1.))
        (0., 0.)
        l
    in
    Gauge.set internal_messages_number internal ;
    Gauge.set external_messages_number external_

  let set_process_time =
    set_gauge
      "The time the rollup node spent processing the head"
      "inbox_process_time"
      Ptime.Span.to_float_s

  let set_fetch_time =
    set_gauge
      "The time the rollup node spent fetching the inbox"
      "inbox_fetch_time"
      Ptime.Span.to_float_s
end

module GC = struct
  let set_process_time =
    set_gauge "GC processing time" "gc_process_time" Ptime.Span.to_float_s

  let set_oldest_available_level =
    set_gauge
      "Oldest Available Level after GC"
      "gc_oldest_available_level"
      Int32.to_float
end

module PVM = struct end

module Batcher = struct
  let set_get_time =
    set_gauge "Time to fetch batches" "batcher_get_time" Ptime.Span.to_float_s

  let set_inject_time =
    set_gauge
      "Time to inject batches"
      "batcher_inject_time"
      Ptime.Span.to_float_s

  let set_message_queue_size =
    set_gauge "Batcher queue size" "batcher_queue_size" Int.to_float

  let set_last_batch_level =
    set_gauge "Level of last batch" "batcher_last_batch_level" Int32.to_float

  let set_last_batch_time =
    set_gauge "Time of last batch" "batcher_last_batch_time" Ptime.to_float_s
end

module Performance = struct
  let virtual_ = v_gauge ~help:"Size Memory Stats" "performance_virtual"

  let resident = v_gauge ~help:"Resident Memory Stats" "performance_resident"

  let shared = v_gauge ~help:"Shared Memory Stats" "performance_shared"

  let mem = v_gauge ~help:"Mem Memory Stats" "performance_mem"

  let set_memory_stats () =
    let open Lwt_syntax in
    let* result = Sys_info.memory_stats () in
    let one_mega = 1024. *. 1024. in
    match result with
    | Ok (Statm stats) ->
        let page_size = Int64.of_int stats.page_size in
        Gauge.set virtual_
        @@ (Int64.(to_float @@ mul stats.size page_size) /. one_mega) ;
        Gauge.set resident
        @@ (Int64.(to_float @@ mul stats.resident page_size) /. one_mega) ;
        Gauge.set shared
        @@ (Int64.(to_float @@ mul stats.shared page_size) /. one_mega) ;
        return_unit
    | Ok (Ps stats) ->
        Gauge.set mem (stats.mem *. Int.to_float stats.page_size /. one_mega) ;
        Gauge.set resident
        @@ Int64.(to_float @@ mul stats.resident @@ of_int stats.page_size)
           /. one_mega ;
        return_unit
    | Error _ ->
        Format.eprintf "ERROR WHILE GETTING MEMORY STATS@." ;
        return_unit

  let cpu = v_gauge ~help:"CPU Percentage" "performance_cpu_percentage"

  let set_cpu_stats =
    let open Unix in
    let sum ts =
      ts.tms_utime +. ts.tms_stime +. ts.tms_cutime +. ts.tms_cstime
    in
    let t0 = ref 0. in
    let ts0 = ref 0. in
    fun () ->
      let t = Unix.gettimeofday () in
      let ts = sum @@ Unix.times () in
      if !t0 = 0. then (
        t0 := t ;
        ts0 := ts)
      else
        let percentage = (ts -. !ts0) /. (t -. !t0) *. 100. in
        t0 := t ;
        ts0 := ts ;
        Gauge.set cpu percentage

  let rec directory_size path =
    let content = Sys.readdir path in
    Array.fold_left (fun acc file ->
        let full_path = Filename.concat path file in
        if Sys.is_directory full_path then
          acc + directory_size full_path
        else
          let stat = Unix.stat full_path in
          acc + stat.st_size) 0 content

  let storage = v_gauge ~help:"Storage Disk Usage" "performance_storage"
  let context = v_gauge ~help:"Context Disk Usage" "performance_context"
  let logs = v_gauge ~help:"Logs Disk Usage" "performance_logs"
  let data = v_gauge ~help:"Data Disk Usage" "performance_data"

  let set_disk_usage_stats data_dir =
    let one_mega = 1024 * 1024 in
    Gauge.set storage @@ Float.of_int @@ (directory_size @@ Filename.concat data_dir "storage") / one_mega;
    Gauge.set context @@ Float.of_int @@ (directory_size @@ Filename.concat data_dir "context") / one_mega;
    Gauge.set logs @@ Float.of_int @@ (directory_size @@ Filename.concat data_dir "daily_logs") / one_mega;
    Gauge.set data @@ Float.of_int @@ (directory_size data_dir) / one_mega

  let set_stats data_dir =
    set_disk_usage_stats data_dir;
    set_cpu_stats ();
    set_memory_stats ()
end
