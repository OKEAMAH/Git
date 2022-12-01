(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech  <contact@trili.tech>                       *)
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

(* DAC/FIXME: https://gitlab.com/tezos/tezos/-/issues/4088
   Add .mli file. *)

(** Library for encoding payloads of arbitrary size in formats that can be
    decoded by the Sc-rollup kernels.
 *)

open Protocol
open Environment.Error_monad

type error +=
  | Payload_cannot_be_empty
  | Cannot_serialize_page_payload
  | Cannot_deserialize_page
  | Non_positive_size_of_payload
  | Merkle_tree_branching_factor_not_high_enough
  | Hashes_page_repr_already_full
  | Hashes_page_repr_expected_single_element

let () =
  register_error_kind
    `Permanent
    ~id:"cannot_deserialize_dac_page_payload"
    ~title:"DAC payload could not be deserialized"
    ~description:"Error when recovering DAC payload payload from binary"
    ~pp:(fun ppf () ->
      Format.fprintf
        ppf
        "Error when recovering DAC payload from list of data chunks")
    Data_encoding.(unit)
    (function Cannot_deserialize_page -> Some () | _ -> None)
    (fun () -> Cannot_deserialize_page) ;
  register_error_kind
    `Permanent
    ~id:"cannot_serialize_dac_page"
    ~title:"DAC page could not be serialized"
    ~description:"Error when serializing DAC page"
    ~pp:(fun ppf () -> Format.fprintf ppf "Error when serializing DAC page")
    Data_encoding.(unit)
    (function Cannot_serialize_page_payload -> Some () | _ -> None)
    (fun () -> Cannot_serialize_page_payload) ;
  register_error_kind
    `Permanent
    ~id:"non_positive_payload_size"
    ~title:"Non positive size for dac payload"
    ~description:"Dac page payload (excluded preamble) are non positive"
    ~pp:(fun ppf () ->
      Format.fprintf ppf "Dac page payload (excluded preamble) are non positive")
    Data_encoding.(unit)
    (function Non_positive_size_of_payload -> Some () | _ -> None)
    (fun () -> Non_positive_size_of_payload) ;
  register_error_kind
    `Permanent
    ~id:"dac_payload_cannot_be_empty"
    ~title:"Cannot serialize empty DAC payload"
    ~description:"Cannot serialize empty DAC payload"
    ~pp:(fun ppf () -> Format.fprintf ppf "Cannot serialize empty DAC payload")
    Data_encoding.(unit)
    (function Payload_cannot_be_empty -> Some () | _ -> None)
    (fun () -> Payload_cannot_be_empty) ;
  register_error_kind
    `Permanent
    ~id:"merkle_tree_branching_factor_not_high_enough"
    ~title:"Merkle tree branching factor must be at least 2"
    ~description:"Merkle tree branching factor must be at least 2"
    ~pp:(fun ppf () ->
      Format.fprintf
        ppf
        "Cannot serialize DAC payload: pages must be able to contain at least \
         two hashes")
    Data_encoding.(unit)
    (function
      | Merkle_tree_branching_factor_not_high_enough -> Some () | _ -> None)
    (fun () -> Merkle_tree_branching_factor_not_high_enough) ;
  register_error_kind
    `Permanent
    ~id:"hashes_page_builder_page_repr_already_full"
    ~title:"Hashes page builder page already full"
    ~description:
      "Cannot add another hash to hashes page_repr due to being full already"
    ~pp:(fun ppf () ->
      Format.fprintf
        ppf
        "Hashes page builder cannot add another hash to hashes page_repr since \
         it is already full")
    Data_encoding.(unit)
    (function Hashes_page_repr_already_full -> Some () | _ -> None)
    (fun () -> Hashes_page_repr_already_full) ;
  register_error_kind
    `Permanent
    ~id:"hashes_page_repr_expected_single_element"
    ~title:"Hashes page representation expected a single element"
    ~description:"Hashes page representation expected a single element"
    ~pp:(fun ppf () ->
      Format.fprintf ppf "Hashes page representation expected a single element")
    Data_encoding.unit
    (function Hashes_page_repr_expected_single_element -> Some () | _ -> None)
    (fun () -> Hashes_page_repr_expected_single_element)

(** Encoding of DAC payload as a Merkle tree with an arbitrary branching
    factor greater or equal to 2. The serialization process works as follows:
    {ul
      {li A large sequence of bytes, the payload, is split into several pages
          of fixed size, each of which is prefixed with a small sequence
          of bytes (also of fixed size), which is referred to as the preamble
          of the page. Pages obtained directly from the original payload
          are referred to as `Contents pages`. Contents pages constitute the
          leaves of the Merkle tree being built,
      }
      {li Each contents page (each of which is a sequence of bytes consisting
        of the preamble followed by the actual contents from the original
        payload) is then hashed. The size of each hash is fixed. The hashes are
        concatenated together, and the resulting sequence of bytes is split
        into pages of the same size of `Hashes pages`, each of which is
        prefixed with a preamble whose size is the same as in Contents pages.
        Hashes pages correspond to nodes of the Merkle tree being built, and
        the children of a hash page are the (either Payload or Hashes) pages
        whose hash appear into the former,
      }
      {li Hashes pages are hashed using the same process described above, leading
        to a smaller list of hashes pages. To guarantee that the list of hashes
        pages is actually smaller than the original list of pages being hashed,
        we require the size of pages to be large enough to contain at least two
        hashes.
      }
    }

    Merkle tree encodings of DAC pages are versioned, to allow for multiple
    hashing schemes to be used.
 *)
module Merkle_tree = struct
  type version = int

  (** A page is either a `Contents page`, containing a chunk of the payload
      that needs to be serialized, or a `Hashes page`, containing a list
      of hashes. The maximum size of bytes inside [Contents] page, or number
      of hashes inside [Hashes] page is such, that when serializing a page
      using [page_encoding], it does not exceed [max_page_size] bytes.
    *)
  type 'a page = Contents of bytes | Hashes of 'a list

  let max_version = 127

  module type VERSION = sig
    val contents_version_tag : version

    val hashes_version_tag : version
  end

  (* Even numbers are used for versioning Contents pages, odd numbers are used
     for versioning Hashes pages. *)
  module Make_version (V : sig
    val contents_version : int

    val hashes_version : int
  end) =
  struct
    let contents_version_tag = 2 * V.contents_version

    let hashes_version_tag = (2 * V.hashes_version) + 1
  end

  module Make (Hashing_scheme : sig
    include Dac_preimage_data_manager.REVEAL_HASH

    val scheme : supported_hashes
  end)
  (V : VERSION) =
  struct
    let hash bytes =
      Hashing_scheme.hash_bytes [bytes] ~scheme:Hashing_scheme.scheme

    let hash_encoding = Hashing_scheme.encoding

    let hashes_encoding = Data_encoding.list hash_encoding

    let to_b58check = Hashing_scheme.to_b58check

    (* The preamble of a serialized page contains 1 byte denoting the version,
       and 4 bytes encoding the size of the rest of the page. In total, 5
       bytes. *)
    let page_preamble_size = 5

    let hash_bytes_size = Hashing_scheme.size ~scheme:Hashing_scheme.scheme

    (** Payload pages are encoded as follows: the first byte is an integer,
        which is corresponds to either `payload_version` (for payload pages) or
        `hashes_version` (for hashes pages). The next four bytes will contain
        the size of the rest of the page; the remainder of the page is either a
        list of raw bytes (in the case of a payload page), or a list of hashes,
        which occupy 32 bytes each. *)
    let page_encoding =
      Data_encoding.(
        union
          ~tag_size:`Uint8
          [
            case
              ~title:"contents"
              (Tag V.contents_version_tag)
              bytes
              (function Contents payload -> Some payload | _ -> None)
              (fun payload -> Contents payload);
            case
              ~title:"hashes"
              (Tag V.hashes_version_tag)
              hashes_encoding
              (function Hashes hashes -> Some hashes | _ -> None)
              (fun hashes -> Hashes hashes);
          ])

    (** Serialization function for a single page. It converts a page to a
        sequence of bytes using [page_encoding]. It also checks that the
        serialized page does not exceed [page_size] bytes. *)
    let serialize_page ~max_page_size page =
      match
        Data_encoding.Binary.to_bytes
          (Data_encoding.check_size max_page_size page_encoding)
          page
      with
      | Ok raw_page -> Ok raw_page
      | Error _ -> error Cannot_serialize_page_payload

    let max_hashes_per_page ~max_page_size =
      (max_page_size - page_preamble_size) / hash_bytes_size

    (* Splits payload into bytes chunks whose size does not exceed [page_size] bytes. *)
    let split_payload ~max_page_size payload =
      let open Result_syntax in
      (* 1 byte for the version size, 4 bytes for the size of the payload. *)
      let actual_page_size = max_page_size - page_preamble_size in
      if actual_page_size <= 0 then error Non_positive_size_of_payload
      else
        let+ splitted_payload = String.chunk_bytes actual_page_size payload in
        List.map String.to_bytes splitted_payload

    let store_page ~max_page_size ~for_each_page page =
      let open Lwt_result_syntax in
      let*? serialized_page = serialize_page ~max_page_size page in
      (* Hashes are computed from raw pages, each of which consists of a
         preamble of 5 bytes followed by a page payload - a raw sequence
         of bytes from the original payload for Contents pages, and a
         a sequence of serialized hashes for hashes pages. The preamble
         bytes is part of the sequence of bytes which is hashed.
      *)
      let hash = hash serialized_page in
      let* () = for_each_page (hash, serialized_page) in
      return hash

    type for_each_page =
      Hashing_scheme.t * bytes ->
      (unit, Environment.Error_monad.error Environment.Error_monad.trace) result
      Lwt.t

    type max_page_size = int

    (** [Payload_handler] is in-memory data structure that allows for serialization
        of DAC payload, by receiving the payload in multiple parts, allowing for
        partial serialization of data. The serializer holds only the minimum of 
        necessarily data required for partial serialization of payload data.
        Additionaly, the serializer respects the following invariant:
        
        Starting with an [empty] serializer, splitting arbitrary [payload] into
        chunks of arbitrary size, and adding them to the serializer from left to
        right, should result in same root hash as adding all the payload data in
        one chunk provided it could fit into the memory. 
        
        Motivation for this data structure was to facilitate serialization of DAC 
        payload that would be to big to fit into memory. Additionaly this could 
        also be used in a batcher like scenario, e.g. for agreggating asynchronous
        payload messages. *)
    module Payload_handler = struct
      (** [Hashes_handler] module defines an in-memory data structure dedicated
          to storing, the minimum amount of hashes in memory, requiered for partial
          serialization of dac payload. *)
      module Hashes_handler = struct
        (** [Hashes_page_repr] is a builder for a [Hashes] page. It ensures that
            number of hashes in the given page would never produce a serialized
            page, which size would be bigger than [~max_page_size] bytes *)
        module Hashes_page_repr = struct
          type t = {
            size : int;
            hashes : Hashing_scheme.t list;
            max_page_size : max_page_size;
          }

          (** [empty ~max_page_size] throws [Merkle_tree_branching_factor_not_high_enough],
              in case of branching factor smaller then 2. *)
          let empty ~max_page_size =
            let open Lwt_result_syntax in
            let hashes_per_page =
              (max_page_size - page_preamble_size) / hash_bytes_size
            in
            (* Requiring a branching factor of at least 2 is necessary to ensure
               that the serialization process terminates. If only one hash was
               stored per page, then the number of pages at height `n-1` could be
               potentially equal to the number of pages at height `n`. *)
            let* () =
              fail_unless
                (hashes_per_page >= 2)
                Merkle_tree_branching_factor_not_high_enough
            in
            return {size = 0; hashes = []; max_page_size}

          let is_full page_repr =
            page_repr.size
            = max_hashes_per_page ~max_page_size:page_repr.max_page_size

          (** [add page_repr hash] adds a [hash] to a given [page_repr]
              For performance reason hashes are added in reverse order.
              In case of [page_repr] that is already full
              [Hashes_page_repr_already_full] error is thrown  *)
          let add page_repr hash =
            let open Lwt_result_syntax in
            if is_full page_repr then tzfail Hashes_page_repr_already_full
            else
              return
                {
                  page_repr with
                  size = page_repr.size + 1;
                  hashes = hash :: page_repr.hashes;
                }

          (** [rev_combine page_repr] creates a valid [Hashes] page, by
              combining hashes inside [page_repr] in the reverse order. This
              is due to [add] function adding them in the reverse order *)
          let rev_combine page_repr = Hashes (List.rev page_repr.hashes)

          let is_empty page_repr = page_repr.size = 0

          let has_one_hash page_repr = page_repr.size = 1

          let get_hash page_repr =
            let open Lwt_result_syntax in
            match page_repr.hashes with
            | [x] -> return x
            | _ -> tzfail Hashes_page_repr_expected_single_element
        end

        (** At any given level, we can have at max 'number_of_hashes_per_page'.
            Whenever a given level is filled we simply serialize it as [Hashes] page
            and add the parent hash to the next level of the merkle tree.
            This invariant is ensured by representing a level with a [Hashes_page_repr.t],
            which does not allow to exceed [~max_page_size] constant. Observe that
            [t] (in-memory) together with already serialized [Hashes] pages (disk)
            represent a k-ary merkle tree for of the given DAC payload. *)
        type t = {
          stack : Hashes_page_repr.t Stack.t;
          max_page_size : max_page_size;
          for_each_page : for_each_page;
        }

        let empty ~max_page_size ~for_each_page =
          {
            stack = (Stack.create () : Hashes_page_repr.t Stack.t);
            max_page_size;
            for_each_page;
          }

        (** [add_hash handler hash] adds a hash into in-memory data structure.
            If number of hashes at any given level is sufficient for the full
            [Hashes] page, the page is serialized and stored to disk,
            freeing the memory. The parent hash is added to next level. The
            procedure repeats recursively if needed. *)
        let rec add_hash ({stack; max_page_size; for_each_page} as handler) hash
            =
          let open Lwt_result_syntax in
          let open Hashes_page_repr in
          let* empty = empty ~max_page_size in
          let () = if Stack.is_empty stack then Stack.push empty stack in
          let popped = Stack.pop stack in
          (* Add element to the bottom level *)
          let* popped_with_add = add popped hash in
          if is_full popped_with_add then
            let hashes_page = rev_combine popped_with_add in
            let* hash = store_page ~max_page_size ~for_each_page hashes_page in
            (* Hash of serialized page is recursively added to the next level *)
            let* () = add_hash handler hash in
            (* Since one level was popped we need to push it back *)
            return @@ Stack.push empty stack
          else return @@ Stack.push popped_with_add stack
        (* Else simply push back the modified level *)

        let rec finalize_hashes
            ({stack = s; max_page_size; for_each_page} as handler) =
          let open Lwt_result_syntax in
          let* () =
            (* Empty stack means no payload added in the first place *)
            fail_unless (not @@ Stack.is_empty s) Payload_cannot_be_empty
          in
          let popped = Stack.pop s in
          let open Hashes_page_repr in
          if is_empty popped then
            (* If [page_repr] is empty, there is nothing to hash *)
            finalize_hashes handler
          else if Stack.is_empty s && has_one_hash popped then
            (* If top level of the tree and only one hash, then this is a root hash *)
            get_hash popped
          else
            (* Else we serialize and store partially filled [Hashes] page,
               recursively, add the parent [hash] to next level, finally
               proceeding with [finalize_hashes] of a new stack *)
            let hashes_page = rev_combine popped in
            let* hash = store_page ~max_page_size ~for_each_page hashes_page in
            let* () = add_hash handler hash in
            finalize_hashes handler
      end

      (**  Whenever a payload is not evenly splitted, i.e. the last [Contents] 
           page would not be full, instead of serializing it directly, we buffer it
           instead and prepend it to the next chunk of payload data, if received,
           else serialize it upon call to [finalize].
           
           Invariant: [leftover] is never [Bytes.empty] or exceeds max 'page_size' *)
      type t = {
        hashes_handler : Hashes_handler.t;
        leftover : bytes;
        max_page_size : max_page_size;
        for_each_page : for_each_page;
      }

      let empty ~max_page_size ~for_each_page =
        {
          hashes_handler = Hashes_handler.empty ~max_page_size ~for_each_page;
          leftover = Bytes.empty;
          max_page_size;
          for_each_page;
        }

      (** [add serializer payload] returns a new state of the serializer [t]
           after serializing [payload] and thus modifying the current state. 
           Note that for every call to [add], as much data as possible is persisted
           to the disk via [~for_each_page] function.
           
           There is no guarantee however, that all the [payload] data has been
           actually processed until the serializer current state is
           finalized via the call to [finalize serializer]. *)
      let add handler payload =
        let open Lwt_result_syntax in
        (* [concat_leftover_and_split] ensures that returned [leftover] never
           exceeds max [Contents] 'page_size' or is empty*)
        let concat_leftover_and_split ~leftover ~payload =
          let payload = Bytes.concat Bytes.empty [leftover; payload] in
          let*? splitted_payload =
            split_payload ~max_page_size:handler.max_page_size payload
          in
          match List.rev splitted_payload with
          | [] -> return (Bytes.empty, [])
          | h :: xs -> return (h, List.rev xs)
        in
        let* () =
          fail_unless (Bytes.length payload > 0) Payload_cannot_be_empty
        in
        (* Prepend old [leftover] to new [payload] and split again accordingly *)
        let* leftover, splitted_payload =
          concat_leftover_and_split ~leftover:handler.leftover ~payload
        in
        (* For evey [splitted_payload] chunk (i.e. only full [Contetnts] pages)
            serialize it, store it and add a hash to the [Hashes_handler.t] *)
        let* () =
          List.iter_es
            (fun content ->
              let* cont_page =
                store_page
                  ~max_page_size:handler.max_page_size
                  ~for_each_page:handler.for_each_page
                  (Contents content)
              in
              Hashes_handler.add_hash handler.hashes_handler cont_page)
            splitted_payload
        in
        return {handler with leftover}

      (** [finalize handler] returns the [Hashing_scheme.t] representing a root
          hash of serialized data. It also guarantees, that all the payload data
          received via previous calls to [add], have been serialized to the disk.
      *)
      let finalize handler =
        let open Lwt_result_syntax in
        (* Store [leftover] as partially filled [Contents] page *)
        let* hash =
          store_page
            ~max_page_size:handler.max_page_size
            ~for_each_page:handler.for_each_page
            (Contents handler.leftover)
        in
        let* () = Hashes_handler.add_hash handler.hashes_handler hash in
        Hashes_handler.finalize_hashes handler.hashes_handler
    end

    (** Main function for computing the pages of a Merkle tree from a sequence
        of bytes. Each page is processed using the function [for_each_page]
        provided in input, which is responsible for ensuring that the original
        payload can be reconstructed from the Merkle tree root; this can be
        achieved, for example, by letting [for_each_page] persist a serialized
        page to disk using the page hash as its filename.
        The function [serialize_payload] returns the root hash of the Merkle
        tree constructed. *)
    let serialize_payload ~max_page_size payload ~for_each_page =
      let open Lwt_result_syntax in
      let open Payload_handler in
      let* s = add (empty ~max_page_size ~for_each_page) payload in
      finalize s

    (** Deserialization function for a single page. A sequence of bytes is
        converted to a page using [page_encoding]. *)
    let deserialize_page raw_page =
      match Data_encoding.Binary.of_bytes page_encoding raw_page with
      | Ok page -> Ok page
      | Error _ -> error Cannot_deserialize_page

    (** Deserialization function for reconstructing the original payload from
        its Merkle tree root hash. The function [retrieve_page_from_hash]
        passed in input is responsible for determining how to retrieve the
        serialized page from its hash. For example, if the page has been
        persisted to disk using the page hash as its filename,
        [retrieve_page_from_hash] simply loads the corresponding file from
        disk to memory. The function [deserialize_payload] returns the
        original payload that was used to compute the Merkle tree root hash.
        This function is guaranteed to terminate if the directed graph induced
        by the retrieved pages (that is, the graph where there is an edge
        from one page to another if and only if the former contains the hash
        of the latter) is acyclic. This property is guaranteed if the root
        hash and pages are computed using the serialized_payload function
        outlined above, but it is not guaranteed in more general cases.
     *)
    let deserialize_payload root_hash ~retrieve_page_from_hash =
      let rec go retrieved_hashes retrieved_contents =
        let open Lwt_result_syntax in
        match retrieved_hashes with
        | [] -> return @@ Bytes.concat Bytes.empty retrieved_contents
        | hash :: hashes -> (
            let* serialized_page = retrieve_page_from_hash hash in
            let*? page = deserialize_page serialized_page in
            match page with
            | Hashes page_hashes ->
                (* Hashes are saved in reverse order. *)
                (go [@tailcall])
                  (List.rev_append page_hashes hashes)
                  retrieved_contents
            | Contents contents ->
                (* Because hashes are saved in reversed order, content pages
                   will be retrieved in reverse order. By always appending a
                   conetent page to the list of retrieved content pages,
                   we ensure that pages are saved in `retrieved_contents` in
                   their original order. *)
                (go [@tailcall]) hashes (contents :: retrieved_contents))
      in
      go [root_hash] []
  end

  module V0 =
    Make
      (struct
        include Sc_rollup_reveal_hash

        let scheme = Sc_rollup_reveal_hash.Blake2B
      end)
      (Make_version (struct
        (* Cntents_version_tag used in contents pages is 0. *)
        let contents_version = 0

        (* Hashes_version_tag used in hashes pages is 1. *)
        let hashes_version = 0
      end))
end
