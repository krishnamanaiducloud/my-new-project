provider "aws" {
  region = "REGION"
}


module "vpc" {
  source = "../../modules/vpc"
  vpc-location                        = "LOCATION"
  namespace                           = "NS"
  name                                = "vpc"
  stage                               = "STAGE"
  map_public_ip_on_launch             = "false"
  total-nat-gateway-required          = "1"
  create_database_subnet_group        = "false"
  vpc-cidr                            = "CIDR.SERIES_VALUE.0.0/16"
  vpc-public-subnet-cidr              = ["CIDR.SERIES_VALUE.1.0/24","CIDR.SERIES_VALUE.2.0/24"]
  vpc-private-subnet-cidr             = ["CIDR.SERIES_VALUE.3.0/24","CIDR.SERIES_VALUE.4.0/24"]
  vpc-database_subnets-cidr           = ["CIDR.SERIES_VALUE.5.0/24","CIDR.SERIES_VALUE.6.0/24"]
  cluster-name                        = "NS-STAGE-eks-cluster"

}

module "eks_workers" {
  source                             = "../../modules/eks-cluster-workers"
  namespace                          = "NS"
  stage                              = "STAGE"
  name                               = "eks"
  instance_type                      = "INSTANCE_TYPE"
  vpc_id                             = module.vpc.vpc-id
  subnet_ids                         = module.vpc.private-subnet-ids
  associate_public_ip_address        = "false"
  health_check_type                  = "EC2"
  min_size                           = MIN
  max_size                           = MAX
  wait_for_capacity_timeout          = "10m"
  # Makesure to check the Latest EKS AMI according to AWS Region
  image_id                           = "IMAGE"
  cluster_name                       = "NS-STAGE-eks-cluster"
  key_name                           = "eksSTAGE"
  cluster_endpoint                   = module.eks_cluster.eks_cluster_endpoint
  cluster_certificate_authority_data = module.eks_cluster.eks_cluster_certificate_authority_data
  cluster_security_group_id          = module.eks_cluster.security_group_id


  # Auto-scaling policies and CloudWatch metric alarms
  autoscaling_policies_enabled           = true
  cpu_utilization_high_threshold_percent = 80
  cpu_utilization_low_threshold_percent  = 50
  block_device_mappings = [
      {
        device_name  = "/dev/xvda"
        no_device    = "false"
        virtual_name = "root"
        ebs = {
          encrypted             = true
          volume_size           = 150
          delete_on_termination = true
          iops                  = null
          kms_key_id            = null
          snapshot_id           = null
          volume_type           = "gp3"
        }
      }
    ]
}

module "eks_cluster" {
  source                       = "../../modules/eks-cluster-master"
  namespace                    = "NS"
  stage                        = "STAGE"
  name                         = "eks"
  region                       = "REGION"
  vpc_id                       = module.vpc.vpc-id
  subnet_ids                   = module.vpc.public-subnet-ids
  kubernetes_version           = "1.15"
  kubeconfig_path              = "~/.kube/configSTAGE"
  workers_role_arns            = [module.eks_workers.workers_role_arn]
  workers_security_group_ids   = [module.eks_workers.security_group_id]

  # "This configmap-auth.yaml is not exist, it will be automatically created & updated via scripts"
  configmap_auth_file          = "../../modules/eks-cluster-master/configmap-auth.yaml"
  oidc_provider_enabled        = true
  local_exec_interpreter       = "/bin/bash"



}
