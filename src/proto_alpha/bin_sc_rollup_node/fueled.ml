module type S = sig
  type 'a r

  type ticks

  type fuel

  type 'a t

  val run : 'a t -> fuel -> ('a * fuel) option r

  val map : 'a t -> ('a -> 'b) -> 'b t

  val bind : 'a t -> ('a -> 'b t) -> 'b t

  val with_consumption : fuel -> ('a -> 'b r) -> 'a -> 'b t

  val from_execution : ('a -> ('b * ticks) r) -> 'a -> 'b t
end

module Make (F : Fuel.S) : S = struct
  type 'a r = 'a tzresult Lwt.t

  type ticks = int64

  type fuel = F.t

  type 'a t = fuel -> ('a * fuel) option r

  let run (type a) (comp : a t) fuel : (a * fuel) option r = comp fuel

  let map (type a b) (computation : a t) (f : a -> b) : b t =
    let new_computation fuel =
      let open Lwt.Syntax in
      let+ result = computation fuel in
      Result.map (Option.map (fun (result, fuel) -> (f result, fuel))) result
    in
    new_computation

  let not_enough_fuel (type a) : a t = fun _fuel -> Lwt_result.return None

  let bind (type a b) (ma : a t) (f : a -> b t) : b t =
    let new_computation fuel_tank : (b * fuel) option r =
      let open Lwt_result_syntax in
      let* result_opt = ma fuel_tank in
      match result_opt with
      | None -> not_enough_fuel fuel_tank
      | Some (a, consumption) -> (
          match F.consume fuel_tank consumption with
          | None -> not_enough_fuel fuel_tank
          | Some remaining_tank -> f a remaining_tank)
    in
    new_computation

  let with_consumption (type a b) (consumption : fuel) (f : a -> b r) (a : a) :
      b t =
    let open Lwt_result_syntax in
    fun fuel ->
      match F.consume consumption fuel with
      | None -> return None
      | Some remaining_fuel ->
          let+ b = f a in
          Some (b, remaining_fuel)

  let from_execution (type a b) (f : a -> (b * ticks) r) (a : a) : b t =
    let open Lwt_result_syntax in
    fun fuel ->
      let+ b, executed_ticks = f a in
      match F.consume (F.of_ticks executed_ticks) fuel with
      | None -> None
      | Some remaining_fuel -> Some (b, remaining_fuel)
end