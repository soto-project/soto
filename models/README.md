# Models

In order to keep up with rapidly updating AWS APIs, we use [the JSON model files utilized by the Go AWS SDK](https://github.com/aws/aws-sdk-go/tree/master/models).

IMPORTANT - There are a few known bugs in certain services api.json

1. s3 - ReplicationStatus enum should be `COMPLETED` past tense. (_not_ `COMPLETE` present tense)
2. elasticloadbalancing (not v2) - ensure ``"SecurityGroupOwnerAlias":{"type":"integer"}`` (_not_ "string")

The current process to update this is to copy these files into our repo, re-run the [`CodeGenerator`](https://github.com/swift-aws/aws-sdk-swift/blob/master/Sources/CodeGenerator/main.swift), and then submit a PR.
