module Kernels = struct
  let tx_kernel_old = "src/lib_scoru_wasm/bin/kernels/tx_kernel/tx_kernel.wasm"

  let tx_kernel_vRAM_nosig =
    "src/lib_scoru_wasm/bin/kernels/tx_kernel/tx_kernal_deb95799cc_nosig.wasm"

  let tx_kernel_vRAM_sig =
    "src/lib_scoru_wasm/bin/kernels/tx_kernel/tx_kernel_12bf6a994.wasm"

  (** https://gitlab.com/trili/kernel/-/commit/e759f43ec27ef5fa2cebb567780a61702e851c33/pipelines?ref=main *)
  let tx_kernal_vRam_latest =
    "src/lib_scoru_wasm/bin/kernels/tx_kernel/tx_kernel_e759f43e.wasm"

  let computation_kernel = "src/lib_scoru_wasm/bin/kernels/computation.wasm"

  let unreachable_kernel = "src/lib_scoru_wasm/bin/kernels/unreachable.wasm"
end

module Messages = struct
  module Deposit_transfer_withdraw = struct
    let fst_deposit =
      "tx_kernel/deposit_transfer_withdraw/fst_deposit_message.out"

    let snd_deposit =
      "tx_kernel/deposit_transfer_withdraw/snd_deposit_message.out"

    let invalid_message =
      "tx_kernel/deposit_transfer_withdraw/invalid_external_message.out"

    let valid_message =
      "tx_kernel/deposit_transfer_withdraw/valid_external_message.out"
  end

  module Large = struct
    let transfer_two_actors =
      "tx_kernel/deposit_transfer_withdraw/big_external_message.out"
  end

  module Old = struct
    let deposit = "tx_kernel/deposit_then_withdraw_to_same_address/deposit.out"

    let withdrawal =
      "tx_kernel/deposit_then_withdraw_to_same_address/withdrawal.out"
  end
end