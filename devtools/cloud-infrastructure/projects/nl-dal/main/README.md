# Deploy to Google Cloud VM

Terraform for deploying docker images to the Google Cloud VM.

## Prerequisite

### Add your SSH key to the docker image

Follow `../prerequisite/docker/README.md`.

### Create a Google Cloud Storage bucket for storing your terraform state

Follow `../prerequisite/state-storage-bucket/README.md`.

## How to Use

First, initialize terraform using the bucket you created in the previous section. This can be done by running the below command using the same `<name>` you used in `../prerequisite/state-storage-bucket/README.md`.

```shell
terraform init -backend-config="bucket=<name>-tfstate" -backend-config="prefix=<name>"
```

Run terraform plan and check the execution plan. You can use any string as `<hostname>`. However, to avoid conflicts with others, it's advisable to use a unique identifier such as your `<name>`.

```shell
terraform plan --var hostname="<hostname>"
```

If the plan looks good, apply the change.

```shell
terraform apply --var hostname="<hostname>"
```

Do not forget to destroy the deployed VM once you are finished with your testing.

```shell
terraform destroy --var hostname="<hostname>"
```
