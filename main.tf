terraform {
 required_providers {
  aws = {
   source = "hashicorp/aws"
  }
 }
}

# setup IAM Role
resource "aws_iam_role" "eks-iam-role" {
 name = "node-eks-iam-role"

 path = "/"

 assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF

}
#Create the needed policies
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
 role    = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
 role    = aws_iam_role.eks-iam-role.name
}

#Attach the policies
resource "aws_eks_cluster" "eks-test" {
 name = "node-cluster"
 role_arn = aws_iam_role.eks-iam-role.arn

 vpc_config {
  subnet_ids = [var.subnet_id_1, var.subnet_id_2]
 }

 depends_on = [
  aws_iam_role.eks-iam-role,
 ]
}

# EKS cluster create
resource "aws_iam_role" "workernodes" {
  name = "eks-test"
 
  assume_role_policy = jsonencode({
   Statement = [{
    Action = "sts:AssumeRole"
    Effect = "Allow"
    Principal = {
     Service = "ec2.amazonaws.com"
    }
   }]
   Version = "2012-10-17"
  })
 }
#IAM Role for nodes 
 resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role    = aws_iam_role.workernodes.name
 }
 
 resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role    = aws_iam_role.workernodes.name
 }
 
 resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role    = aws_iam_role.workernodes.name
 }
 
 resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role    = aws_iam_role.workernodes.name
 }

#Create Nodes
 resource "aws_eks_node_group" "worker-node-group" {
  cluster_name  = aws_eks_cluster.eks-test.name
  node_group_name = "test-workernodes"
  node_role_arn  = aws_iam_role.workernodes.arn
  subnet_ids   = [var.subnet_id_1, var.subnet_id_2]
  instance_types = ["t2.micro"]
 
  scaling_config {
   desired_size = 1
   max_size   = 1
   min_size   = 1
  }
 
  depends_on = [
   aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
   aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
   #aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
 }
