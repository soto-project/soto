# Security Policy

## Supported Versions

Currently we support versions 4.x.x and 5.x.x of Soto. These will receive security updates as and when needed.

## Reporting a Vulnerability

If you believe you have found a security vulnerability in Soto please do not post this in a public forum, do not create a GitHub Issue. Instead you should email [security@soto.codes](mailto:security@soto.codes) with details of the issue.

#### What happens next?

* A member of the team will acknowledge receipt of the report within 5
  working days. This may include a request for additional
  information about reproducing the vulnerability.
* We will privately inform the Swift Server Work Group ([SSWG][sswg]) of the
  vulnerability within 10 days of the report as per their [security
  guidelines][sswg-security].
* Once we have identified a fix we may ask you to validate it. We aim to do this
  within 30 days, but this may not always be possible, for example when the 
  vulnerability is internal to Amazon Web Services(AWS). In this situation we will 
  forward the issue to AWS.
* We will decide on a planned release date and let you know when it is.
* Once the fix has been released we will publish a security advisory on GitHub
  and the [SSWG][sswg] will announce the vulnerability on the [Swift
  forums][swift-forums-sec].

[sswg]: https://github.com/swift-server/sswg
[sswg-security]: https://github.com/swift-server/sswg/blob/main/process/incubation.md#security-best-practices
[swift-forums-sec]: https://forums.swift.org/c/server/security-updates/
