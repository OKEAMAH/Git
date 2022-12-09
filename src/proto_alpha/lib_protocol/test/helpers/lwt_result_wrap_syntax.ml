include Tezos_base.TzPervasives.Lwt_result_syntax

let wrap_tzresult m = m >|= Environment.wrap_tzresult

let ( let*@ ) m f =
  let* x = wrap_tzresult m in
  f x

let ( let*?@ ) m f =
  let*? x = Environment.wrap_tzresult m in
  f x

let ( let+@ ) m f =
  let+ x = wrap_tzresult m in
  f x
