# AWSClient

Before you start using AWS SDK Swift you need to create an `AWSClient`. This is the object that manages your communication with AWS. It manages credential acqusition, takes your request, encodes it, signs it, sends it to AWS and then decodes the response for you. In most situations your application should only require one `AWSClient` . Create this at startup and use it throughout. Basic initialisation of a `AWSClient` only requires an 
# AWS service objects
