# Credential Providers

Before using Soto, you will need AWS credentials to sign all your requests. The main client object, `AWSClient`, accepts a `credentialProvider` parameter in its `init`. With this you can specify how the client should find AWS credentials. The default if you don't set the `credentialProvider` parameter is to select a method from the four methods listed below. Each method is tested in the order they are listed below and the first that is successful is chosen. If you are running on a Mac it ignores the ECS or EC2 methods as they would obviously fail.

### Load Credentials from Environment Variable

You can set the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` and `AWSClient` will automatically pick up the credentials from these variables.

```bash
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
```

### Via ECS Container credentials

If you are running your code as an AWS ECS container task, you can [setup an IAM role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html#create_task_iam_policy_and_role) for your container task to automatically grant credentials via the metadata service.

### Via EC2 Instance Profile

If you are running your code on an AWS EC2 instance, you can [setup an IAM role](https://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-iam-instance-profile.html) as the server's Instance Profile to automatically grant credentials via the metadata service.

### Load Credentials from shared credential file.

You can [set shared credentials](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/create-shared-credentials-file.html) in the home directory for the user running the app, in the file `~/.aws/credentials`.

```ini
[default]
aws_access_key_id = YOUR_AWS_ACCESS_KEY_ID
aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
```

## Pass Credentials to AWSClient directly

If you would prefer to pass the credentials to the `AWSClient` directly you can specify credentials with the `.static` credential provider as follows.

```swift
let client = AWSClient(
    credentialProvider: .static(
        accessKeyId: "MY_AWS_ACCESS_KEY_ID",
        secretAccessKey: "MY_AWS_SECRET_ACCESS_KEY"
    )
)
```
## Without Credentials

Some services like CognitoIdentityProvider don't require credentials to access some of their functionality. In this case you should use the `.empty` credential provider. This will disable all other credential access functions and send requests unsigned.
```swift
let client = AWSClient(credentialProvider: .empty)
```

## Selector Credential Providers

You can supply a list of credential providers you would like your `AWSClient` to use with the `.selector` credential provider. Each provider in the list is tested, until it finds a provider that successfully provides credentials. The following would test if credentials are available via environment variables, and then in the shared config file `~/.aws/credentials`.
```swift
let client = AWSClient(credentialProvider: .selector(.environment, .configfile()))
```

The default credential provider is implemented as a selector as follows.
```swift
.selector(.environment, .ecs, .ec2, .configfile())
```

## STS and Cognito Identity

The `CredentialProviders` protocol allows you to define credential providers external to the core library. This mean you can implement STS(Security Token Service) and Cognito Identity credential providers.

STS extends `CredentialProviderFactory` with five new `CredentialProviders`.
- `stsAssumeRole` for returning temporary credentials for a different role.
- `stsSAML` for users authenticated via a SAML authentication response.
- `stsWebIdentity` for users who have been authenticated in a mobile or web application with a web identity provider.
- `federationToken` for providing temporary credential to federated users.
- `sessionToken` for providing temporary credentials for the provided user with possible MFA authentication.

See the AWS documentation on [requesting temporary security credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html).

CognitoIdentity adds `cognitoIdentity` for users in a Cognito Identity Pool. These can be users in a Cognito User Pool or users who authenticate with external providers such as Facebook, Google and Apple. See the AWS documentation on [Cognito Identity Pools](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-identity.html).

For example, to use `STS.AssumeRole` to acquire new credentials you provide a request structure, credential provider to access original credentials and a region to run the STS commands in:

```swift
import STS

let request = STS.AssumeRoleRequest(roleArn: "arn:aws:iam::000000000000:role/Admin", roleSessionName: "session-name")
let client = AWSClient(credentialProvider: .stsAssumeRole(request: request, credentialProvider: .ec2, region: .euwest1))
```

Similarly you can setup a Cognito Identity credential provider as follows:

```swift
import CognitoIdentity

let credentialProvider: CredentialProviderFactory = .cognitoIdentity(
    identityPoolId: poolId,
    logins: ["appleid.apple.com": "APPLETOKEN"],
    region: .useast1
)
let client = AWSClient(credentialProvider: credentialProvider)
```
