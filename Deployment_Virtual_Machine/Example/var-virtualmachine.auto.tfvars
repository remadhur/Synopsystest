resource_group_name = "Terraformpractice"
key_vault_name      = "avtest03"

linux_vms = {
  vm1 = {
    name                                 = "jstartvm0235"
    vm_size                              = "Standard_D2s_v3"
    assign_identity                      = true
    availability_set_key                 = null
    vm_nic_keys                          = ["nic1"]
    zone                                 = null
    disable_password_authentication      = true
    source_image_reference_offer         = "UbuntuServer" # set this to null if you are  using image id from shared image gallery or if you are passing image id to the VM through packer
    source_image_reference_publisher     = "Canonical"    # set this to null if you are  using image id from shared image gallery or if you are passing image id to the VM through packer  
    source_image_reference_sku           = "18.04-LTS" #"18.04-LTS"    # set this to null if you are using image id from shared image gallery or if you are passing image id to the VM through packer 
    source_image_reference_version       = "latest"# set this to null if you are using image id from shared image gallery or if you are passing image id to the VM through packer             
    os_disk_name                         = "osdisklin0928-linux"
    storage_os_disk_caching              = "ReadWrite"
    managed_disk_type                    = "Premium_LRS"
    disk_size_gb                         = null
    write_accelerator_enabled            = null
    recovery_services_vault_name         = "samplersv" #"tfex-recovery-vault"
    vm_backup_policy_name                = "DefaultPolicy" #"tfex-recovery-vault-policy"
    ultra_ssd_enabled                    = false
    use_existing_ssh_key                 = false # set it to true if you want to use existing public ssh key
    secret_name_of_public_ssh_key        = null  # key vault secret name of existing public ssh key          # set it to true if you want to enable disk encryption using customer managed key
    use_existing_disk_encryption_set     = false
    existing_disk_encryption_set_name    = null
    existing_disk_encryption_set_rg_name = null
    custom_data_path                     = null #"//CustomData.tpl" # Optional
    custom_data_args                     = null #"{ name = "VMandVM", destination = "EASTUS2", version = "1.0" }
  }
}

linux_vm_nics = {
  nic1 = {
    name      = "jstartvm01-nic1"
    subnet_id = "/subscriptions/4ce5dc2e-0f88-46c6-873f-d1ebe23a9e07/resourceGroups/Terraformpractice/providers/Microsoft.Network/virtualNetworks/Terraformpractice-vnet/subnets/default"
    lb_nat_rules                   = null # provide the name and resource IDs of the NAT rules
    app_security_group_names       = null
    app_gateway_backend_pool_names = null
    internal_dns_name_label        = null
    enable_ip_forwarding           = null # set it to true if you want to enable IP forwarding on the NIC
    enable_accelerated_networking  = null # set it to true if you want to enable accelerated networking
    dns_servers                    = null
    lb_backend_pools               = null
    nic_ip_configurations = [
      {
        static_ip = null
        name      = "ip-config-first"
      }
    ]
  }
}

administrator_user_name      = "demouser"
administrator_login_password = null

diagnostics_sa_name = "terraformstatesaas"

# Existing SSH Keys
ssh_key_vault_name    =  null     # name of the key vault where public ssh key is stored
ssh_key_vault_rg_name =  null # rg name of the key vault where public ssh key is stored
ado_subscription_id   = null

vm_additional_tags = {
  iac            = "Terraform"
  env            = "uat"
  automated_by   = ""
  monitor_enable = true
}

application_gateway_backend_pool_ids_map =null