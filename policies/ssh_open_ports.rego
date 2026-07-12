package terraform.ec2

test_deny_when_port_80_open_to_world {
    deny[_] with input as {
        "resource_changes": [
            {
                "type": "aws_security_group",
                "change": {"after": {"ingress": [
                    {"from_port": 80, "cidr_blocks": ["0.0.0.0/0"]}
                ]}}
            }
        ]
    }
}

test_allow_when_only_ssh_open_to_world {
    count(deny) == 0 with input as {
        "resource_changes": [
            {
                "type": "aws_security_group",
                "change": {"after": {"ingress": [
                    {"from_port": 22, "cidr_blocks": ["0.0.0.0/0"]}
                ]}}
            }
        ]
    }
}