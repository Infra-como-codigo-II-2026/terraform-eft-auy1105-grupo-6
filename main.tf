module "networking" {
  source  = "Infra-como-codigo-II-2026/vpc-AUY1105-grupo-6/aws"
  version = "~> 1.0.1"

  vpc_name    = "eft-vpc-grupo-6"
  vpc_cidr    = var.vpc_cidr
  project     = var.project
  environment = var.environment
}

module "compute" {
  source  = "Infra-como-codigo-II-2026/ec2-AUY1105-grupo-6/aws"
  version = "~> 1.0.1"

  key_name      = var.key_name
  ami           = var.ami != "" ? var.ami : data.aws_ami.amazon_linux.id
  subnet_id     = module.networking.subnet_publica_1_id
  vpc_id        = module.networking.vpc_id
  instance_name = "eft-instancia-grupo-6"
  project       = var.project
  environment   = var.environment
}