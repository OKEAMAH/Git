(module
  (type (;0;) (func (param i32 i32 i32 i32 i32) (result i32)))
  (type $t0 (func (param i32 i32) (result i32)))
  (type $t3 (func (param i32 i32 i32 i32 i32) (result i32)))
  (import "rollup_safe_core" "read_input" (func $read_input (type $t3)))
  (import "rollup_safe_core" "write_output" (func $write_output (type $t0)))
  (func (export "kernel_next")
    (local $size i32)
   (local.set $size (call $read_input (i32.const 0) ;; rtype_offset
                      (i32.const 20) ;; level_offset
                      (i32.const 40) ;; id_offset
                      (i32.const 60) ;; dst
                      (i32.const 3600))) ;; max_bytes
    (call $write_output (i32.const 60) ;; dst
                       (local.get $size))
    drop)
  (memory (;0;) 17)
  (export "memory" (memory 0)))

