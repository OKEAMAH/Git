(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Jingoo.Jg_types

let tvalue_to_string_opt tvalue =
  let open Jingoo.Jg_types in
  match tvalue with
  | Tstr s -> Some s
  | Tint i -> Some (string_of_int i)
  | Tbool b -> Some (string_of_bool b)
  | _ -> None

let run_templates_and_update_vars ~vars ~agent ~res ~re ~item
    (updates : Global_variables.update list) =
  List.fold_left
    (fun vars u ->
      Global_variables.update
        vars
        (Template.expand_update_var ~vars ~agent ~res ~re ~item u))
    vars
    updates

let interpret_global_uri_of_procedure :
    type a.
    self:Agent_name.t ->
    Orchestrator_state.t ->
    (a, Uri.global_uri) Remote_procedure.t ->
    (a, Uri.agent_uri) Remote_procedure.t =
 fun ~self state ->
  let open Remote_procedure in
  function
  | Quit -> Quit
  | Echo {payload} -> Echo {payload}
  | Start_octez_node {network; snapshot; sync_threshold} ->
      Start_octez_node {network; snapshot; sync_threshold}
  | Originate_smart_rollup {with_wallet; with_endpoint; alias; src} ->
      let with_endpoint =
        Uri.agent_uri_of_global_uri
          ~self
          ~services:(fun agent_name node_name ->
            Orchestrator_state.get_service_info
              Octez_node
              Rpc
              state
              agent_name
              node_name)
          with_endpoint
      in
      Originate_smart_rollup {with_wallet; with_endpoint; alias; src}
  | Start_rollup_node {with_wallet; with_endpoint; operator; mode; address} ->
      let with_endpoint =
        Uri.agent_uri_of_global_uri
          ~self
          ~services:(fun agent_name node_name ->
            Orchestrator_state.get_service_info
              Octez_node
              Rpc
              state
              agent_name
              node_name)
          with_endpoint
      in
      Start_rollup_node {with_wallet; with_endpoint; operator; mode; address}

let run_job_body ~state ~agent ~re ~item ~vars_updates job_name
    (body : Uri.global_uri Job.body) =
  let agent_name = Remote_agent.name agent in
  Log.info
    ~color:Log.Color.FG.magenta
    "[%s] %s%a"
    (agent_name :> string)
    job_name
    Format.(pp_print_option (fun fmt v -> fprintf fmt " (item=%s)" v))
    (tvalue_to_string_opt item) ;

  let* res =
    match body with
    | Copy {source; destination} ->
        assert (Filename.is_relative destination) ;
        let destination = Remote_agent.scope agent destination in
        let* () =
          Helpers.mkdir
            ~p:true
            ~runner:(Remote_agent.runner agent)
            (Filename.dirname destination)
        in
        let* () =
          Helpers.deploy
            ~r:true
            ~for_runner:(Remote_agent.runner agent)
            source
            destination
        in
        return Tnull
    | Remote_procedure {procedure = Remote_procedure.Packed cmd} ->
        let cmd =
          interpret_global_uri_of_procedure
            ~self:(Remote_agent.name agent)
            state
            cmd
        in
        let* handler = Remote_agent.start_request agent cmd in
        let* res = Remote_agent.wait_for_request agent handler in
        let res = Remote_procedure.tvalue_of_response cmd res in
        return res
  in
  Orchestrator_state.with_global_variables state (fun vars ->
      run_templates_and_update_vars ~vars ~agent ~res ~re ~item vars_updates) ;

  unit

let run_job ~state ~agent ~re (job : string Job.t) =
  let vars = Orchestrator_state.get_global_variables state in
  let items =
    match job.header.with_items with
    | Some item_defs ->
        Seq.concat
          (List.to_seq
             (List.map (Template.expand_item ~vars ~agent ~re) item_defs))
    | None -> Seq.return Tnull
  in
  Execution_params.traverse
    job.header.mode
    (fun item ->
      let body = Template.expand_job_body ~vars ~agent ~re ~item job.body in
      run_job_body
        ~state
        ~agent
        ~re
        ~item
        ~vars_updates:job.header.vars_updates
        job.header.name
        body)
    items

let run_jobs ~state ~agent ~re mode jobs =
  Execution_params.traverse
    mode
    (fun job -> run_job ~state ~agent ~re job)
    (List.to_seq jobs)

module Re = struct
  let rex r = Re.compile (Re.Perl.re r)

  let ( =~ ) s r = Re.execp r s

  let matches r s =
    let groups = Re.all r s in
    List.to_seq groups
    |> Seq.map (fun group -> Re.Group.all group |> Array.to_seq)
    |> Seq.concat
    |> Seq.map (fun x -> Tstr x)
    |> Array.of_seq
end

let run_stage ~state (stage : Stage.t) =
  let open Re in
  let vars = Orchestrator_state.get_global_variables state in
  Log.info ~color:Log.Color.FG.cyan "[orchestrator] %s" stage.name ;
  let agents_regex =
    List.map
      (fun regex ->
        let regex = Template.expand_agent ~vars regex in
        rex regex)
      stage.with_agents
  in
  Orchestrator_state.iter_agents stage.run_agents state (fun agent ->
      let agent_name = Remote_agent.name agent in
      let re =
        List.find_map
          (fun regex ->
            if (agent_name :> string) =~ regex then
              let re = matches regex (agent_name :> string) in
              Some (Tarray re)
            else None)
          agents_regex
      in
      match re with
      | Some re -> run_jobs ~state ~agent ~re stage.run_jobs stage.jobs
      | None -> unit)

let run_stages ~state (stages : Stage.t list) =
  Execution_params.traverse Sequential (run_stage ~state) (List.to_seq stages)

let initialize_agent ~state (agent : Recipe.agent) =
  let open Recipe in
  let runner =
    Runner.create
      ~address:agent.address
      ~ssh_user:agent.user
      ~ssh_port:agent.port
      ~ssh_id:agent.identity
      ()
  in

  let agent = Remote_agent.create ~name:agent.name ~runner () in
  let* () =
    Remote_agent.run
      ~on_terminate:(fun _status ->
        Log.info "%s has terminated" (Remote_agent.name agent :> string) ;
        Orchestrator_state.forget_agent state (Remote_agent.name agent) ;
        unit)
      agent
  in
  let* () = Remote_agent.wait_for_ready agent in
  Orchestrator_state.record_agent state agent ;
  unit

let initialize_agents ~state agents =
  Lwt_list.iter_p (initialize_agent ~state) agents

let terminate_agents ~state =
  Orchestrator_state.iter_agents Concurrent state (fun agent ->
      let* handler = Remote_agent.start_request agent Quit in
      let* () = Remote_agent.wait_for_request agent handler in
      unit)

let run_recipe (recipe : Recipe.t) =
  let state = Orchestrator_state.initial_state recipe.vars in
  let* () = initialize_agents ~state recipe.agents in
  let* () = run_stages ~state recipe.stages in
  terminate_agents ~state
