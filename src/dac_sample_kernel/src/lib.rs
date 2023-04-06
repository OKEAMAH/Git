// src/lib.rs
use tezos_crypto_rs::hash::PublicKeyBls;
use tezos_data_encoding::enc::BinWriter;
use tezos_data_encoding::encoding::HasEncoding;
use tezos_data_encoding::nom::NomReader;
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_encoding::inbox::*;
use tezos_smart_rollup_encoding::michelson::MichelsonUnit;
use tezos_smart_rollup_entrypoint::kernel_entry;
use tezos_smart_rollup_host::runtime::Runtime;
mod dac_message;

#[derive(Debug, PartialEq, HasEncoding, BinWriter, NomReader)]
enum ExternalMessage {
    DAC(dac_message::ParsedDacMessage),
}

#[derive(Debug, PartialEq, HasEncoding, BinWriter, NomReader)]

struct DacContents {
    #[encoding(list, string)]
    message: Vec<String>,
}

fn get_dac_committee() -> Result<Vec<PublicKeyBls>, String> {
    // Assume that we have 2 dac committee members pk stored as raw bytes of CompressedPK.
    // In the future, we probably want to have a bigger dac committee.

    // obtained with {./octez-client bls gen keys alias}: public key hash is "tz4APLQyKZ9PmUnr2CC1DjaMresVTkU7tmVL"
    let pk_0 = PublicKeyBls::from_base58_check(
        "BLpk1tsVzqCokL6dZEiCQgEvwqQp4btiHYm3A1HoEUxKUwq5jCNZMJQ7bU71QE969KioUWCKtK9F",
    )
    .map_err(|e| e.to_string())?;
    //obtained with {./octez-client bls gen keys alias}: public key hash is "tz4T2jr919uQXMuzEsSqSZXS8D2yV25QAheG"
    let pk_1 = PublicKeyBls::from_base58_check(
        "BLpk1xQMdGocMdiiuU2pGvNMeu8vP91nNfrKk5tCssvPzP4z9EY7k5bbEisrqN3pT9vaoN2dsSiW",
    )
    .map_err(|e| e.to_string())?;

    // The order of this Vec is important, as the DAC certificates will refer to the position of
    // the committee member in the below vector to check whether a committee member has signed the certificate.
    // It is extremely important that the Dac committee coordinator configuration file lists the public key hashes
    // of the two committee members in the same order of this rollup kernel. That is, the coordinator configuration
    // file should contain the following line:
    // {committee_members = ["tz4APLQyKZ9PmUnr2CC1DjaMresVTkU7tmVL", "tz4T2jr919uQXMuzEsSqSZXS8D2yV25QAheG"]};
    Ok(vec![pk_0, pk_1])
}

fn process_external(host: &mut impl Runtime, payload: &[u8]) -> Result<(), String> {
    let (_, message) = ExternalMessage::nom_read(payload).map_err(|e| e.to_string())?;
    let ExternalMessage::DAC(dac_message) = message;
    if dac_message.witnesses.0 < 3.into() {
        return Err("Not enough signatures on certificate".to_string());
    }
    let committee = get_dac_committee()?;
    dac_message.verify_signature(committee.as_slice())?;
    let mut payload = Vec::new();
    dac_message
        .reveal_dac_message(host, &mut payload)
        .map_err(|e| e.to_string())?;

    let (_, dac_contents) = DacContents::nom_read(&payload).map_err(|e| e.to_string())?;
    dac_contents
        .message
        .iter()
        .for_each(|msg| debug_msg!(host, "{msg}\n"));
    Ok(())
}

fn process_input<Host: Runtime>(host: &mut Host) {
    let input = host.read_input();
    match input {
        Err(_) | Ok(None) => {}
        Ok(Some(message)) => {
            let _ = host.mark_for_reboot();
            let payload: &[u8] = message.as_ref();
            let message = InboxMessage::<MichelsonUnit>::parse(payload);
            match message {
                Ok((_, InboxMessage::Internal(internal))) => {
                    debug_msg!(host, "Internal message: {}", internal);
                }
                Ok((_, InboxMessage::External(external))) => {
                    host.write_debug("Checking if the message is a valid DAC certificate\n");
                    if let Err(e) = process_external(host, external) {
                        debug_msg!(host, "{e:?}\n");
                    };
                }
                _ => {
                    host.write_debug("The message has not been recognised and will be ignore\n");
                }
            }
        }
    }
}

// src/lib.rs
pub fn entry<Host: Runtime>(host: &mut Host) {
    host.write_debug("Hello Kernel\n");
    process_input(host);
}

kernel_entry!(entry);
