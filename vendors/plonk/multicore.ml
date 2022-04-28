let with_pool f = f ()

let map2_one_chunk_per_core f l1 l2 = [f ~start:0 ~len:(Array.length l1) l1 l2]

let pmap = List.map
