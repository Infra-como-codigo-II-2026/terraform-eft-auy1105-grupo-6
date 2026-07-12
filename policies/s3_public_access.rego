package terraform.s3

deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_public_access_block"
  resource.change.after.block_public_acls == false
  msg := "El bucket S3 no puede tener block_public_acls en false"
}