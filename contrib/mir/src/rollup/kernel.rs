use tezos_smart_rollup::{
    prelude::{debug_msg, Runtime},
    types::Message,
};

// This module follows the reference examples: https://gitlab.com/tezos/kernel-gallery

/// The root method of the kernel.
///
/// Executed every level. Can be asked from inside to be run again at the same
/// level to handle some of the messages in the inbox, mind the limits on
/// execution time of one such call.
pub fn kernel_entry(host: &mut impl Runtime) {
    debug_msg!(host, "Kernel started");

    let mut first_message_for_invocation = true;
    // Handle all the messages we got at this level
    loop {
        match host.read_input() {
            Ok(Some(msg)) => {
                if first_message_for_invocation {
                    debug_msg!(host, "Handling messages at level {}", msg.level);
                    first_message_for_invocation = false;
                }

                // TODO: consider catching panics
                process_message(host, &msg);
            }
            Err(_) => continue,
            Ok(None) => break,
        }
    }
}

pub fn process_message(host: &mut impl Runtime, msg: &Message) {
    let _ = (host, msg);
}
