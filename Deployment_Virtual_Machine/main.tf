# Design Decisions applicable: #1575, #1580, #1582, #1583, #1589, #1593, #1598, #3387
# Design Decisions not applicable: #1581, #1584, #1585, #1586, #1590, #1600, #1857

data "azurerm_resource_group" "this" {
  
  name  = var.resource_group_name
}

data azurerm_resources this {
  resource_group_name = var.resource_group_name
}

data "azurerm_storage_account" "this" {
  name                = var.diagnostics_sa_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault" "this" {
  
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault" "ssh" {
  provider            = azurerm.ado
  for_each            = local.use_existing_ssh_key
  name                = var.ssh_key_vault_name
  resource_group_name = var.ssh_key_vault_rg_name
}

data "azurerm_key_vault_secret" "this" {
  provider     = azurerm.ado
  for_each     = local.use_existing_ssh_key
  name         = lookup(each.value, "secret_name_of_public_ssh_key", null)
  key_vault_id = lookup(data.azurerm_key_vault.ssh, each.key)["id"]
}

data "azurerm_backup_policy_vm" "this" {
  for_each            = local.linux_vms_for_backup
  name                = each.value.vm_backup_policy_name
  recovery_vault_name = each.value.recovery_services_vault_name
  resource_group_name = var.resource_group_name
}

# -
# - Get the current user config
# -
data "azurerm_client_config" "current" {}

locals {

   #get list of resources from resource group
  group_resources            = data.azurerm_resources.this.resources

  tags                       = merge(var.vm_additional_tags, data.azurerm_resource_group.this.tags)
  
  des_exists           = { for k, v in var.linux_vms : k => v if lookup(v, "use_existing_disk_encryption_set", false) == true }
  use_existing_ssh_key = { for k, v in var.linux_vms : k => v if lookup(v, "use_existing_ssh_key", false) == true }
  generate_ssh_key     = { for k, v in var.linux_vms : k => v if lookup(v, "use_existing_ssh_key", false) == false }

  key_permissions         = ["get", "wrapkey", "unwrapkey"]
  secret_permissions      = ["get", "set", "list"]
  certificate_permissions = ["get", "create", "update", "list", "import"]
  storage_permissions     = ["get"]

    asg_values 	= {
		for asgi, asgv in local.group_resources : asgi => asgv["name"] if asgv["type"] == "Microsoft.Network/applicationSecurityGroups"
  }
}

#
# Existing DES
#
data "azurerm_disk_encryption_set" "this" {
  for_each            = local.des_exists
  name                = lookup(each.value, "existing_disk_encryption_set_name", null)
  resource_group_name = lookup(each.value, "existing_disk_encryption_set_rg_name", null) == null ? var.resource_group_name : each.value["existing_disk_encryption_set_rg_name"]
}

data "azurerm_application_security_group" "this" {
  for_each            = local.asg_values
  name                = each.value
  resource_group_name = var.resource_group_name
}


# -
# - Generate Private/Public SSH Key for Linux Virtual Machine
# -
resource "tls_private_key" "this" {
  for_each  = local.generate_ssh_key
  algorithm = "RSA"
  rsa_bits  = 2048
}

# -
# - Store Generated Private SSH Key to Key Vault Secrets
# - Design Decision #1582
# -
resource "azurerm_key_vault_secret" "this" {
  for_each     = local.generate_ssh_key
  name         = each.value.name
  value        = lookup(tls_private_key.this, each.key)["private_key_pem"]
  key_vault_id = data.azurerm_key_vault.this.id
}

#
#- Availability Set
#
resource "azurerm_availability_set" "this" {
  for_each                     = var.availability_sets
  name                         = each.value["name"]
  location                     = data.azurerm_resource_group.this.location
  resource_group_name          = var.resource_group_name
  platform_update_domain_count = coalesce(lookup(each.value, "platform_update_domain_count"), 5)
  platform_fault_domain_count  = coalesce(lookup(each.value, "platform_fault_domain_count"), 3)

  tags = local.tags
}

