# State storage bucket

Terraform code for creating a Google Cloud Storage bucket for storing terraform state.
You only need to run this once at your initial setup.

## How to Use

```shell
terraform init
terraform plan --var project="NL-dal" --var region="europe-west1" --var name="<your-name>"
terraform apply --var project="NL-dal" --var region="europe-west1" --var name="<your-name>"
```

For example:

```shell
terraform init
terraform plan --var project="NL-dal" --var region="europe-west1" --var name="lin"
terraform apply --var project="NL-dal" --var region="europe-west1" --var name="lin"
```

Remember what you used of `<your-name>` as it will be needed in subsequent steps.
