# Using Soto with Vapor 4

When using Soto with Vapor 4 it is best to have a global `AWSClient` that all routes use. You shouldn't be creating an `AWSClient` on the fly. Initialization of the client can take time and you have to shutdown the client before it is deleted. You best option is to store a single `AWSClient` in the Vapor `Application`. The code below shows how you can extend `Application` to provide a global `AWSClient`.

```swift
import Vapor

public extension Application {
    var aws: AWS {
        .init(application: self)
    }

    struct AWS {
        struct ClientKey: StorageKey {
            typealias Value = AWSClient
        }

        public var client: AWSClient {
            get {
                guard let client = self.application.storage[ClientKey.self] else {
                    fatalError("AWSClient not setup. Use application.aws.client = ...")
                }
                return client
            }
            nonmutating set {
                self.application.storage.set(ClientKey.self, to: newValue) {
                    try $0.syncShutdown()
                }            
            }
        }

        let application: Application
    }
}
```
And extend `Request` to provide access to this `AWSClient`.

```swift
public extension Request {
    var aws: AWS {
        .init(request: self)
    }

    struct AWS {
        var client: AWSClient {
            return request.application.aws.client
        }

        let request: Request
    }
}
```

Once you have this you can then initialize your client in the `configure(_ app: Application)` function found in `configure.swift`. The code below initializes an `AWSClient` to use the shared `HTTPClient` that Vapor uses.

```swift
app.aws.client = AWSClient(httpClientProvider: .shared(app.http.client.shared))
```

And then in all your routes you can access the `AWSClient` as follows
```swift
func myRoute(req: Request) -> EventLoopFuture<> {
    let client = req.aws.client
    let s3 = S3(client: client, region: .useast1)
}
```
Alternatively you can also include your service structs in the `Application` as well.
```swift
import SotoS3

extension Application.AWS {
    struct S3Key: StorageKey {
        typealias Value = S3
    }

    public var s3: S3 {
        get {
            guard let s3 = self.application.storage[S3Key.self] else {
                fatalError("S3 not setup. Use application.aws.s3 = ...")
            }
            return s3
        }
        nonmutating set {
            self.application.storage[S3Key.self] = newValue
        }
    }
}
```

And provide access to them through `Request`:

```swift
public extension Request.AWS {
    var s3: S3 {
        return request.application.aws.s3
    }
}
```

## Example

If you have extended your Vapor `Application` as above and also included an `SES` (Simple Email Service) service object in the `Application` in a similar way to the example above with `S3` you could write a route to send an email as follows:

```swift
final class MyController {
    struct EmailData: Content {
        let address: String
        let subject: String
        let message: String
    }
    func sendUserEmailFromJSON(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let emailData = try req.content.decode(EmailData.self)
        let destination = SES.Destination(toAddresses: [emailData.address])
        let message = SES.Message(body: .init(text: SES.Content(data: emailData.message)), subject: .init(data: emailData.subject))
        let sendEmailRequest = SES.SendEmailRequest(destination: destination, message: message, source: "soto@me.com")
        return req.ses.sendEmail(sendEmailRequest, on: req.eventLoop)
            .map { response -> HTTPStatus in
                return .ok
            }
    }
}
```
