# Create Linux Virtual Machines in Azure

This layer allows you to create one or multiple Linux Virtual Machines in Azure.

## Features

1.  Create one or multiple Linux Virtual Machines in an existing resource group.
2.  Create public and private ssh key for login and store them in Key Vault.
3.  Allows to create additional data disks for Linux Virtual Machine.
4.  Encrypt OS disks using disk Encryption set
5.  Add Linux Virtual Machines to the backend pools of LB.
6.  Associate Application Security Groups to Linux Virtual Machine.
7.  Enable MSI on Linux Virtual Machine and create Key Vault Access Policy for VM Principal Id.
8.  Enables Backup to Recovery Services Vault for Linux Virtual Machine.

## Example of Layer Consumption

```yaml
- name: virtualmachine
  type: virtualmachine
  version: "2.7.0"
  skip: false
  destroy: false
  dependencies:
    loadbalancer: loadbalancer
    storage: storage
    keyvault: keyvault
    adoprivateendpoints: adoprivateendpoints
    applicationgateway: applicationgateway
    recoveryservicesvault: recoveryservicesvault
    applicationsecuritygroup: applicationsecuritygroup
    diskencryptionset: diskencryptionset
```

## Example

Please refer Example directory to consume this layer into your application.

- [var-virtualmachine.tf](./var-virtualmachine.tf) contains declaration and definition of terraform `linux_image_ids` variable which is passed to the Virtual Machine layer.
- [var-virtualmachine.auto.tfvars](./var-virtualmachine.auto.tfvars) contains the variable definition or actual values for respective variables which are passed to the Virtual Machine layer.

## Best practices for variable declarations

1.  All names of the Resources should be defined as per AT&T standard naming conventions.
2.  While declaring variables with data type 'map(object)', it's mandatory to define all the objects. If you don't want to use any specific objects define it as null or empty list as per the object data type.

    - for example:

    ```hcl
     variable "example" {
       type = map(object({
         name         = string
         permissions  = list(string)
         cmk_enable   = bool
         auto_scaling = string
     }))
    ```

    - In above example, if you don't want to use the objects permissions and auto_scaling, you can define it as below.

    ```hcl
     example = {
       name         = "example"
       permissions  = []
       cmk_enable   = true
       auto_scaling = null
    }
    ```

3.  Please make sure all the Required parameters are declared.Refer below section to understand the required and optional parameters of this layer.

4.  Please verify that the values provided to the variables are with in the allowed values.Refer below section to understand the allowed values to each parameter.

## Inputs

### **Required Parameters**

These variables must be set in the `/Layers/<env>/var-virtualmachine.auto.tfvars` file when using this layer.

#### resource_group_name `string`

    Description: Specifies the name of the resource group in which to create the Virtual Machines.

#### linux_vms `map(object({}))`

    Description: Specifies the Map of objects containing attributes for Virtual Machines.

