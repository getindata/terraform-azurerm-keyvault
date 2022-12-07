namespace           = "getindata"
stage               = "example"
location            = "West Europe"
resource_group_name = "key-vault"

descriptor_formats = {
  azure-key-vault = {
    labels = ["namespace", "environment", "stage", "name"]
    format = "%v-%v-%v-%v-kv"
  }
  azure-private-link = {
    labels = ["namespace", "environment", "stage", "name"]
    format = "%v-%v-%v-%v-private-link"
  }
}

tags = {
  Terraform = "True"
}