# -
# - Linux Virtual Machine
# -
resource "azurerm_linux_virtual_machine" "linux_vms" {
  for_each            = var.linux_vms
  name                = each.value["name"]
  location            = data.azurerm_resource_group.this.location
  resource_group_name = var.resource_group_name

  network_interface_ids           = [for nic_k, nic_v in azurerm_network_interface.linux_nics : nic_v.id if(contains(each.value["vm_nic_keys"], nic_k) == true)]
  size                            = coalesce(lookup(each.value, "vm_size"), "Standard_DS1_v2")
  zone                            = lookup(each.value, "availability_set_key", null) == null ? lookup(each.value, "zone", null) : null
  availability_set_id             = lookup(each.value, "availability_set_key", null) == null ? null : lookup(azurerm_availability_set.this, each.value["availability_set_key"])["id"]
  disable_password_authentication = coalesce(lookup(each.value, "disable_password_authentication"), true)
  admin_username                  = var.administrator_user_name
  admin_password                  = coalesce(lookup(each.value, "disable_password_authentication"), true) == false ? var.administrator_login_password : null

  dynamic "admin_ssh_key" {
    for_each = coalesce(lookup(each.value, "disable_password_authentication"), true) == true ? [var.administrator_user_name] : []
    content {
      username   = var.administrator_user_name
      public_key = lookup(each.value, "use_existing_ssh_key", false) == true ? lookup(data.azurerm_key_vault_secret.this, each.key)["value"] : lookup(tls_private_key.this, each.key)["public_key_openssh"]
    }
  }

  os_disk {
    name                      = each.value["os_disk_name"]
    caching                   = coalesce(lookup(each.value, "storage_os_disk_caching"), "ReadWrite")
    storage_account_type      = coalesce(lookup(each.value, "managed_disk_type"), "Standard_LRS")
    disk_size_gb              = lookup(each.value, "disk_size_gb", null)
    write_accelerator_enabled = lookup(each.value, "write_accelerator_enabled", null)
    disk_encryption_set_id    = lookup(each.value, "use_existing_disk_encryption_set", false) == true ? lookup(data.azurerm_disk_encryption_set.this, each.key)["id"] : null
  }

  dynamic "source_image_reference" {
    for_each = lookup(local.linux_image_ids, each.value["name"], null) == null ? (lookup(each.value, "source_image_reference_publisher", null) == null ? [] : [lookup(each.value, "source_image_reference_publisher", null)]) : []
    content {
      publisher = lookup(each.value, "source_image_reference_publisher", null)
      offer     = lookup(each.value, "source_image_reference_offer", null)
      sku       = lookup(each.value, "source_image_reference_sku", null)
      version   = lookup(each.value, "source_image_reference_version", null)
    }
  }

  additional_capabilities {
    ultra_ssd_enabled = coalesce(each.value.ultra_ssd_enabled, false)
  }

  computer_name   = each.value["name"]
  custom_data     = lookup(each.value, "custom_data_path", null) == null ? null : (base64encode(templatefile("${path.root}${each.value["custom_data_path"]}", each.value["custom_data_args"] != null ? each.value["custom_data_args"] : {})))
  source_image_id = lookup(local.linux_image_ids, each.value["name"], null)

  boot_diagnostics {
    storage_account_uri = data.azurerm_storage_account.this.primary_blob_endpoint
  }

  # Design Decision #1583
  dynamic "identity" {
    for_each = coalesce(lookup(each.value, "assign_identity"), false) == false ? [] : tolist([coalesce(lookup(each.value, "assign_identity"), false)])
    content {
      type = "SystemAssigned"
    }
  }

  lifecycle {
    ignore_changes = [
      admin_ssh_key,
      network_interface_ids,
      os_disk[0].disk_encryption_set_id
    ]
  }

  tags = local.tags

}

# -
# - Linux Network Interfaces
# -
resource "azurerm_network_interface" "linux_nics" {
  for_each                      = var.linux_vm_nics
  name                          = each.value.name
  location                      = data.azurerm_resource_group.this.location
  resource_group_name           = var.resource_group_name
  internal_dns_name_label       = lookup(each.value, "internal_dns_name_label", null)
  enable_ip_forwarding          = lookup(each.value, "enable_ip_forwarding", null)
  enable_accelerated_networking = lookup(each.value, "enable_accelerated_networking", null)
  dns_servers                   = lookup(each.value, "dns_servers", null)

  dynamic "ip_configuration" {
    for_each = coalesce(each.value.nic_ip_configurations, [])
    content {
      name                          = coalesce(ip_configuration.value.name, format("%s00%d-ip", each.value.name, index(each.value.nic_ip_configurations, ip_configuration.value) + 1))
      subnet_id                     = each.value.subnet_id
      private_ip_address_allocation = lookup(ip_configuration.value, "static_ip", null) == null ? "dynamic" : "static"
      private_ip_address            = lookup(ip_configuration.value, "static_ip", null)
      primary                       = index(each.value.nic_ip_configurations, ip_configuration.value) == 0 ? true : false
    }
  }

  tags = local.tags
}