| Attribute                            |  Data Type   | Field Type | Description                                                                                                                                | Allowed Values                                           |
| :----------------------------------- | :----------: | :--------: | :----------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------- |
| name                                 |    string    |  Required  | The name of the Linux Virtual Machine. Changing this forces a new resource to be created.                                                  |                                                          |
| vm_size                              |    string    |  Required  | The SKU which should be used for this Virtual Machine, such as Standard_F2.                                                                |                                                          |
| zone                                 |    string    |  Optional  | The Zone in which this Virtual Machine should be created. Changing this forces a new resource to be created.                               |                                                          |
| assign_identity                      |     bool     |  Optional  | Specifies whether to enable Managed System Identity for the Virtual Machine. Defaults to true.                                             | true, false                                              |
| availability_set_key                 |    string    |  Optional  | key name of the availability set                                                                                                           |                                                          |
| vm_nic_keys                          | list(string) |  Optional  | Specifies the list of NIC key names which should be associated to the VM                                                                   |                                                          |
| lb_backend_pool_names                | list(string) |  Optional  | Specifies the list of Load Balancer Backend Pool Names which this VM Network Interface should be connected to.                             |                                                          |
| lb_nat_rule_names                    | list(string) |  Optional  | Specifies the list of Load Balancer NAT rule Names which this VM Network Interface should be connected to.                                 |                                                          |
| app_security_group_names             | list(string) |  Optional  | Specifies the list of Application Security Group Names which this VM Network Interface should be connected to.                             |                                                          |
| app_gateway_name                     |    string    |  Optional  | Specifies the Application Gateway Name which this VM Network Interface should be connected to.                                             |                                                          |
| disable_password_authentication      |     bool     |  Optional  | Should Password Authentication be disabled on this Virtual Machine? Defaults to true.                                                      | true, false                                              |
| source_image_reference_publisher     |    string    |  Optional  | Specifies the publisher of the image used to create the virtual machines.                                                                  |                                                          |
| source_image_reference_offer         |    string    |  Optional  | Specifies the offer of the image used to create the virtual machines.                                                                      |                                                          |
| source_image_reference_sku           |    string    |  Optional  | Specifies the SKU of the image used to create the virtual machines.                                                                        |                                                          |
| source_image_reference_version       |    string    |  Optional  | Specifies the version of the image used to create the virtual machines.                                                                    |                                                          |
| storage_os_disk_caching              |    string    |  Optional  | The Type of Caching which should be used for the Internal OS Disk.                                                                         | None, ReadOnly and ReadWrite                             |
| os_disk_name                         |    string    |  Required  | Specifies the name of the OS Disk attched to Linux VM.                                                                                     |                                                          |
| managed_disk_type                    |    string    |  Optional  | The Type of Storage Account which should back this the Internal OS Disk.                                                                   | Standard_LRS, StandardSSD_LRS, Premium_LRS, UltraSSD_LRS |
| disk_size_gb                         |    number    |  Optional  | The Size of the Internal OS Disk in GB, if you wish to vary from the size used in the image this Virtual Machine is sourced from.          |                                                          |
| write_accelerator_enabled            |     bool     |  Optional  | Should Write Accelerator be Enabled for this OS Disk? Defaults to false.                                                                   | true, false                                              |
| use_existing_disk_encryption_set     |     bool     |  Optional  | Specifies whether to use existing disk encryption set, set this as false when you set enable_cmk_disk_encryption to true                   | true, false                                              |
| existing_disk_encryption_set_name    |    string    |  Optional  | Name of the existing disk encryption set                                                                                                   | NA                                                       |
| existing_disk_encryption_set_rg_name |    string    |  Optional  | Name of the existing disk encryption set rg name                                                                                           | NA                                                       |
| use_existing_ssh_key                 |     bool     |  Optional  | want to use existing ssh public key?                                                                                                       | NA                                                       |
| secret_name_of_public_ssh_key        |    string    |  Optional  | key vault secret name where existing public ssh key is stored                                                                              | NA                                                       |
| recovery_services_vault_name         |    string    |  Optional  | Specifies the Recovery Servie Vault name to be used for VM Backup.                                                                         |                                                          |
| vm_backup_policy_name                |    string    |  Optional  | Specifies the name of the backup policy to be used for VM Backup.                                                                          |                                                          |
| ultra_ssd_enabled                    |     bool     |  Optional  | Should the capacity to enable Data Disks of the UltraSSD_LRS storage account type be supported on this Virtual Machine? Defaults to false. | true, false                                              |
| custom_data_path                     |    string    |  Optional  | Specifies the External Path for custom data script file.                                                                                   |                                                          |
| custom_data_args                     | map(string)  |  Optional  | Specifies the arguments passed to the custom data script file.                                                                             |                                                          |

#### linux_vm_nics `map(object({}))`

    Description: Specifies the Map of objects containing attributes for Virtual Machine NIC's.

