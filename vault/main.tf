# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_mount" "zscaler" {
  path        = "zscaler"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 1 secret engine mount"
}

# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_kv_secret_v2" "zpacloudprod" {
  mount = vault_mount.zscaler.path
  name = "zpacloudprod"
  delete_all_versions = true
  data_json = jsonencode(
  {
    client_id = "",
    client_secret = "",
    customer_id = ""
  }
  )
}

# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_kv_secret_v2" "zpacloudprod_bdsa" {
  mount = vault_mount.zscaler.path
  name = "zpacloudprod_bdsa"
  delete_all_versions = true
  data_json = jsonencode(
  {
    client_id = "",
    client_secret = "",
    customer_id = ""
  }
  )
}

# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_kv_secret_v2" "zpacloudbeta" {
  mount = vault_mount.zscaler.path
  name = "zpacloudbeta"
  delete_all_versions = true
  data_json = jsonencode(
  {
    client_id = "",
    client_secret = "",
    customer_id = "",
    zpa_cloud = "BETA"
  }
  )
}

# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_kv_secret_v2" "zpacloudpreview" {
  mount = vault_mount.zscaler.path
  name = "zpacloudpreview"
  delete_all_versions = true
  data_json = jsonencode(
  {
    client_id = "",
    client_secret = "",
    customer_id = "",
    zpa_cloud = "PREVIEW"
  }
  )
}

# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_kv_secret_v2" "zpacloud_dev_shard2_01" {
  mount = vault_mount.zscaler.path
  name = "zpacloud_dev_shard2_01"
  delete_all_versions = true
  data_json = jsonencode(
  {
    client_id = "",
    client_secret = "",
    customer_id = "",
    zpa_cloud = "DEV"
  }
  )
}

# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_kv_secret_v2" "zpacloud_dev_shard2_02" {
  mount = vault_mount.zscaler.path
  name = "zpacloud_dev_shard2_02"
  delete_all_versions = true
  data_json = jsonencode(
  {
    client_id = "",
    client_secret = "",
    customer_id = "",
    zpa_cloud = "DEV"
  }
  )
}

# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_kv_secret_v2" "zpacloud_dev_shard3_01" {
  mount = vault_mount.zscaler.path
  name = "zpacloud_dev_shard3_01"
  delete_all_versions = true
  data_json = jsonencode(
  {
    client_id = "",
    client_secret = "",
    customer_id = "",
    zpa_cloud = "DEV"
  }
  )
}

# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_kv_secret_v2" "zpacloud_dev_shard3_02" {
  mount = vault_mount.zscaler.path
  name = "zpacloud_dev_shard3_01"
  delete_all_versions = true
  data_json = jsonencode(
  {
    client_id = "",
    client_secret = "",
    customer_id = "",
    zpa_cloud = "DEV"
  }
  )
}

# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_kv_secret_v2" "ziacloudprod" {
  mount = vault_mount.zscaler.path
  name = "ziacloudprod"
  delete_all_versions = true
  data_json = jsonencode(
  {
    username = "",
    password = "",
    api_key = "",
    zia_cloud = "zscalerthree"
  }
  )
}

# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_kv_secret_v2" "ziacloudprod_bdsa" {
  mount = vault_mount.zscaler.path
  name = "ziacloudprod_bdsa"
  delete_all_versions = true
  data_json = jsonencode(
  {
    username = "",
    password = "",
    api_key = "",
    zia_cloud = "zscalertwo"
  }
  )
}

# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!
resource "vault_kv_secret_v2" "ziacloudbeta" {
  mount = vault_mount.zscaler.path
  name = "ziacloudbeta"
  delete_all_versions = true
  data_json = jsonencode(
  {
    username = "",
    password = "",
    api_key = "",
    zia_cloud = "zspreview"
  }
  )
}
# THE CREDENTIALS IN THIS FILE ARE FAKE AND NOT USED IN ANY PRODUCTION OR DEVELOPMENT ENVIRONMENT ARE SET AS EXAMPLES ONLY !!!!