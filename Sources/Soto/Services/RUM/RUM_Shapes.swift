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

// THIS FILE IS AUTOMATICALLY GENERATED by https://github.com/soto-project/soto-codegenerator.
// DO NOT EDIT.

#if compiler(>=5.6)
@preconcurrency import Foundation
#else
import Foundation
#endif
import SotoCore

extension RUM {
    // MARK: Enums

    public enum StateEnum: String, CustomStringConvertible, Codable, _SotoSendable {
        case active = "ACTIVE"
        case created = "CREATED"
        case deleting = "DELETING"
        public var description: String { return self.rawValue }
    }

    public enum Telemetry: String, CustomStringConvertible, Codable, _SotoSendable {
        /// Includes JS error event plugin
        case errors
        /// Includes X-Ray Xhr and X-Ray Fetch plugin
        case http
        /// Includes navigation, paint, resource and web vital event plugins
        case performance
        public var description: String { return self.rawValue }
    }

    // MARK: Shapes

    public struct AppMonitor: AWSDecodableShape {
        /// A structure that contains much of the configuration data for the app monitor.
        public let appMonitorConfiguration: AppMonitorConfiguration?
        /// The date and time that this app monitor was created.
        public let created: String?
        /// A structure that contains information about whether this app monitor stores a copy of the telemetry data that RUM collects using CloudWatch Logs.
        public let dataStorage: DataStorage?
        /// The top-level internet domain name for which your application has administrative authority.
        public let domain: String?
        /// The unique ID of this app monitor.
        public let id: String?
        /// The date and time of the most recent changes to this app monitor's configuration.
        public let lastModified: String?
        /// The name of the app monitor.
        public let name: String?
        /// The current state of the app monitor.
        public let state: StateEnum?
        /// The list of tag keys and values associated with this app monitor.
        public let tags: [String: String]?

        public init(appMonitorConfiguration: AppMonitorConfiguration? = nil, created: String? = nil, dataStorage: DataStorage? = nil, domain: String? = nil, id: String? = nil, lastModified: String? = nil, name: String? = nil, state: StateEnum? = nil, tags: [String: String]? = nil) {
            self.appMonitorConfiguration = appMonitorConfiguration
            self.created = created
            self.dataStorage = dataStorage
            self.domain = domain
            self.id = id
            self.lastModified = lastModified
            self.name = name
            self.state = state
            self.tags = tags
        }

        private enum CodingKeys: String, CodingKey {
            case appMonitorConfiguration = "AppMonitorConfiguration"
            case created = "Created"
            case dataStorage = "DataStorage"
            case domain = "Domain"
            case id = "Id"
            case lastModified = "LastModified"
            case name = "Name"
            case state = "State"
            case tags = "Tags"
        }
    }

    public struct AppMonitorConfiguration: AWSEncodableShape & AWSDecodableShape {
        /// If you set this to true, the RUM web client sets two cookies, a session cookie and a user cookie. The cookies allow the RUM web client to collect data relating to the number of users an application has and the behavior of the application across a sequence of events. Cookies are stored in the top-level domain of the current page.
        public let allowCookies: Bool?
        /// If you set this to true, RUM enables X-Ray tracing for the user sessions that RUM samples. RUM adds an X-Ray trace header to allowed HTTP requests. It also records an X-Ray segment for allowed HTTP requests. You can see traces and segments from these user sessions in the X-Ray console and the CloudWatch ServiceLens console. For more information, see What is X-Ray?
        public let enableXRay: Bool?
        /// A list of URLs in your website or application to exclude from RUM data collection. You can't include both ExcludedPages and IncludedPages in the same operation.
        public let excludedPages: [String]?
        /// A list of pages in the CloudWatch RUM console that are to be displayed with a "favorite" icon.
        public let favoritePages: [String]?
        /// The ARN of the guest IAM role that is attached to the Amazon Cognito identity pool  that is used to authorize the sending of data to RUM.
        public let guestRoleArn: String?
        /// The ID of the Amazon Cognito identity pool  that is used to authorize the sending of data to RUM.
        public let identityPoolId: String?
        /// If this app monitor is to collect data from only certain pages in your application, this structure lists those pages.   You can't include both ExcludedPages and IncludedPages in the same operation.
        public let includedPages: [String]?
        /// Specifies the percentage of user sessions to use for RUM data collection. Choosing a higher percentage gives you more data but also incurs more costs. The number you specify is the percentage of user sessions that will be used. If you omit this parameter, the default of 10 is used.
        public let sessionSampleRate: Double?
        /// An array that lists the types of telemetry data that this app monitor is to collect.    errors indicates that RUM collects data about unhandled JavaScript errors raised by your application.    performance indicates that RUM collects performance data about how your application and its resources are loaded and rendered. This includes Core Web Vitals.    http indicates that RUM collects data about HTTP errors thrown by your application.
        public let telemetries: [Telemetry]?

