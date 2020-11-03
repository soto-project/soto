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

// THIS FILE IS AUTOMATICALLY GENERATED by https://github.com/soto-project/soto/tree/main/CodeGenerator. DO NOT EDIT.

import SotoCore

/// Error enum for SQS
public struct SQSErrorType: AWSErrorType {
    enum Code: String {
        case batchEntryIdsNotDistinct = "AWS.SimpleQueueService.BatchEntryIdsNotDistinct"
        case batchRequestTooLong = "AWS.SimpleQueueService.BatchRequestTooLong"
        case emptyBatchRequest = "AWS.SimpleQueueService.EmptyBatchRequest"
        case invalidAttributeName = "InvalidAttributeName"
        case invalidBatchEntryId = "AWS.SimpleQueueService.InvalidBatchEntryId"
        case invalidIdFormat = "InvalidIdFormat"
        case invalidMessageContents = "InvalidMessageContents"
        case messageNotInflight = "AWS.SimpleQueueService.MessageNotInflight"
        case overLimit = "OverLimit"
        case purgeQueueInProgress = "AWS.SimpleQueueService.PurgeQueueInProgress"
        case queueDeletedRecently = "AWS.SimpleQueueService.QueueDeletedRecently"
        case queueDoesNotExist = "AWS.SimpleQueueService.NonExistentQueue"
        case queueNameExists = "QueueAlreadyExists"
        case receiptHandleIsInvalid = "ReceiptHandleIsInvalid"
        case tooManyEntriesInBatchRequest = "AWS.SimpleQueueService.TooManyEntriesInBatchRequest"
        case unsupportedOperation = "AWS.SimpleQueueService.UnsupportedOperation"
    }

    private let error: Code
    public let context: AWSErrorContext?

    /// initialize SQS
    public init?(errorCode: String, context: AWSErrorContext) {
        guard let error = Code(rawValue: errorCode) else { return nil }
        self.error = error
        self.context = context
    }

    internal init(_ error: Code) {
        self.error = error
        self.context = nil
    }

    /// return error code string
    public var errorCode: String { self.error.rawValue }

    /// Two or more batch entries in the request have the same Id.
    public static var batchEntryIdsNotDistinct: Self { .init(.batchEntryIdsNotDistinct) }
    /// The length of all the messages put together is more than the limit.
    public static var batchRequestTooLong: Self { .init(.batchRequestTooLong) }
    /// The batch request doesn't contain any entries.
    public static var emptyBatchRequest: Self { .init(.emptyBatchRequest) }
    /// The specified attribute doesn't exist.
    public static var invalidAttributeName: Self { .init(.invalidAttributeName) }
    /// The Id of a batch entry in a batch request doesn't abide by the specification.
    public static var invalidBatchEntryId: Self { .init(.invalidBatchEntryId) }
    /// The specified receipt handle isn't valid for the current version.
    public static var invalidIdFormat: Self { .init(.invalidIdFormat) }
    /// The message contains characters outside the allowed set.
    public static var invalidMessageContents: Self { .init(.invalidMessageContents) }
    /// The specified message isn't in flight.
    public static var messageNotInflight: Self { .init(.messageNotInflight) }
    /// The specified action violates a limit. For example, ReceiveMessage returns this error if the maximum number of inflight messages is reached and AddPermission returns this error if the maximum number of permissions for the queue is reached.
    public static var overLimit: Self { .init(.overLimit) }
    /// Indicates that the specified queue previously received a PurgeQueue request within the last 60 seconds (the time it can take to delete the messages in the queue).
    public static var purgeQueueInProgress: Self { .init(.purgeQueueInProgress) }
    /// You must wait 60 seconds after deleting a queue before you can create another queue with the same name.
    public static var queueDeletedRecently: Self { .init(.queueDeletedRecently) }
    /// The specified queue doesn't exist.
    public static var queueDoesNotExist: Self { .init(.queueDoesNotExist) }
    /// A queue with this name already exists. Amazon SQS returns this error only if the request includes attributes whose values differ from those of the existing queue.
    public static var queueNameExists: Self { .init(.queueNameExists) }
    /// The specified receipt handle isn't valid.
    public static var receiptHandleIsInvalid: Self { .init(.receiptHandleIsInvalid) }
    /// The batch request contains more entries than permissible.
    public static var tooManyEntriesInBatchRequest: Self { .init(.tooManyEntriesInBatchRequest) }
    /// Error code 400. Unsupported operation.
    public static var unsupportedOperation: Self { .init(.unsupportedOperation) }
}

extension SQSErrorType: Equatable {
    public static func == (lhs: SQSErrorType, rhs: SQSErrorType) -> Bool {
        lhs.error == rhs.error
    }
}

extension SQSErrorType: CustomStringConvertible {
    public var description: String {
        return "\(self.error.rawValue): \(self.message ?? "")"
    }
}