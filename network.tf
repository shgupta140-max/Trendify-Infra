resource "aws_vpc" "trendstore" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "trendstore-vpc"
  }
}

resource "aws_subnet" "public_01" {
  vpc_id                  = aws_vpc.trendstore.id
  cidr_block              = var.public_subnet_01_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "trend-pub-sub01"
  }
}

resource "aws_subnet" "public_02" {
  vpc_id                  = aws_vpc.trendstore.id
  cidr_block              = var.public_subnet_02_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "trend-pub-sub02"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.trendstore.id

  tags = {
    Name = "trendstore-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.trendstore.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "trendstore-public-rt"
  }
}

resource "aws_route_table_association" "public_01" {
  subnet_id      = aws_subnet.public_01.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_02" {
  subnet_id      = aws_subnet.public_02.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "eks_nodes" {
  name        = "trendstore-eks-nodes-sg"
  description = "Security group for EKS worker nodes to allow application access on NodePort"
  vpc_id      = aws_vpc.trendstore.id

  ingress {
    description = "Allow application access via NodePort from anywhere"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "trendstore-eks-nodes-sg"
  }
}
