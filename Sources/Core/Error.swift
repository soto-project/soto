//
//  Error.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/04/04.
//
//

import Foundation

public protocol AWSErrorType: Error {
    init?(errorCode: String, message: String?)
}

public struct AWSRawError: Error {
    public let errorCode: String
    public let message: String?
    
    public init(errorCode: String, message: String?){
        self.errorCode = errorCode
        self.message = message
    }
}

public enum AWSServerError: AWSErrorType {
    // Not enough available addresses to satisfy your minimum request. Reduce the number of addresses you are requesting or wait for additional capacity to become available.
    case insufficientAddressCapacity(message: String?)
    //There is not enough capacity to fulfill your import instance request. You can wait for additional capacity to become available.
    case insufficientCapacity(message: String?)
    //There is not enough capacity to fulfill your instance request. Reduce the number of instances in your request, or wait for additional capacity to become available. You can also try launching an instance by selecting different instance types (which you can resize at a later stage). The returned message might also give specific guidance about how to solve the problem.
    case insufficientInstanceCapacity(message: String?)
    //There is not enough capacity to fulfill your Dedicated Host request. Reduce the number of Dedicated Hosts in your request, or wait for additional capacity to become available.
    case insufficientHostCapacity(message: String?)
    //Not enough available Reserved instances to satisfy your minimum request. Reduce the number of Reserved instances in your request or wait for additional capacity to become available.
    case insufficientReservedInstanceCapacity(message: String?)
    //An internal error has occurred. Retry your request, but if the problem persists, contact us with details by posting a message on the AWS forums.
    case internalError(message: String?)
    //The request processing has failed because of an unknown error, exception or failure.
    case internalFailure(message: String?)
    //The maximum request rate permitted by the Amazon EC2 APIs has been exceeded for your account. For best results, use an increasing or variable sleep interval between requests. For more information, see Query API Request Rate.
    case requestLimitExceeded(message: String?)
    //The request has failed due to a temporary failure of the server.
    case serviceUnavailable(message: String?)
    //The server is overloaded and can't handle the request.
    case unavailable(message: String?)
}

extension AWSServerError {
    public init?(errorCode: String, message: String?) {
        switch errorCode {
        case "InsufficientAddressCapacity":
            self = .insufficientAddressCapacity(message: message)
        case "InsufficientCapacity":
            self = .insufficientCapacity(message: message)
        case "InsufficientInstanceCapacity":
            self = .insufficientInstanceCapacity(message: message)
        case "InsufficientHostCapacity":
            self = .insufficientHostCapacity(message: message)
        case "InsufficientReservedInstanceCapacity":
            self = .insufficientReservedInstanceCapacity(message: message)
        case "InternalError":
            self = .internalError(message: message)
        case "InternalFailure":
            self = .internalFailure(message: message)
        case "RequestLimitExceeded":
            self = .requestLimitExceeded(message: message)
        case "ServiceUnavailable":
            self = .serviceUnavailable(message: message)
        case "Unavailable":
            self = .unavailable(message: message)
        default:
            return nil
        }
    }
}

