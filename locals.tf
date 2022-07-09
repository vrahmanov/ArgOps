
locals {
  name   = "ex-${replace(basename(path.cwd), "_", "-")}"
  region = "us-east-2"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}