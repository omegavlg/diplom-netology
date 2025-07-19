resource "yandex_storage_bucket" "tf_bucket" {
  bucket     = "netology-dedyurin"
  access_key = var.access_key
  secret_key = var.secret_key
  acl        = "public-read"
}