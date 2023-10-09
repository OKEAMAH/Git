# Simple server deployment running on COS with static IPs

Create a compute instance running on COS with static public and private IPs on provided networks.
If the network (and subnetwork) are not provided, the deployment will generate one.
A startup script is provided and will run at boot.

## Usage

For developers:

```sh
make format
make lint
```

For the deployment:

```sh
make init
make plan
make apply
```

To destroy the deployment:

```sh
terraform destroy
```

## Variables

| Name                        | Description                                                                                                                                            | Type           | Default         | Required |
|-----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|----------------|-----------------|:--------:|
| project_id                  | The GCP project ID                                                                                                                                     | `string`       | "nl-dal"        |   yes    |
| region                      | The GCP region where the VM is deployed.                                                                                                               | `string`       | ""              |   yes    |
| zone"                       | (optional) The zone where the VM is deployed (if leave empty, will use the location of the cluster deployed if exists; if not use \"europe-west1-b\"). | `string`       | ""              |    no    |
| network                     | (optional) The network (VPC) used by the VM (if leave empty, will deploy its own network (VPC)).                                                       | `string`       | ""              |    no    |
| subnetwork                  | (optional) The subnetwork used by the VM (if leave empty, will deploy its own subnetwork (VPC)).                                                       | `string`       | ""              |    no    |
| firewall_source_ranges      | List of IP CIDR ranges for the firewall, defaults to 0.0.0.0/0.                                                                                        | `list(string)` | ["0.0.0.0/0"]   |    no    |
| firewall_opened_ports_range | List of ports to be opened for the firewall, defaults to 50000-51000                                                                                   | `list(string)` | ["50000-51000"] |   yes    |
