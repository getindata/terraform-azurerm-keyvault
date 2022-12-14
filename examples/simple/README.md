# Complete Example

```terraform
module "resource_group" {
  source  = "github.com/getindata/terraform-azurerm-resource-group?ref=v1.2.0"
  context = module.this.context

  name     = var.resource_group_name
  location = var.location
}

module "key_vault" {
  source = "../../"
  context = module.this.context

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
}
```

## Usage

```
terraform init
terraform plan -var-file fixtures.west-europe.tfvars -out tf.plan
terraform apply tf.plan
```
