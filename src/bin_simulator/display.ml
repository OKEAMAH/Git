open Gg

let setup width height =
  let open Raylib in
  init_window width height "p2p sim" ;
  let camera =
    Camera.create
      (Vector3.create 50.0 50.0 50.0) (* position *)
      (Vector3.create 0.0 0.0 0.0) (* target *)
      (Vector3.create 0.0 1.0 0.0) (* up *)
      45.0
      (* FOV *) CameraProjection.Perspective
  in
  set_camera_mode camera CameraMode.Free ;
  set_target_fps 60 ;
  camera

type color = int * int * int

type style =
  | Circle of float * color (* radius * color *)
  | Square of float * color

(* width * color *)

(* A drawable object is defined by its position, its style and some string data.  *)
type obj = {style : style; mutable text : string}

type params = {zoom : float; xres : int; yres : int}

module SM = Springmodel

let p3_to_raylib (v : P3.t) = Raylib.Vector3.create (P3.x v) (P3.y v) (P3.z v)

let rgb_from_color (c : Raylib.Color.t) =
  let open Raylib.Color in
  let r = r c in
  let g = g c in
  let b = b c in
  let a = a c in
  (r, g, b, a)

let texture_table = Hashtbl.create 11

let texture_from_text text size color =
  let key = (text, size, rgb_from_color color) in
  match Hashtbl.find_opt texture_table key with
  | Some texture -> texture
  | None ->
      let text_img = Raylib.image_text text size color in
      let texture = Raylib.load_texture_from_image text_img in
      Hashtbl.add texture_table key texture ;
      texture

let draw_text camera pos size color text =
  let texture = texture_from_text text 10 color in
  Raylib.draw_billboard camera texture pos size color

let draw_scene :
    SM.t ->
    draw_node:(SM.Vertex.t -> Raylib.Vector3.t -> unit) ->
    draw_edge:
      (SM.Vertex.t ->
      Raylib.Vector3.t ->
      SM.Vertex.t ->
      Raylib.Vector3.t ->
      unit) ->
    unit =
 fun model ~draw_node ~draw_edge ->
  SM.G.iter_edges
    (fun source_id target_id ->
      let source_state = SM.Vertex_table.find model.SM.state source_id in
      let target_state = SM.Vertex_table.find model.SM.state target_id in
      let vec = V3.sub target_state.SM.position source_state.SM.position in
      let unit_dir = V3.unit vec in
      let src = p3_to_raylib @@ V3.add source_state.SM.position unit_dir in
      let tgt = p3_to_raylib @@ V3.sub target_state.SM.position unit_dir in
      Raylib.draw_line_3d src tgt Raylib.Color.black ;
      draw_edge source_id src target_id tgt)
    model.SM.graph ;
  SM.Vertex_table.iter
    (fun id state ->
      let pos = p3_to_raylib state.SM.position in
      draw_node id pos)
    model.SM.state

let t0 = Tezos_shims_shared.Internal_for_tests.now ()

let draw_all sm camera ~draw_node ~draw_edge =
  let open Raylib in
  begin_drawing () ;
  clear_background Color.raywhite ;
  begin_mode_3d camera ;
  draw_scene sm ~draw_node ~draw_edge ;
  draw_grid 100 10.0 ;
  end_mode_3d () ;
  draw_rectangle 10 10 320 133 (fade Color.skyblue 0.5) ;
  draw_rectangle_lines 10 10 320 133 Color.blue ;
  draw_text "Free camera default controls:" 20 20 10 Color.black ;
  draw_text "- Mouse Wheel to Zoom in-out" 40 40 10 Color.darkgray ;
  draw_text "- Mouse Wheel Pressed to Pan" 40 60 10 Color.darkgray ;
  draw_text "- Alt + Mouse Wheel Pressed to Rotate" 40 80 10 Color.darkgray ;
  draw_text
    "- Alt + Ctrl + Mouse Wheel Pressed for Smooth Zoom"
    40
    100
    10
    Color.darkgray ;
  draw_text "- Z to zoom to (0 0 0)" 40 120 10 Color.darkgray ;
  let width = get_screen_width () in
  let height = get_screen_height () in
  let button_width = 200 in
  let button_height = 125 in
  let offset = 50 in
  let rect =
    Rectangle.create
      (float @@ (width - offset - button_width))
      (float @@ (height - offset - button_height))
      (float button_width)
      (float button_height)
  in
  let elapse = Raygui.button rect "Step forward" in

  let rect =
    Rectangle.create
      (float offset)
      (float (height - offset - button_height))
      (float button_width)
      (float button_height)
  in
  let relax = Raygui.button rect "Relax layout" in

  let elapsed = Tezos_shims_shared.Internal_for_tests.now () -. t0 in
  draw_text
    (Format.asprintf "elapsed: %f s" elapsed)
    (width - (2 * offset) - button_width)
    20
    30
    Color.black ;

  let next =
    Option.map
      (fun x -> x -. t0)
      (Tezos_shims_shared.Internal_for_tests.next_wakeup ())
  in
  draw_text
    (Format.asprintf
       "next: %a s"
       (Format.pp_print_option Format.pp_print_float)
       next)
    (width - (2 * offset) - button_width)
    60
    30
    Color.black ;

  end_drawing () ;
  (elapse, relax)
