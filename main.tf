terraform {
  required_version = "> 0.12.0"

  backend "s3" {
    bucket     = "pttp-logging-spike-terraform-remote-state"
    key        = "terraform/v1/state"
    region     = "eu-west-2"
  }
}

provider "tls" {
  version = "> 2.1"
}

data "aws_region" "current_region" {}

module "dynamic_subnets" {
  source                  = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
  namespace               = "pttp"
  stage                   = "dev"
  name                    = "pttp-logging-spike"
  availability_zones      = ["eu-west-2a","eu-west-2b","eu-west-2c"]
  vpc_id                  = module.vpc.vpc_id
  igw_id                  = module.vpc.igw_id
  cidr_block              = "10.0.0.0/16"
  map_public_ip_on_launch = false
  nat_gateway_enabled     = true
}

module "vpc" {
  source               = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=master"
  namespace            = "pttp"
  stage                = "dev"
  name                 = "pttp-logging-spike"
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

//module "build" {
//  source = "./modules/pipeline"
//  vpc_id = module.vpc.vpc_id
//  subnet_ids = module.dynamic_subnets.public_subnet_ids
//  github_oauth_token = var.github_oauth_token
//}

//module "ecs-spike" {
//  source = "./modules/ecs-spike"
//  vpc_id = module.vpc.vpc_id
//  subnet_ids = module.dynamic_subnets.public_subnet_ids
//}
//
//module "beats" {
//  source = "./modules/beats"
//  vpc_id = module.vpc.vpc_id
//  subnet_ids = module.dynamic_subnets.public_subnet_ids
//}
