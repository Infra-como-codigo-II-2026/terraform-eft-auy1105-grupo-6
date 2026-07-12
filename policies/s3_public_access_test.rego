package terraform.s3

test_deny_when_public_acls_allowed {
    deny["El bucket S3 no puede tener block_public_acls en false"] with input as {
        "resource_changes": [
            {
                "type": "aws_s3_bucket_public_access_block",
                "change": {"after": {"block_public_acls": false}}
            }
        ]
    }
}

test_allow_when_public_acls_blocked {
    count(deny) == 0 with input as {
        "resource_changes": [
            {
                "type": "aws_s3_bucket_public_access_block",
                "change": {"after": {"block_public_acls": true}}
            }
        ]
    }
}