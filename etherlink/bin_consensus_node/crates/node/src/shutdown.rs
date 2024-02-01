// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Graceful shutdown helper.

use log::info;
use tokio::{
    signal::unix::{signal, SignalKind},
    sync::broadcast,
};

pub struct Shutdown {
    tx_shutdown: broadcast::Sender<()>,
}

impl Shutdown {
    pub fn new() -> Self {
        let (tx_shutdown, _) = broadcast::channel(1);
        Self { tx_shutdown }
    }

    pub fn subscribe(&self) -> broadcast::Receiver<()> {
        self.tx_shutdown.subscribe()
    }

    pub async fn run(&self) -> Result<(), ()> {
        let mut sigterm = signal(SignalKind::terminate()).unwrap();
        let mut sigint = signal(SignalKind::interrupt()).unwrap();

        loop {
            tokio::select! {
                _ = sigterm.recv() => info!("Received SIGTERM, initiating shutdown..."),
                _ = sigint.recv() => info!("Received SIGINT, initiating shutdown..."),
            };
            return self.tx_shutdown.send(()).map(|_| ()).map_err(|_| ());
        }
    }
}