# -
# - Linux Network Interfaces - Internal Backend Pools Association
# -
locals {
  linux_nics_with_internal_bp_list = flatten([
    for nic_k, nic_v in var.linux_vm_nics : [
      for backend_pool in coalesce(nic_v["lb_backend_pools"], []) :
      {
        key                     = "${nic_k}_${backend_pool.name}"
        nic_key                 = nic_k
        backend_address_pool_id = backend_pool.backend_pool_id
      }
    ]
  ])
  linux_nics_with_internal_bp = {
    for bp in local.linux_nics_with_internal_bp_list : bp.key => bp
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "linux_nics_with_internal_backend_pools" {
  for_each                = local.linux_nics_with_internal_bp
  network_interface_id    = lookup(azurerm_network_interface.linux_nics, each.value["nic_key"]).id
  ip_configuration_name   = lookup(azurerm_network_interface.linux_nics, each.value["nic_key"]).ip_configuration[0].name
  backend_address_pool_id = each.value["backend_address_pool_id"]

  lifecycle {
    ignore_changes = [network_interface_id]
  }

  depends_on = [azurerm_network_interface.linux_nics]
}

#
# Linux Network Interfaces - NAT Rules Association
#
locals {
  linux_nics_with_natrule_list = flatten([
    for nic_k, nic_v in var.linux_vm_nics : [
      for nat_rule in coalesce(nic_v["lb_nat_rules"], []) : [
        for nat_rule_id in([nat_rule.nat_rule_id]) :
        {
          key         = "${nic_k}_${nat_rule_id}"
          nic_key     = nic_k
          nat_rule_id = nat_rule_id
        }
      ]
    ]
  ])
  linux_nics_with_nat_rule = {
    for ntr in local.linux_nics_with_natrule_list : ntr.key => ntr
  }
}

resource "azurerm_network_interface_nat_rule_association" "this" {
  for_each              = local.linux_nics_with_nat_rule
  network_interface_id  = lookup(azurerm_network_interface.linux_nics, each.value["nic_key"]).id
  ip_configuration_name = lookup(azurerm_network_interface.linux_nics, each.value["nic_key"]).ip_configuration[0].name
  nat_rule_id           = each.value["nat_rule_id"]

  lifecycle {
    ignore_changes = [network_interface_id]
  }

  depends_on = [azurerm_network_interface.linux_nics]
}

# -
# - Linux Network Interfaces - Application Security Groups Association
# -
locals {

    app_security_group_ids_map = {
    for asgi, asgv in data.azurerm_application_security_group.this : asgv["name"] => asgv["id"]
  }

  linux_nics_with_asg_list = flatten([
    for nic_k, nic_v in var.linux_vm_nics : [
      for asg_name in coalesce(nic_v["app_security_group_names"], []) :
      {
        key                           = "${nic_k}_${asg_name}"
        nic_key                       = nic_k
        application_security_group_id = lookup(local.app_security_group_ids_map, asg_name, null)
      }
    ]
  ])
  linux_nics_with_asg = {
    for asg in local.linux_nics_with_asg_list : asg.key => asg
  }
}

resource "azurerm_network_interface_application_security_group_association" "this" {
  for_each                      = local.linux_nics_with_asg
  network_interface_id          = lookup(azurerm_network_interface.linux_nics, each.value["nic_key"]).id
  application_security_group_id = each.value["application_security_group_id"]

  lifecycle {
    ignore_changes = [network_interface_id]
  }

  depends_on = [azurerm_network_interface.linux_nics]
}

# -
# - Linux Network Interfaces - Application Gateway's Backend Address Pools Association
# -
locals {


  linux_nics_with_appgw_bp_list = flatten([
    for nic_k, nic_v in var.linux_vm_nics : [
      for backend_pool_name in coalesce(nic_v["app_gateway_backend_pool_names"], []) :
      {
        key                     = "${nic_k}_${backend_pool_name}"
        nic_key                 = nic_k
        backend_address_pool_id = lookup(var.application_gateway_backend_pool_ids_map, backend_pool_name, null)
      }
    ]
  ])
  linux_nics_with_appgw_bp = {
    for bp in local.linux_nics_with_appgw_bp_list : bp.key => bp
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "this" {
  for_each                = local.linux_nics_with_appgw_bp
  network_interface_id    = lookup(azurerm_network_interface.linux_nics, each.value["nic_key"]).id
  ip_configuration_name   = lookup(azurerm_network_interface.linux_nics, each.value["nic_key"]).ip_configuration[0].name
  backend_address_pool_id = each.value["backend_address_pool_id"]

  lifecycle {
    ignore_changes = [network_interface_id]
  }

  depends_on = [azurerm_network_interface.linux_nics]
}

# -
# - Create Key Vault Accesss Policy for VM MSI
# - Design Decision #1598
# -
locals {
  vm_ids_map = {
    for vm in azurerm_linux_virtual_machine.linux_vms :
    vm.name => vm.id
  }

  msi_enabled_linux_vms = [
    for vm_k, vm_v in var.linux_vms :
    vm_v if coalesce(lookup(vm_v, "assign_identity"), false) == true
  ]

  vm_principal_ids = flatten([
    for x in azurerm_linux_virtual_machine.linux_vms :
    [
      for y in x.identity :
      y.principal_id if y.principal_id != ""
    ] if length(keys(azurerm_linux_virtual_machine.linux_vms)) > 0
  ])
}

resource "azurerm_key_vault_access_policy" "this" {
  count        = length(local.msi_enabled_linux_vms)
  key_vault_id = data.azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = element(local.vm_principal_ids, count.index)

  key_permissions         = local.key_permissions
  secret_permissions      = local.secret_permissions
  certificate_permissions = local.certificate_permissions
  storage_permissions     = local.storage_permissions

  depends_on = [azurerm_linux_virtual_machine.linux_vms]
}

# -
# - Azure Backup for an Linux Virtual Machine
# -
locals {
  linux_vms_for_backup = {
    for vm_k, vm_v in var.linux_vms :
    vm_k => vm_v if vm_v.recovery_services_vault_name != null
  }
}

resource "azurerm_backup_protected_vm" "this" {
  for_each            = length(values(local.linux_vms_for_backup)) > 0 ? local.linux_vms_for_backup : {}
  resource_group_name = var.resource_group_name
  recovery_vault_name = each.value["recovery_services_vault_name"]
  source_vm_id        = azurerm_linux_virtual_machine.linux_vms[each.key].id
  backup_policy_id    = lookup(data.azurerm_backup_policy_vm.this, each.key)["id"]
  depends_on          = [azurerm_linux_virtual_machine.linux_vms]
  
  lifecycle {
    prevent_destroy = true
    # ignore_changes = [source_vm_id,
    #                   backup_policy_id]
    # ## these ignore_changes are an alternative approach to the bug where RSV soft-delete causes vm destroy to fail
    # ## this was not chosen because it would mean backup policy cannot be changed via code once deployed
    # ## RSV soft delete is behaving as it should.  The pipeline should fail immediately to alert user
    }
}





######################################################
# Role Assignment
######################################################

# -
# - Assigning Reader Role to VM in order to access KV using MSI Identity
# -
resource "azurerm_role_assignment" "kv" {
  count                            = (var.kv_role_assignment == true && length(local.msi_enabled_linux_vms) > 0) ? length(local.vm_principal_ids) : 0
  scope                            = data.azurerm_key_vault.this.id
  role_definition_name             = "Reader"
  principal_id                     = element(local.vm_principal_ids, count.index)
  skip_service_principal_aad_check = true
}

# -
# - Assigning Reader Role to VM in order to access itself using MSI Identity
# -
resource "azurerm_role_assignment" "vm" {
  count                            = (var.self_role_assignment == true && length(local.msi_enabled_linux_vms) > 0) ? length(local.vm_principal_ids) : 0
  scope                            = lookup(local.vm_ids_map, element(local.msi_enabled_linux_vms, count.index)["name"])
  role_definition_name             = "Reader"
  principal_id                     = element(local.vm_principal_ids, count.index)
  skip_service_principal_aad_check = true
}
