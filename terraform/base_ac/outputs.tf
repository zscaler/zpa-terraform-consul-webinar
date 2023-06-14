locals {

  testbedconfig = <<TB

1) Copy the SSH key to the Consul Server host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.consul_server.public_dns}:/home/ubuntu/.

2) SSH to the Consul Server
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.consul_server.public_dns}

3) HTTP Access to Consul Server UI
"http://${module.consul_server.public_dns}:8500"

4) HTTP Access to Vault Server UI
"http://${module.consul_server.public_dns}:8200"

5) Vault Server Public IP (Configure in CTS)
export VAULT_ADDR="http://${module.consul_server.public_dns}:8200"

6) Vault Server Internal IP (Configure in CTS)
export VAULT_ADDR="http://${module.consul_server.private_ip}:8200"

7) Executing Consul-Terraform-Sync (CTS Automation)
cd ../../zpa_nia/example/
consul-terraform-sync start -config-file config.hcl

8) KMS ID Output
${join("\n", aws_kms_key.vault_kms_key[*].key_id)}

ZPA App Connector Group Name (Use in CTS Module)
${join("\n", module.zpa_app_connector_group[*].app_connector_group_name)}

ZPA Server Group Name (Use in CTS Module)
${join("\n", module.zpa_server_group[*].server_group_name)}

ZPA Segment Group Name (Use in CTS Module)
${zpa_segment_group.segment_group.name}

4) SSH to the App Connector
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.ac_vm.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ec2-user@${module.consul_server.public_dns}"

All AC Private IPs. Replace private IP below with ec2-user@"ip address" in ssh example command above. ec2-user@"ip address" for AL2 AMI deployments
${join("\n", module.ac_vm.private_ip)}

TB
}

output "testbedconfig" {
  description = "AWS Testbed results"
  value       = local.testbedconfig
}

resource "local_file" "testbed" {
  content  = local.testbedconfig
  filename = "../testbed.txt"
}