        public init(allowCookies: Bool? = nil, enableXRay: Bool? = nil, excludedPages: [String]? = nil, favoritePages: [String]? = nil, guestRoleArn: String? = nil, identityPoolId: String? = nil, includedPages: [String]? = nil, sessionSampleRate: Double? = nil, telemetries: [Telemetry]? = nil) {
            self.allowCookies = allowCookies
            self.enableXRay = enableXRay
            self.excludedPages = excludedPages
            self.favoritePages = favoritePages
            self.guestRoleArn = guestRoleArn
            self.identityPoolId = identityPoolId
            self.includedPages = includedPages
            self.sessionSampleRate = sessionSampleRate
            self.telemetries = telemetries
        }

        public func validate(name: String) throws {
            try self.excludedPages?.forEach {
                try validate($0, name: "excludedPages[]", parent: name, max: 1260)
                try validate($0, name: "excludedPages[]", parent: name, min: 1)
                try validate($0, name: "excludedPages[]", parent: name, pattern: "https?:\\/\\/(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&//=]*)")
            }
            try self.validate(self.excludedPages, name: "excludedPages", parent: name, max: 50)
            try self.validate(self.favoritePages, name: "favoritePages", parent: name, max: 50)
            try self.validate(self.guestRoleArn, name: "guestRoleArn", parent: name, pattern: "arn:[^:]*:[^:]*:[^:]*:[^:]*:.*")
            try self.validate(self.identityPoolId, name: "identityPoolId", parent: name, max: 55)
            try self.validate(self.identityPoolId, name: "identityPoolId", parent: name, min: 1)
            try self.validate(self.identityPoolId, name: "identityPoolId", parent: name, pattern: "[\\w-]+:[0-9a-f-]+")
            try self.includedPages?.forEach {
                try validate($0, name: "includedPages[]", parent: name, max: 1260)
                try validate($0, name: "includedPages[]", parent: name, min: 1)
                try validate($0, name: "includedPages[]", parent: name, pattern: "https?:\\/\\/(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&//=]*)")
            }
            try self.validate(self.includedPages, name: "includedPages", parent: name, max: 50)
            try self.validate(self.sessionSampleRate, name: "sessionSampleRate", parent: name, max: 1.0)
            try self.validate(self.sessionSampleRate, name: "sessionSampleRate", parent: name, min: 0.0)
        }

        private enum CodingKeys: String, CodingKey {
            case allowCookies = "AllowCookies"
            case enableXRay = "EnableXRay"
            case excludedPages = "ExcludedPages"
            case favoritePages = "FavoritePages"
            case guestRoleArn = "GuestRoleArn"
            case identityPoolId = "IdentityPoolId"
            case includedPages = "IncludedPages"
            case sessionSampleRate = "SessionSampleRate"
            case telemetries = "Telemetries"
        }
    }

    public struct AppMonitorDetails: AWSEncodableShape {
        /// The unique ID of the app monitor.
        public let id: String?
        /// The name of the app monitor.
        public let name: String?
        /// The version of the app monitor.
        public let version: String?

        public init(id: String? = nil, name: String? = nil, version: String? = nil) {
            self.id = id
            self.name = name
            self.version = version
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case version
        }
    }

