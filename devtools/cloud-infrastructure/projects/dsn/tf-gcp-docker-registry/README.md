# GCP docker registry to keep docker images

Create a docker image registry in europe region (multiregion) to store docker images.

## Requirements

- GCP account access with good rights
- gcloud version ~> 440.0.0
- terraform version ~> 1.0

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

## Variables

| Name       | Description                                      | Type     | Default         | Required |
|------------|--------------------------------------------------|----------|-----------------|:--------:|
| project_id | The GCP project ID                               | `string` | "dsn-benchmark" |   yes    |
| region     | The GCP region where the docker registry resides | `string` | "europe"        |   yes    |
