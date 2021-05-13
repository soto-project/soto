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

### Formatting

We use Nick Lockwood's SwiftFormat for formatting code. PRs will not be accepted if they haven't be formatted. The current version of SwiftFormat we are using is v0.47.4.

All new files need to include the following file header at the top
```swift
//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
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

The Soto shape, api and error service files are generated from the json files in the [`models`](https://github.com/soto-project/soto/tree/master/models) folder. We get these from Amazon via the [`aws-sdk-go`](https://github.com/aws/aws-sdk-go) GitHub repository.

The application to do this conversion from model file to Soto services files can be found in the [`CodeGenerator`](https://github.com/soto-project/soto/tree/master/CodeGenerator) folder of the soto repository. Go into this folder and type `open Package.swift` to load the project into Xcode.

The model files are not always correct, so we have to patch them before generating the Soto service files. This patch process is part of the `CodeGenerator` and is run prior to parsing the dictionaries that have been loaded from the model json. The code for this can be found in [`patch.swift`](https://github.com/soto-project/soto/blob/master/CodeGenerator/Sources/CodeGenerator/patch.swift).

At the top of this file you'll see a list of various shapes that have been patched. There are three types of patch (`replace`, `add` or `remove`). To work out what you need to patch, you need to look at the `api-2.json` file for the service you are editing and find the definition of the shape you want to change. The most common patches are for renaming, or adding enum entries. There are a number of patches removing a variable from the "required" section of a shape, for example. Once you have edited `patch.swift` you should run the CodeGenerator and new service files will be generated.

To help make it easier to review the contents of a response (to identify what might need to get patched), you can add the `AWSLoggingMiddleware` to the client to provide debug output. This should help you work out what the issue is. When you create your client you add the logging middleware as follows.

```swift
let client = AWSClient(middlewares: [AWSLoggingMiddleware()], ...)
```

## Community

You can also contribute by becoming an active member of the Soto community.  Join us on the soto-aws [slack](https://join.slack.com/t/soto-project/shared_invite/zt-juqk6l9w-z9zruW5pjlod4AscdWlz7Q).