public enum AWSClientError: AWSErrorType {
    /// The provided credentials could not be validated. You may not be authorized to carry out the request; for example, associating an Elastic IP address that is not yours, or trying to use an AMI for which you do not have permissions. Ensure that your account is authorized to use the Amazon EC2 service, that your credit card details are correct, and that you are using the correct access keys.
    case authFailure(message: String?)
    /// Your account is currently blocked. Contact aws-verification@amazon.com if you have questions.
    case blocked(message: String?)
    /// The user has the required permissions, so the request would have succeeded, but the DryRun parameter was used.
    case dryRunOperation(message: String?)
    /// The request uses the same client token as a previous, but non-identical request. Do not reuse a client token with different requests, unless the requests are identical.
    case idempotentParameterMismatch(message: String?)
    /// The request signature does not conform to AWS standards.
    case incompleteSignature(message: String?)
    /// The action or operation requested is not valid. Verify that the action is typed correctly.
    case invalidAction(message: String?)
    /// A specified character is invalid.
    case invalidCharacter(message: String?)
    /// The X.509 certificate or AWS access key ID provided does not exist in our records.
    case invalidClientTokenId(message: String?)
    /// The specified pagination token is not valid or is expired.
    case invalidPaginationToken(message: String?)
    /// A parameter specified in a request is not valid, is unsupported, or cannot be used. The returned message provides an explanation of the error value. For example, if you are launching an instance, you can't specify a security group and subnet that are in different VPCs.
    case invalidParameter(message: String?)
    /// Indicates an incorrect combination of parameters, or a missing parameter. For example, trying to terminate an instance without specifying the instance ID.
    case invalidParameterCombination(message: String?)
    /// A value specified in a parameter is not valid, is unsupported, or cannot be used. Ensure that you specify a resource by using its full ID. The returned message provides an explanation of the error value.
    case invalidParameterValue(message: String?)
    /// The AWS query string is malformed or does not adhere to AWS standards.
    case invalidQueryParameter(message: String?)
    /// The query string contains a syntax error.
    case malformedQueryString(message: String?)
    /// The request is missing an action or a required parameter.
    case missingAction(message: String?)
    /// The request must contain either a valid (registered) AWS access key ID or X.509 certificate.
    case missingAuthenticationToken(message: String?)
    /// The request is missing a required parameter. Ensure that you have supplied all the required parameters for the request; for example, the resource ID.
    case missingParameter(message: String?)
    /// You are not authorized to use the requested service. Ensure that you have subscribed to the service you are trying to use. If you are new to AWS, your account might take some time to be activated while your credit card details are being verified.
    case optInRequired(message: String?)
    /// Your account is pending verification. Until the verification process is complete, you may not be able to carry out requests with this account. If you have questions, contact AWS Support.
    case pendingVerification(message: String?)
    /// The request reached the service more than 15 minutes after the date stamp on the request or more than 15 minutes after the request expiration date (such as for pre-signed URLs), or the date stamp on the request is more than 15 minutes in the future. If you're using temporary security credentials, this error can also occur if the credentials have expired. For more information, see Temporary Security Credentials in the IAM User Guide.
    case requestExpired(message: String?)
    /// You are not authorized to perform this operation. Check your IAM policies, and ensure that you are using the correct access keys. For more information, see Controlling Access. If the returned message is encoded, you can decode it using the DecodeAuthorizationMessage action. For more information, see DecodeAuthorizationMessage in the AWS Security Token Service API Reference.
    case unauthorizedOperation(message: String?)
    /// An unknown or unrecognized parameter was supplied. Requests that could cause this error include supplying a misspelled parameter or a parameter that is not supported for the specified API version.
    case unknownParameter(message: String?)
    /// The specified attribute cannot be modified.
    case unsupportedInstanceAttribute(message: String?)
    /// The specified request includes an unsupported operation. For example, you can't stop an instance that's instance store-backed. Or you might be trying to launch an instance type that is not supported by the specified AMI. The returned message provides details of the unsupported operation.
    case unsupportedOperation(message: String?)
    /// SOAP has been deprecated and is no longer supported. For more information, see SOAP Requests.
    case unsupportedProtocol(message: String?)
    /// The input fails to satisfy the constraints specified by an AWS service.
    case validationError(message: String?)
    ///
    case accessDenied(message: String?)
    ///
    case signatureDoesNotMatch(message: String?)
}

extension AWSClientError {
    public init?(errorCode: String, message: String?) {
        switch errorCode {
        case "AuthFailure":
            self = .authFailure(message: message)
            
        case "Blocked":
            self = .blocked(message: message)
            
        case "DryRunOperation":
            self = .dryRunOperation(message: message)
            
        case "IdempotentParameterMismatch":
            self = .idempotentParameterMismatch(message: message)
            
        case "IncompleteSignature":
            self = .incompleteSignature(message: message)
            
        case "InvalidAction":
            self = .invalidAction(message: message)
            
        case "InvalidCharacter":
            self = .invalidCharacter(message: message)
            
        case "InvalidClientTokenId":
            self = .invalidClientTokenId(message: message)
            
        case "InvalidPaginationToken":
            self = .invalidPaginationToken(message: message)
            
        case "InvalidParameter":
            self = .invalidParameter(message: message)
            
        case "InvalidParameterCombination":
            self = .invalidParameterCombination(message: message)
            
        case "InvalidParameterValue":
            self = .invalidParameterValue(message: message)
            
        case "InvalidQueryParameter":
            self = .invalidQueryParameter(message: message)
            
        case "MalformedQueryString":
            self = .malformedQueryString(message: message)
            
        case "MissingAction":
            self = .missingAction(message: message)
            
        case "MissingAuthenticationToken":
            self = .missingAuthenticationToken(message: message)
            
        case "MissingParameter":
            self = .missingParameter(message: message)
            
        case "OptInRequired":
            self = .optInRequired(message: message)
            
        case "PendingVerification":
            self = .pendingVerification(message: message)
            
        case "RequestExpired":
            self = .requestExpired(message: message)
            
        case "UnauthorizedOperation":
            self = .unauthorizedOperation(message: message)
            
        case "UnknownParameter":
            self = .unknownParameter(message: message)
            
        case "UnsupportedInstanceAttribute":
            self = .unsupportedInstanceAttribute(message: message)
            
        case "UnsupportedOperation":
            self = .unsupportedOperation(message: message)
            
        case "UnsupportedProtocol":
            self = .unsupportedProtocol(message: message)
            
        case "ValidationError":
            self = .validationError(message: message)
            
        case "AccessDenied":
            self = .accessDenied(message: message)
            
        case "SignatureDoesNotMatch":
            self = .signatureDoesNotMatch(message: message)
            
        default:
            return nil
        }
    }
}
