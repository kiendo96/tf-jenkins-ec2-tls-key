terraform {
  backend "s3" {
    bucket         = "tf-bucket-kiendt"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}