    public struct AppMonitorSummary: AWSDecodableShape {
        /// The date and time that the app monitor was created.
        public let created: String?
        /// The unique ID of this app monitor.
        public let id: String?
        /// The date and time of the most recent changes to this app monitor's configuration.
        public let lastModified: String?
        /// The name of this app monitor.
        public let name: String?
        /// The current state of this app monitor.
        public let state: StateEnum?

        public init(created: String? = nil, id: String? = nil, lastModified: String? = nil, name: String? = nil, state: StateEnum? = nil) {
            self.created = created
            self.id = id
            self.lastModified = lastModified
            self.name = name
            self.state = state
        }

        private enum CodingKeys: String, CodingKey {
            case created = "Created"
            case id = "Id"
            case lastModified = "LastModified"
            case name = "Name"
            case state = "State"
        }
    }

    public struct CreateAppMonitorRequest: AWSEncodableShape {
        /// A structure that contains much of the configuration data for the app monitor. If you are using  Amazon Cognito for authorization, you must include this structure in your request, and it must include the ID of the  Amazon Cognito identity pool to use for authorization. If you don't include AppMonitorConfiguration, you must set up your own  authorization method. For more information, see  Authorize your application to send data to Amazon Web Services. If you omit this argument, the sample rate used for RUM is set to 10% of the user sessions.
        public let appMonitorConfiguration: AppMonitorConfiguration?
        /// Data collected by RUM is kept by RUM for 30 days and then deleted. This parameter specifies whether RUM  sends a copy of this telemetry data to Amazon CloudWatch Logs in your account. This enables you to keep the telemetry data for more than 30 days, but it does incur Amazon CloudWatch Logs charges. If you omit this parameter, the default is false.
        public let cwLogEnabled: Bool?
        /// The top-level internet domain name for which your application has administrative authority.
        public let domain: String
        /// A name for the app monitor.
        public let name: String
        /// Assigns one or more tags (key-value pairs) to the app monitor. Tags can help you organize and categorize your resources. You can also use them to scope user permissions by granting a user permission to access or change only resources with certain tag values. Tags don't have any semantic meaning to Amazon Web Services and are interpreted strictly as strings of characters.  You can associate as many as 50 tags with an app monitor. For more information, see Tagging Amazon Web Services resources.
        public let tags: [String: String]?

        public init(appMonitorConfiguration: AppMonitorConfiguration? = nil, cwLogEnabled: Bool? = nil, domain: String, name: String, tags: [String: String]? = nil) {
            self.appMonitorConfiguration = appMonitorConfiguration
            self.cwLogEnabled = cwLogEnabled
            self.domain = domain
            self.name = name
            self.tags = tags
        }

        public func validate(name: String) throws {
            try self.appMonitorConfiguration?.validate(name: "\(name).appMonitorConfiguration")
            try self.validate(self.domain, name: "domain", parent: name, max: 253)
            try self.validate(self.domain, name: "domain", parent: name, min: 1)
            try self.validate(self.domain, name: "domain", parent: name, pattern: "^(localhost)|^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$|^(?![-.])([A-Za-z0-9-\\.\\-]{0,63})((?![-])([a-zA-Z0-9]{1}|^[a-zA-Z0-9]{0,1}))\\.(?![-])[A-Za-z-0-9]{1,63}((?![-])([a-zA-Z0-9]{1}|^[a-zA-Z0-9]{0,1}))|^(\\*\\.)(?![-.])([A-Za-z0-9-\\.\\-]{0,63})((?![-])([a-zA-Z0-9]{1}|^[a-zA-Z0-9]{0,1}))\\.(?![-])[A-Za-z-0-9]{1,63}((?![-])([a-zA-Z0-9]{1}|^[a-zA-Z0-9]{0,1}))")
            try self.validate(self.name, name: "name", parent: name, max: 255)
            try self.validate(self.name, name: "name", parent: name, min: 1)
            try self.validate(self.name, name: "name", parent: name, pattern: "^(?!\\.)[\\.\\-_#A-Za-z0-9]+$")
            try self.tags?.forEach {
                try validate($0.key, name: "tags.key", parent: name, max: 128)
                try validate($0.key, name: "tags.key", parent: name, min: 1)
                try validate($0.key, name: "tags.key", parent: name, pattern: "^(?!aws:)[a-zA-Z+-=._:/]+$")
                try validate($0.value, name: "tags[\"\($0.key)\"]", parent: name, max: 256)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case appMonitorConfiguration = "AppMonitorConfiguration"
            case cwLogEnabled = "CwLogEnabled"
            case domain = "Domain"
            case name = "Name"
            case tags = "Tags"
        }
    }

