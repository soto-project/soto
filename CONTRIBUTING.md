# Contributing

## Legal
By submitting a pull request, you represent that you have the right to license your contribution to the community, and agree by submitting the patch
that your contributions are licensed under the Apache 2.0 license (see [LICENSE](LICENSE.txt)).

## Contributor Conduct
All contributors are expected to adhere to the project's [Code of Conduct](CODE_OF_CONDUCT.md).

## Submitting a bug or issue
Please ensure to include the following in your bug report
- A consise description of the issue, what happened and what you expected.
- Simple reproduction steps
- Version of the library you are using
- Contextual information (Swift version, OS etc)

## Submitting a Pull Request

Please ensure to include the following in your Pull Request
- A description of what you are trying to do. What the PR provides to the library, additional functionality, fixing a bug etc
- A description of the code changes
- Documentation on how these changes are being tested
- Additional tests to show your code working and to ensure future changes don't break your code.

Please keep you PRs to a minimal number of changes. If a PR is large try to split it up into smaller PRs. Don't move code around unnecessarily it makes comparing old with new very hard.

The main development branch of the repository is  `main`. Each major version release has it's own branch named "version number".x.x eg `4.x.x` . If you are submitting code for an older version then you should use the version branch as the base for your code changes.

### Testing

By default the Soto tests are setup to use [Localstack](https://github.com/localstack/localstack) for testing. This avoids hitting AWS services while testing. You need to run a localstack server locally to get this to work. As long as you have Docker this can be done by running the script `./scripts/localstack`. If you would like to test against real AWS services set the environment variable `AWS_DISABLE_LOCALSTACK` to `true`. Not all services are supported by Localstack and there are some discrepancies in error messages returned by Localstack and real AWS services. 

Other environment variables that affect testing include
- `AWS_LOG_LEVEL`: Sets log level of tests
- `AWS_ENABLE_LOGGING`: Log requests and responses sent and received by Soto.
- `AWS_TEST_RESOURCE_PREFIX`: Prefix all resources created by your tests with this string. This means you can run tests hitting AWS services without worrying about clashing with someone else running tests.

### Formatting

We use Apple's SwiftFormat for formatting code. PRs will not be accepted if they haven't be formatted.

All new files need to include the following file header at the top
```swift
//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2021 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```
Please ensure the dates are correct in the header.

### Creating, Updating, and Patching Service Modules

`Soto` is built using code generation. There are a few steps to generate the modules, and also a process to "patch" updates or fixes when we find them to be necessary to work correctly.

The Soto shape, api and error service files are generated from the json files in the [`models`](https://github.com/soto-project/soto/tree/main/models) folder. We get these from Amazon via the [`aws-sdk-go-v2`](https://github.com/aws/aws-sdk-go-v2) GitHub repository.

The application to do this conversion from model file to Soto services files can be found in the [`SotoCodeGenerator`](https://github.com/soto-project/soto-codegenerator) repository.

The model files are not always correct, so we have to patch them before generating the Soto service files. This patch process is part of the `SotoCodeGenerator` and is run prior to parsing the dictionaries that have been loaded from the model json. The code for this can be found in [`Model+Patch.swift`](https://github.com/soto-project/soto-codegenerator/blob/main/Sources/SotoCodeGeneratorLib/Model%2BPatch.swift).

To help make it easier to review the contents of a response (to identify what might need to get patched), you can add the `AWSLoggingMiddleware` to the AWSClient to provide debug output. This should help you work out what the issue is. When you create your client you add the logging middleware as follows.

```swift
let client = AWSClient(middlewares: [AWSLoggingMiddleware()], ...)
```

## Community

You can also contribute by becoming an active member of the Soto community.  Join us on the soto-aws [slack](https://join.slack.com/t/soto-project/shared_invite/zt-y7c8tmcx-Sm2eDY1nrRJ0~bRCD9byVg).
