package terraform.ec2

deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_security_group"
  rule := resource.change.after.ingress[_]
  rule.from_port != 22
  rule.cidr_blocks[_] == "0.0.0.0/0"
  msg := sprintf("Puerto %d abierto a 0.0.0.0/0, solo el 22 esta permitido para Learner Lab", [rule.from_port])
}