    public struct CreateAppMonitorResponse: AWSDecodableShape {
        /// The unique ID of the new app monitor.
        public let id: String?

        public init(id: String? = nil) {
            self.id = id
        }

        private enum CodingKeys: String, CodingKey {
            case id = "Id"
        }
    }

    public struct CwLog: AWSDecodableShape {
        /// Indicated whether the app monitor stores copies of the data that RUM collects in CloudWatch Logs.
        public let cwLogEnabled: Bool?
        /// The name of the log group where the copies are stored.
        public let cwLogGroup: String?

        public init(cwLogEnabled: Bool? = nil, cwLogGroup: String? = nil) {
            self.cwLogEnabled = cwLogEnabled
            self.cwLogGroup = cwLogGroup
        }

        private enum CodingKeys: String, CodingKey {
            case cwLogEnabled = "CwLogEnabled"
            case cwLogGroup = "CwLogGroup"
        }
    }

    public struct DataStorage: AWSDecodableShape {
        /// A structure that contains the information about whether the app monitor stores copies of the data that RUM collects in CloudWatch Logs. If it does, this structure also contains the name of the log group.
        public let cwLog: CwLog?

        public init(cwLog: CwLog? = nil) {
            self.cwLog = cwLog
        }

        private enum CodingKeys: String, CodingKey {
            case cwLog = "CwLog"
        }
    }