| Attribute                     |    Data Type     | Field Type | Description                                                                                                    | Allowed Values |
| :---------------------------- | :--------------: | :--------: | :------------------------------------------------------------------------------------------------------------- | :------------- |
| name                          |      string      |  Required  | Name of the Network interface                                                                                  |                |
| subnet_name                   |      string      |  Optional  | Specifies the Name of the Subnet in which Virtual Machine should be deployed.                                  |                |
| vnet_name                     |      string      |  Optional  | Specifies the Name of the VNet in which Virtual Machine should be deployed.                                    |                |
| networking_resource_group     |      string      |  Optional  | Specifies the Name of the Resource Group for the Virtual Network / Subnet used in NIC.                         |                |
| internal_dns_name_label       |      string      |  Optional  | The (relative) DNS Name used for internal communications between Virtual Machines in the same Virtual Network. |                |
| enable_ip_forwarding          |       bool       |  Optional  | Should IP Forwarding be enabled? Defaults to false.                                                            | true, false    |
| enable_accelerated_networking |       bool       |  Optional  | Should Accelerated Networking be enabled? Defaults to false.                                                   | true, false    |
| dns_servers                   |   list(string)   |  Optional  | A list of IP Addresses defining the DNS Servers which should be used for this Network Interface.               |                |
| nic_ip_configurations         | list(object({})) |  Required  | Specifies one or more `ip_configuration` blocks as defined below.                                              |                |

#### ip_configuration

| Attribute | Data Type | Field Type | Description                                         | Allowed Values |
| :-------- | :-------: | :--------: | :-------------------------------------------------- | :------------- |
| name      |  string   |  Required  | Specifies the name used for this IP Configuration.  |                |
| static_ip |  string   |  Optional  | The Static Private IP Address which should be used. |                |

#### diagnostics_sa_name `string`

    Description: storage account name where the diagnostic logs will be stored.

#### administrator_user_name `string`

    Description: Specifies the username of the local administrator used for the Virtual Machine. Changing this forces a new resource to be created.

### **Optional Parameters**

#### availability_sets `map(object({}))`

    Description: Specifies the Map of objects containing attributes for availability set.

| Attribute                    | Data Type | Field Type | Description                                           | Allowed Values |
| :--------------------------- | :-------: | :--------: | :---------------------------------------------------- | :------------- |
| name                         |  string   |  Required  | The name of the availability set                      |                |
| platform_update_domain_count |  number   |  optional  | Specifies the number of update domains that are used. |                |
| platform_fault_domain_count  |  number   |  optional  | Specifies the number of fault domains that are used.  |                |

#### administrator_login_password `string`

    Description: Specifies the password of the local administrator used for the Virtual Machine. Changing this forces a new resource to be created.

#### vm_additional_tags `map(string)`

    Description: A mapping of tags to assign to the resource. Specifies additional Virtual Machine resources tags, in addition to the resource group tags.

    Default: {
        monitor_enable = true
    }


## Outputs

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Reference

[azurerm_linux_virtual_machine](https://www.terraform.io/docs/providers/azurerm/r/linux_virtual_machine.html) <br />
[azurerm_storage_account](https://www.terraform.io/docs/providers/azurerm/r/storage_account.html) <br />
[azurerm_key_vault_key](https://www.terraform.io/docs/providers/azurerm/r/key_vault_key.html) <br />
[azurerm_key_vault_secret](https://www.terraform.io/docs/providers/azurerm/r/key_vault_secret.html) <br />
[azurerm_key_vault_access_policy](https://www.terraform.io/docs/providers/azurerm/r/key_vault_access_policy.html) <br />
[azurerm_disk_encryption_set](https://www.terraform.io/docs/providers/azurerm/r/disk_encryption_set.html) <br />
[azurerm_role_assignment](https://www.terraform.io/docs/providers/azurerm/r/role_assignment.html) <br />
[azurerm_network_interface](https://www.terraform.io/docs/providers/azurerm/r/network_interface.html) <br />
[azurerm_network_interface_backend_address_pool_association](https://www.terraform.io/docs/providers/azurerm/r/network_interface_backend_address_pool_association.html) <br />
[azurerm_network_interface_application_security_group_association](https://www.terraform.io/docs/providers/azurerm/r/network_interface_application_security_group_association.html) <br />
[azurerm_backup_protected_vm](azurerm_backup_protected_vm) <br />
[azurerm_managed_disk](https://www.terraform.io/docs/providers/azurerm/r/managed_disk.html) <br />
[azurerm_virtual_machine_data_disk_attachment](https://www.terraform.io/docs/providers/azurerm/r/virtual_machine_data_disk_attachment.html) <br />
