provider "aws" {
    region = "ap-southeast-2"
}
data "aws_vpc" "defaults" {
    default = true
}

data "aws_subnets" "defaults" {
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.defaults.id]
    }
}


resource "aws_iam_role" "eks_cluster_role" {
    name = "eks-cluster-role"

    assume_role_policy = jsonencode({
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "eks.amazonaws.com"
            }
        }]
        Version = "2012-10-17"
    })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role       = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "eks_cluster" {
    name     = "example-eks-cluster"
    role_arn = aws_iam_role.eks_cluster_role.arn
    version  = "1.29"

    vpc_config {
        subnet_ids = data.aws_subnets.defaults.ids
    }

    depends_on = [
        aws_iam_role_policy_attachment.eks_cluster_policy
    ]
}

resource "aws_iam_role" "k8s" {
    name = "eks-node-group-example"

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

resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.k8s.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = aws_iam_role.k8s.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role       = aws_iam_role.k8s.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSworkernodeminimalpolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
    role       = aws_iam_role.k8s.name
}

resource "aws_eks_node_group" "node" {
    cluster_name    = aws_eks_cluster.eks_cluster.name
    node_group_name = "node_group"
    node_role_arn   = aws_iam_role.k8s.arn
    subnet_ids      = data.aws_subnets.defaults.ids

    scaling_config {
        desired_size = 1
        max_size     = 2
        min_size     = 1
    }

    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["c7i.large"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 20

    depends_on = [
        aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
        aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
        aws_iam_role_policy_attachment.example-AmazonEKSworkernodeminimalpolicy,
    ]
}
