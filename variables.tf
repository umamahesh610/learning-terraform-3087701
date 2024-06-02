variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t2.micro"
}

variable "ami_filter"{
  description = "Name filter and owner to AMI"
  
  type = object({
    name = string
    owner = string 
  })

  default = {
    name   = "bitnami-tomcat-*-x86_64-hvm-ebs-nami"
    owner = "979382823631" # Bitnami
  }
}
  
variable "environment" {
  description = "Defines the environment name and ip pre-fix"
  
  type = object({
    name = string
    network_prefix = string 
  })

  default = {
    name   = "dev"
    network_prefix = "10.0"
  }

}

variable "min_size" {
  description = "minimum no.of instances in asg"
  default =  1
}

variable "max_size" {
  description = "maximum no.of instances in asg"
  default =  2
}

variable "ProjectName" {
  description = "Name of the project"
  default =  "First teraform Project"
}