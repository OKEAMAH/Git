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

module Shards = struct
  module Key : Index.Key.S = struct
    type t = Cryptobox.Commitment.t * int [@@deriving repr]

    let equal = ( = )

    let hash = Hashtbl.hash

    let hash_size = 30

    let encode = assert false

    let encoded_size = assert false

    let decode = assert false
  end

  module Value = struct
    type t = Cryptobox.share [@@deriving repr]

    let encode = assert false

    let encoded_size = assert false

    let decode _s _off = assert false
  end

  include Index_unix.Make (Key) (Value) (Index.Cache.Unbounded)

  let init path =
    let cache = empty_cache () in
    v ~log_size:4 ~cache ~fresh:true path
end

module Slot_shards = struct
  module Key = struct
    include Index.Key.String_fixed (struct
      let length = 50
    end)
  end

  module Value = struct
    include Index.Value.String_fixed (struct
      let length = 100
    end)
  end

  include Index_unix.Make (Key) (Value) (Index.Cache.Unbounded)

  let init path =
    let cache = empty_cache () in
    v ~log_size:4 ~cache ~fresh:true path
end
