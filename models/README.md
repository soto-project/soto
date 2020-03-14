# Models

In order to keep up with rapidly updating AWS APIs, we use [the JSON model files utilized by the Go AWS SDK](https://github.com/aws/aws-sdk-go/tree/master/models).

The current process to update this is to copy these files into our repo, re-run the [`CodeGenerator`](https://github.com/swift-aws/aws-sdk-swift/tree/master/CodeGenerator/Sources/CodeGenerator), and then submit a PR. A shell script [update_models.sh](https://github.com/swift-aws/aws-sdk-swift/blob/master/scripts/update_models.sh) has been written to automate this.

If there are any errors in the JSON model files these can be patched by the CodeGenerator. The code that does the patching can be found [here](https://github.com/swift-aws/aws-sdk-swift/blob/master/CodeGenerator/Sources/CodeGenerator/patch.swift).