    public struct DeleteAppMonitorRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "name", location: .uri("Name"))
        ]

        /// The name of the app monitor to delete.
        public let name: String

        public init(name: String) {
            self.name = name
        }

        public func validate(name: String) throws {
            try self.validate(self.name, name: "name", parent: name, max: 255)
            try self.validate(self.name, name: "name", parent: name, min: 1)
            try self.validate(self.name, name: "name", parent: name, pattern: "^(?!\\.)[\\.\\-_#A-Za-z0-9]+$")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct DeleteAppMonitorResponse: AWSDecodableShape {
        public init() {}
    }

    public struct GetAppMonitorDataRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "name", location: .uri("Name"))
        ]

        /// An array of structures that you can use to filter the results to those that match one or more sets of key-value pairs that you specify.
        public let filters: [QueryFilter]?
        /// The maximum number of results to return in one operation.
        public let maxResults: Int?
        /// The name of the app monitor that collected the data that you want to retrieve.
        public let name: String
        /// Use the token returned by the previous operation to request the next page of results.
        public let nextToken: String?
        /// A structure that defines the time range that you want to retrieve results from.
        public let timeRange: TimeRange

        public init(filters: [QueryFilter]? = nil, maxResults: Int? = nil, name: String, nextToken: String? = nil, timeRange: TimeRange) {
            self.filters = filters
            self.maxResults = maxResults
            self.name = name
            self.nextToken = nextToken
            self.timeRange = timeRange
        }

        public func validate(name: String) throws {
            try self.validate(self.maxResults, name: "maxResults", parent: name, max: 100)
            try self.validate(self.maxResults, name: "maxResults", parent: name, min: 0)
            try self.validate(self.name, name: "name", parent: name, max: 255)
            try self.validate(self.name, name: "name", parent: name, min: 1)
            try self.validate(self.name, name: "name", parent: name, pattern: "^(?!\\.)[\\.\\-_#A-Za-z0-9]+$")
        }

        private enum CodingKeys: String, CodingKey {
            case filters = "Filters"
            case maxResults = "MaxResults"
            case nextToken = "NextToken"
            case timeRange = "TimeRange"
        }
    }

    public struct GetAppMonitorDataResponse: AWSDecodableShape {
        /// The events that RUM collected that match your request.
        public let events: [String]?
        /// A token that you can use in a subsequent operation to retrieve the next set of results.
        public let nextToken: String?

        public init(events: [String]? = nil, nextToken: String? = nil) {
            self.events = events
            self.nextToken = nextToken
        }

        private enum CodingKeys: String, CodingKey {
            case events = "Events"
            case nextToken = "NextToken"
        }
    }

    public struct GetAppMonitorRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "name", location: .uri("Name"))
        ]

        /// The app monitor to retrieve information for.
        public let name: String

        public init(name: String) {
            self.name = name
        }

        public func validate(name: String) throws {
            try self.validate(self.name, name: "name", parent: name, max: 255)
            try self.validate(self.name, name: "name", parent: name, min: 1)
            try self.validate(self.name, name: "name", parent: name, pattern: "^(?!\\.)[\\.\\-_#A-Za-z0-9]+$")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct GetAppMonitorResponse: AWSDecodableShape {
        /// A structure containing all the configuration information for the app monitor.
        public let appMonitor: AppMonitor?

        public init(appMonitor: AppMonitor? = nil) {
            self.appMonitor = appMonitor
        }

        private enum CodingKeys: String, CodingKey {
            case appMonitor = "AppMonitor"
        }
    }

    public struct ListAppMonitorsRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "maxResults", location: .querystring("maxResults")),
            AWSMemberEncoding(label: "nextToken", location: .querystring("nextToken"))
        ]

        /// The maximum number of results to return in one operation.
        public let maxResults: Int?
        /// Use the token returned by the previous operation to request the next page of results.
        public let nextToken: String?

        public init(maxResults: Int? = nil, nextToken: String? = nil) {
            self.maxResults = maxResults
            self.nextToken = nextToken
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct ListAppMonitorsResponse: AWSDecodableShape {
        /// An array of structures that contain information about the returned app monitors.
        public let appMonitorSummaries: [AppMonitorSummary]?
        /// A token that you can use in a subsequent operation to retrieve the next set of results.
        public let nextToken: String?

        public init(appMonitorSummaries: [AppMonitorSummary]? = nil, nextToken: String? = nil) {
            self.appMonitorSummaries = appMonitorSummaries
            self.nextToken = nextToken
        }

        private enum CodingKeys: String, CodingKey {
            case appMonitorSummaries = "AppMonitorSummaries"
            case nextToken = "NextToken"
        }
    }

    public struct ListTagsForResourceRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "resourceArn", location: .uri("ResourceArn"))
        ]

        /// The ARN of the resource that you want to see the tags of.
        public let resourceArn: String

        public init(resourceArn: String) {
            self.resourceArn = resourceArn
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, pattern: "arn:[^:]*:[^:]*:[^:]*:[^:]*:.*")
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct ListTagsForResourceResponse: AWSDecodableShape {
        /// The ARN of the resource that you are viewing.
        public let resourceArn: String
        /// The list of tag keys and values associated with the resource you specified.
        public let tags: [String: String]

        public init(resourceArn: String, tags: [String: String]) {
            self.resourceArn = resourceArn
            self.tags = tags
        }

        private enum CodingKeys: String, CodingKey {
            case resourceArn = "ResourceArn"
            case tags = "Tags"
        }
    }

    public struct PutRumEventsRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "id", location: .uri("Id"))
        ]

        /// A structure that contains information about the app monitor that collected this telemetry information.
        public let appMonitorDetails: AppMonitorDetails
        /// A unique identifier for this batch of RUM event data.
        public let batchId: String
        /// The ID of the app monitor that is sending this data.
        public let id: String
        /// An array of structures that contain the telemetry event data.
        public let rumEvents: [RumEvent]
        /// A structure that contains information about the user session that this batch of events was collected from.
        public let userDetails: UserDetails

        public init(appMonitorDetails: AppMonitorDetails, batchId: String, id: String, rumEvents: [RumEvent], userDetails: UserDetails) {
            self.appMonitorDetails = appMonitorDetails
            self.batchId = batchId
            self.id = id
            self.rumEvents = rumEvents
            self.userDetails = userDetails
        }

        public func validate(name: String) throws {
            try self.validate(self.id, name: "id", parent: name, max: 36)
            try self.validate(self.id, name: "id", parent: name, min: 36)
            try self.validate(self.id, name: "id", parent: name, pattern: "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$")
        }

        private enum CodingKeys: String, CodingKey {
            case appMonitorDetails = "AppMonitorDetails"
            case batchId = "BatchId"
            case rumEvents = "RumEvents"
            case userDetails = "UserDetails"
        }
    }

    public struct PutRumEventsResponse: AWSDecodableShape {
        public init() {}
    }

    public struct QueryFilter: AWSEncodableShape {
        /// The name of a key to search for.  The filter returns only the events that match the Name and Values that you specify.  Valid values for Name are Browser | Device | Country | Page | OS | EventType | Invert
        public let name: String?
        /// The values of the Name that are to be be included in the returned results.
        public let values: [String]?

        public init(name: String? = nil, values: [String]? = nil) {
            self.name = name
            self.values = values
        }

        private enum CodingKeys: String, CodingKey {
            case name = "Name"
            case values = "Values"
        }
    }

    public struct RumEvent: AWSEncodableShape {
        /// A string containing details about the event.
        public let details: String
        /// A unique ID for this event.
        public let id: String
        /// Metadata about this event, which contains a JSON serialization of the identity of the user for this session. The user information comes from information such as the HTTP user-agent request header and document interface.
        public let metadata: String?
        /// The exact time that this event occurred.
        public let timestamp: Date
        /// The JSON schema that denotes the type of event this is, such as a page load or a new session.
        public let type: String

        public init(details: String, id: String, metadata: String? = nil, timestamp: Date, type: String) {
            self.details = details
            self.id = id
            self.metadata = metadata
            self.timestamp = timestamp
            self.type = type
        }

        private enum CodingKeys: String, CodingKey {
            case details
            case id
            case metadata
            case timestamp
            case type
        }
    }

    public struct TagResourceRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "resourceArn", location: .uri("ResourceArn"))
        ]

        /// The ARN of the CloudWatch RUM resource that you're adding tags to.
        public let resourceArn: String
        /// The list of key-value pairs to associate with the resource.
        public let tags: [String: String]

        public init(resourceArn: String, tags: [String: String]) {
            self.resourceArn = resourceArn
            self.tags = tags
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, pattern: "arn:[^:]*:[^:]*:[^:]*:[^:]*:.*")
            try self.tags.forEach {
                try validate($0.key, name: "tags.key", parent: name, max: 128)
                try validate($0.key, name: "tags.key", parent: name, min: 1)
                try validate($0.key, name: "tags.key", parent: name, pattern: "^(?!aws:)[a-zA-Z+-=._:/]+$")
                try validate($0.value, name: "tags[\"\($0.key)\"]", parent: name, max: 256)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case tags = "Tags"
        }
    }

    public struct TagResourceResponse: AWSDecodableShape {
        public init() {}
    }

    public struct TimeRange: AWSEncodableShape {
        /// The beginning of the time range to retrieve performance events from.
        public let after: Int64
        /// The end of the time range to retrieve performance events from. If you omit this, the time  range extends to the time that this operation is performed.
        public let before: Int64?

        public init(after: Int64, before: Int64? = nil) {
            self.after = after
            self.before = before
        }

        private enum CodingKeys: String, CodingKey {
            case after = "After"
            case before = "Before"
        }
    }

    public struct UntagResourceRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "resourceArn", location: .uri("ResourceArn")),
            AWSMemberEncoding(label: "tagKeys", location: .querystring("tagKeys"))
        ]

        /// The ARN of the CloudWatch RUM resource that you're removing tags from.
        public let resourceArn: String
        /// The list of tag keys to remove from the resource.
        public let tagKeys: [String]

        public init(resourceArn: String, tagKeys: [String]) {
            self.resourceArn = resourceArn
            self.tagKeys = tagKeys
        }

        public func validate(name: String) throws {
            try self.validate(self.resourceArn, name: "resourceArn", parent: name, pattern: "arn:[^:]*:[^:]*:[^:]*:[^:]*:.*")
            try self.tagKeys.forEach {
                try validate($0, name: "tagKeys[]", parent: name, max: 128)
                try validate($0, name: "tagKeys[]", parent: name, min: 1)
                try validate($0, name: "tagKeys[]", parent: name, pattern: "^(?!aws:)[a-zA-Z+-=._:/]+$")
            }
            try self.validate(self.tagKeys, name: "tagKeys", parent: name, max: 50)
        }

        private enum CodingKeys: CodingKey {}
    }

    public struct UntagResourceResponse: AWSDecodableShape {
        public init() {}
    }

    public struct UpdateAppMonitorRequest: AWSEncodableShape {
        public static var _encoding = [
            AWSMemberEncoding(label: "name", location: .uri("Name"))
        ]

        /// A structure that contains much of the configuration data for the app monitor. If you are using  Amazon Cognito for authorization, you must include this structure in your request, and it must include the ID of the  Amazon Cognito identity pool to use for authorization. If you don't include AppMonitorConfiguration, you must set up your own  authorization method. For more information, see  Authorize your application to send data to Amazon Web Services.
        public let appMonitorConfiguration: AppMonitorConfiguration?
        /// Data collected by RUM is kept by RUM for 30 days and then deleted. This parameter specifies whether RUM  sends a copy of this telemetry data to Amazon CloudWatch Logs in your account. This enables you to keep the telemetry data for more than 30 days, but it does incur Amazon CloudWatch Logs charges.
        public let cwLogEnabled: Bool?
        /// The top-level internet domain name for which your application has administrative authority.
        public let domain: String?
        /// The name of the app monitor to update.
        public let name: String

        public init(appMonitorConfiguration: AppMonitorConfiguration? = nil, cwLogEnabled: Bool? = nil, domain: String? = nil, name: String) {
            self.appMonitorConfiguration = appMonitorConfiguration
            self.cwLogEnabled = cwLogEnabled
            self.domain = domain
            self.name = name
        }

        public func validate(name: String) throws {
            try self.appMonitorConfiguration?.validate(name: "\(name).appMonitorConfiguration")
            try self.validate(self.domain, name: "domain", parent: name, max: 253)
            try self.validate(self.domain, name: "domain", parent: name, min: 1)
            try self.validate(self.domain, name: "domain", parent: name, pattern: "^(localhost)|^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$|^(?![-.])([A-Za-z0-9-\\.\\-]{0,63})((?![-])([a-zA-Z0-9]{1}|^[a-zA-Z0-9]{0,1}))\\.(?![-])[A-Za-z-0-9]{1,63}((?![-])([a-zA-Z0-9]{1}|^[a-zA-Z0-9]{0,1}))|^(\\*\\.)(?![-.])([A-Za-z0-9-\\.\\-]{0,63})((?![-])([a-zA-Z0-9]{1}|^[a-zA-Z0-9]{0,1}))\\.(?![-])[A-Za-z-0-9]{1,63}((?![-])([a-zA-Z0-9]{1}|^[a-zA-Z0-9]{0,1}))")
            try self.validate(self.name, name: "name", parent: name, max: 255)
            try self.validate(self.name, name: "name", parent: name, min: 1)
            try self.validate(self.name, name: "name", parent: name, pattern: "^(?!\\.)[\\.\\-_#A-Za-z0-9]+$")
        }

        private enum CodingKeys: String, CodingKey {
            case appMonitorConfiguration = "AppMonitorConfiguration"
            case cwLogEnabled = "CwLogEnabled"
            case domain = "Domain"
        }
    }

    public struct UpdateAppMonitorResponse: AWSDecodableShape {
        public init() {}
    }

    public struct UserDetails: AWSEncodableShape {
        /// The session ID that the performance events are from.
        public let sessionId: String?
        /// The ID of the user for this user session. This ID is generated by RUM and does not include any  personally identifiable information about the user.
        public let userId: String?

        public init(sessionId: String? = nil, userId: String? = nil) {
            self.sessionId = sessionId
            self.userId = userId
        }

        private enum CodingKeys: String, CodingKey {
            case sessionId
            case userId
        }
    }
}