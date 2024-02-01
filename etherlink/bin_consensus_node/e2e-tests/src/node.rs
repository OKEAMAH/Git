// SPDX-FileCopyrightText: 2024 Madara contributors
// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use dsn_rpc::{proto::dsn_client::DsnClient, DEFAULT_RPC_SERVER_PORT};
use log::error;
use std::{
    env,
    fs::{create_dir_all, File},
    net::TcpListener,
    path::{Path, PathBuf},
    process::{Child, Command, ExitStatus, Stdio},
    str::FromStr,
    time::Duration,
};
use tonic::transport::{Channel, Uri};

const MIN_PORT: u16 = 49_152;
const MAX_PORT: u16 = 65_535;

#[derive(Debug)]
/// A wrapper over the DSN node process handle
///
/// When this struct goes out of scope, it's `Drop` impl
/// will take care of killing the DSN node process.
pub struct DsnNode {
    process: Child,
    port: u16,
}

impl Drop for DsnNode {
    fn drop(&mut self) {
        let mut kill = Command::new("kill")
            .args(["-s", "TERM", &self.process.id().to_string()])
            .spawn()
            .expect("Failed to kill");
        kill.wait().expect("Failed to kill the process");
    }
}

fn get_free_port() -> u16 {
    for port in MIN_PORT..=MAX_PORT {
        if let Ok(listener) = TcpListener::bind(("127.0.0.1", port)) {
            return listener.local_addr().expect("No local addr").port();
        }
        // otherwise port is occupied
    }
    panic!("No free ports available");
}

fn get_repository_root() -> PathBuf {
    let manifest_path = Path::new(&env!("CARGO_MANIFEST_DIR"));
    let repository_root = manifest_path
        .parent()
        .expect("Failed to get parent directory of CARGO_MANIFEST_DIR");
    repository_root.to_path_buf()
}

impl DsnNode {
    fn cargo_run(root_dir: &Path, params: Vec<&str>) -> Child {
        let arguments = [vec!["run", "--release", "--"], params].concat();

        let logs_dir = Path::join(root_dir, Path::new("target/dsn-node-logs"));
        create_dir_all(logs_dir.clone()).expect("Failed to create logs dir");

        let stdout =
            Stdio::from(File::create(Path::join(&logs_dir, Path::new("stdout.txt"))).unwrap());
        let stderr =
            Stdio::from(File::create(Path::join(&logs_dir, Path::new("stderr.txt"))).unwrap());

        Command::new("cargo")
            .stdout(stdout)
            .stderr(stderr)
            .args(arguments)
            .spawn()
            .expect("Could not run DSN node")
    }

    pub fn run() -> Self {
        let port = DEFAULT_RPC_SERVER_PORT; // get_free_port();
        let repository_root = &get_repository_root();

        std::env::set_current_dir(repository_root).expect("Failed to change working directory");

        let params = vec![];
        let process = Self::cargo_run(repository_root.as_path(), params);

        Self { process, port }
    }

    pub fn endpoint(&self) -> Uri {
        Uri::from_str(&format!("http://127.0.0.1:{}", self.port)).unwrap()
    }

    pub fn has_exited(&mut self) -> Option<ExitStatus> {
        self.process
            .try_wait()
            .expect("Failed to get DSN node exit status")
    }

    pub async fn connect(&mut self) -> DsnClient<Channel> {
        let mut attempts = 120;
        loop {
            match DsnClient::connect(self.endpoint().clone()).await {
                Ok(client) => return client,
                Err(err) => {
                    if let Some(status) = self.has_exited() {
                        panic!("DSN node exited early with {}", status);
                    }
                    if attempts == 0 {
                        panic!(
                            "Failed to connect to {}: {}",
                            self.endpoint(),
                            err.to_string()
                        );
                    }
                }
            };

            attempts -= 1;
            tokio::time::sleep(Duration::from_millis(500)).await;
        }
    }
}
