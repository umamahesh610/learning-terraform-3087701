variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t2.micro"
}

variable "environment"{
  description = "Define the environment like Dev, test"
  default     = "Dev"
  type = object ({
    name = "dev"
  })
}