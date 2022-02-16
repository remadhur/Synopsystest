resource_group_name = "[__resource_group_name__]"

linux_vms = {
  vm1 = {
    name                                 = "jstartvm09282021"
    vm_size                              = "Standard_DS1_v2"
    assign_identity                      = true
    availability_set_key                 = null
    vm_nic_keys                          = ["nic2"]
    zone                                 = "1"
    disable_password_authentication      = true
    source_image_reference_offer         = "UbuntuServer" # set this to null if you are  using image id from shared image gallery or if you are passing image id to the VM through packer
    source_image_reference_publisher     = "Canonical"    # set this to null if you are  using image id from shared image gallery or if you are passing image id to the VM through packer  
    source_image_reference_sku           = "12.04.3-LTS" #"18.04-LTS"    # set this to null if you are using image id from shared image gallery or if you are passing image id to the VM through packer 
    source_image_reference_version       = "12.04.201401270"       # set this to null if you are using image id from shared image gallery or if you are passing image id to the VM through packer             
    os_disk_name                         = "osdisklin09282021-linux"
    storage_os_disk_caching              = "ReadWrite"
    managed_disk_type                    = "Premium_LRS"
    disk_size_gb                         = null
    write_accelerator_enabled            = null
    recovery_services_vault_name         = null #"tfex-recovery-vault"
    vm_backup_policy_name                = null #"tfex-recovery-vault-policy"
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
    subnet_id = "/subscriptions/[__subscription_id__]/resourceGroups/[__networking_resource_group_name__]/providers/Microsoft.Network/virtualNetworks/[__virtual_network_name__]/subnets/proxy"
    lb_nat_rules                   = null # provide the name and resource IDs of the NAT rules
    app_security_group_names       = null
    app_gateway_backend_pool_names = null
    internal_dns_name_label        = null
    enable_ip_forwarding           = null # set it to true if you want to enable IP forwarding on the NIC
    enable_accelerated_networking  = null # set it to true if you want to enable accelerated networking
    dns_servers                    = null
    lb_backend_pools = [
      {
        name            = "jstartvmlbbackend"
        backend_pool_id = "/subscriptions/9e9d8a58-6c9b-4cdb-8a7b-6450e36a6f51/resourceGroups/[__resource_group_name__]/providers/Microsoft.Network/loadBalancers/jstartvmlb1/backendAddressPools/jstartvmlbbackend"
      }
    ]
    nic_ip_configurations = [
      {
        static_ip = null
        name      = "ip-config-first"
      },
      {
        static_ip = null
        name      = "ip-config-second"
      }
    ]
  },
  nic2 = {
    name      = "jstartvm02-nic2"
    subnet_id = "/subscriptions/[__subscription_id__]/resourceGroups/[__networking_resource_group_name__]/providers/Microsoft.Network/virtualNetworks/[__virtual_network_name__]/subnets/proxy"
    lb_nat_rules                   = null # provide the name and resource IDs of the NAT rules
    app_security_group_names       = null
    app_gateway_backend_pool_names = null
    internal_dns_name_label        = null
    enable_ip_forwarding           = null # set it to true if you want to enable IP forwarding on the NIC
    enable_accelerated_networking  = null # set it to true if you want to enable accelerated networking
    dns_servers                    = null
    lb_backend_pools = [
      {
        name            = "jstartvmlbbackend"
        backend_pool_id = "/subscriptions/9e9d8a58-6c9b-4cdb-8a7b-6450e36a6f51/resourceGroups/[__resource_group_name__]/providers/Microsoft.Network/loadBalancers/jstartvmlb1/backendAddressPools/jstartvmlbbackend"
      }
    ]
    nic_ip_configurations = [
      {
        static_ip = null
        name      = "ip-config-first"
      },
      {
        static_ip = null
        name      = "ip-config-second"
      }
    ]
  },
}

administrator_user_name      = "demo"
administrator_login_password = null

diagnostics_sa_name = "[__storage_account_name__]"
key_vault_name      = "[__key_vault_name__]"

# Existing SSH Keys
ssh_key_vault_name    = "[__ado_key_vault_name__]"      # name of the key vault where public ssh key is stored
ssh_key_vault_rg_name = "[__ado_resource_group_name__]" # rg name of the key vault where public ssh key is stored
ado_subscription_id   = "[__ado_subscription_id__]"

vm_additional_tags = {
  iac            = "Terraform"
  env            = "uat"
  automated_by   = ""
  monitor_enable = true
}

application_gateway_backend_pool_ids_map = {
  "appgateway-beap" = "/subscriptions/[__subscription_id__]/resourceGroups/[__resource_group_name__]/providers/Microsoft.Network/applicationGateways/jstartall09212021tgw/backendAddressPools/appgateway-beap",
}
