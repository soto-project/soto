//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2024 the Soto project authors
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

#if os(Linux) && compiler(<5.10)
// swift-corelibs-foundation hasn't been updated with Sendable conformances
@preconcurrency import Foundation
#else
import Foundation
#endif
@_exported import SotoCore

/// Service object for interacting with AWS GeoRoutes service.
///
/// With the Amazon Location Routes API you can calculate routes and estimate travel time based on up-to-date road network and live  traffic information. Calculate optimal travel routes and estimate travel times using up-to-date road network and traffic data. Key features include:   Point-to-point routing with estimated travel time, distance, and turn-by-turn directions   Multi-point route optimization to minimize travel time or distance   Route matrices for efficient multi-destination planning   Isoline calculations to determine reachable areas within specified time or distance thresholds   Map-matching to align GPS traces with the road network
public struct GeoRoutes: AWSService {
    // MARK: Member variables

    /// Client used for communication with AWS
    public let client: AWSClient
    /// Service configuration
    public let config: AWSServiceConfig

    // MARK: Initialization

    /// Initialize the GeoRoutes client
    /// - parameters:
    ///     - client: AWSClient used to process requests
    ///     - region: Region of server you want to communicate with. This will override the partition parameter.
    ///     - partition: AWS partition where service resides, standard (.aws), china (.awscn), government (.awsusgov).
    ///     - endpoint: Custom endpoint URL to use instead of standard AWS servers
    ///     - middleware: Middleware chain used to edit requests before they are sent and responses before they are decoded 
    ///     - timeout: Timeout value for HTTP requests
    ///     - byteBufferAllocator: Allocator for ByteBuffers
    ///     - options: Service options
    public init(
        client: AWSClient,
        region: SotoCore.Region? = nil,
        partition: AWSPartition = .aws,
        endpoint: String? = nil,
        middleware: AWSMiddlewareProtocol? = nil,
        timeout: TimeAmount? = nil,
        byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator(),
        options: AWSServiceConfig.Options = []
    ) {
        self.client = client
        self.config = AWSServiceConfig(
            region: region,
            partition: region?.partition ?? partition,
            serviceName: "GeoRoutes",
            serviceIdentifier: "geo-routes",
            serviceProtocol: .restjson,
            apiVersion: "2020-11-19",
            endpoint: endpoint,
            errorType: GeoRoutesErrorType.self,
            middleware: middleware,
            timeout: timeout,
            byteBufferAllocator: byteBufferAllocator,
            options: options
        )
    }





    // MARK: API Calls

    /// Use the CalculateIsolines action to find service areas that can be reached in a given threshold of time, distance.
    @Sendable
    @inlinable
    public func calculateIsolines(_ input: CalculateIsolinesRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> CalculateIsolinesResponse {
        try await self.client.execute(
            operation: "CalculateIsolines", 
            path: "/isolines", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Use the CalculateIsolines action to find service areas that can be reached in a given threshold of time, distance.
    ///
    /// Parameters:
    ///   - allow: Features that are allowed while calculating. a route
    ///   - arrivalTime: Time of arrival at the destination. Time format: YYYY-MM-DDThh:mm:ss.sssZ | YYYY-MM-DDThh:mm:ss.sss+hh:mm  Examples:  2020-04-22T17:57:24Z   2020-04-22T17:57:24+02:00
    ///   - avoid: Features that are avoided while calculating a route. Avoidance is on a best-case basis. If an avoidance can't be satisfied for a particular case, it violates the avoidance and the returned response produces a notice for the violation.
    ///   - departNow: Uses the current time as the time of departure.
    ///   - departureTime: Time of departure from thr origin. Time format:YYYY-MM-DDThh:mm:ss.sssZ | YYYY-MM-DDThh:mm:ss.sss+hh:mm  Examples:  2020-04-22T17:57:24Z   2020-04-22T17:57:24+02:00
    ///   - destination: The final position for the route. In the World Geodetic System (WGS 84) format: [longitude, latitude].
    ///   - destinationOptions: Destination related options.
    ///   - isolineGeometryFormat: The format of the returned IsolineGeometry.  Default Value:FlexiblePolyline
    ///   - isolineGranularity: Defines the granularity of the returned Isoline
    ///   - key: Optional: The API key to be used for authorization. Either an API key or valid SigV4 signature must be provided when making a request.
    ///   - optimizeIsolineFor: Specifies the optimization criteria for when calculating an isoline. AccurateCalculation generates an isoline of higher granularity that is more precise.
    ///   - optimizeRoutingFor: Specifies the optimization criteria for calculating a route. Default Value: FastestRoute
    ///   - origin: The start position for the route.
    ///   - originOptions: Origin related options.
    ///   - thresholds: Threshold to be used for the isoline calculation. Up to  3 thresholds per provided type can be requested.
    ///   - traffic: Traffic related options.
    ///   - travelMode: Specifies the mode of transport when calculating a route.  Used in estimating the speed of travel and road compatibility.  The mode Scooter also applies to motorcycles, set to Scooter when wanted to calculate options for motorcycles.  Default Value: Car
    ///   - travelModeOptions: Travel mode related options for the provided travel mode.
    ///   - logger: Logger use during operation
    @inlinable
    public func calculateIsolines(
        allow: IsolineAllowOptions? = nil,
        arrivalTime: String? = nil,
        avoid: IsolineAvoidanceOptions? = nil,
        departNow: Bool? = nil,
        departureTime: String? = nil,
        destination: [Double]? = nil,
        destinationOptions: IsolineDestinationOptions? = nil,
        isolineGeometryFormat: GeometryFormat? = nil,
        isolineGranularity: IsolineGranularityOptions? = nil,
        key: String? = nil,
        optimizeIsolineFor: IsolineOptimizationObjective? = nil,
        optimizeRoutingFor: RoutingObjective? = nil,
        origin: [Double]? = nil,
        originOptions: IsolineOriginOptions? = nil,
        thresholds: IsolineThresholds,
        traffic: IsolineTrafficOptions? = nil,
        travelMode: IsolineTravelMode? = nil,
        travelModeOptions: IsolineTravelModeOptions? = nil,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> CalculateIsolinesResponse {
        let input = CalculateIsolinesRequest(
            allow: allow, 
            arrivalTime: arrivalTime, 
            avoid: avoid, 
            departNow: departNow, 
            departureTime: departureTime, 
            destination: destination, 
            destinationOptions: destinationOptions, 
            isolineGeometryFormat: isolineGeometryFormat, 
            isolineGranularity: isolineGranularity, 
            key: key, 
            optimizeIsolineFor: optimizeIsolineFor, 
            optimizeRoutingFor: optimizeRoutingFor, 
            origin: origin, 
            originOptions: originOptions, 
            thresholds: thresholds, 
            traffic: traffic, 
            travelMode: travelMode, 
            travelModeOptions: travelModeOptions
        )
        return try await self.calculateIsolines(input, logger: logger)
    }

    /// Calculates route matrix containing the results for all pairs of  Origins to Destinations. Each row corresponds to one entry in Origins.  Each entry in the row corresponds to the route from that entry in Origins to an entry in Destinations positions.
    @Sendable
    @inlinable
    public func calculateRouteMatrix(_ input: CalculateRouteMatrixRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> CalculateRouteMatrixResponse {
        try await self.client.execute(
            operation: "CalculateRouteMatrix", 
            path: "/route-matrix", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Calculates route matrix containing the results for all pairs of  Origins to Destinations. Each row corresponds to one entry in Origins.  Each entry in the row corresponds to the route from that entry in Origins to an entry in Destinations positions.
    ///
    /// Parameters:
    ///   - allow: Features that are allowed while calculating. a route
    ///   - avoid: Features that are avoided while calculating a route. Avoidance is on a best-case basis. If an avoidance can't be satisfied for a particular case, it violates the avoidance and the returned response produces a notice for the violation.
    ///   - departNow: Uses the current time as the time of departure.
    ///   - departureTime: Time of departure from thr origin. Time format:YYYY-MM-DDThh:mm:ss.sssZ | YYYY-MM-DDThh:mm:ss.sss+hh:mm  Examples:  2020-04-22T17:57:24Z   2020-04-22T17:57:24+02:00
    ///   - destinations: List of destinations for the route.
    ///   - exclude: Features to be strictly excluded while calculating the route.
    ///   - key: Optional: The API key to be used for authorization. Either an API key or valid SigV4 signature must be provided when making a request.
    ///   - optimizeRoutingFor: Specifies the optimization criteria for calculating a route. Default Value: FastestRoute
    ///   - origins: The position in longitude and latitude for the origin.
    ///   - routingBoundary: Boundary within which the matrix is to be calculated.  All data, origins and destinations outside the boundary are considered invalid.  When request routing boundary was set as AutoCircle, the response routing boundary will return Circle derived from the AutoCircle settings.
    ///   - traffic: Traffic related options.
    ///   - travelMode: Specifies the mode of transport when calculating a route.  Used in estimating the speed of travel and road compatibility. Default Value: Car
    ///   - travelModeOptions: Travel mode related options for the provided travel mode.
    ///   - logger: Logger use during operation
    @inlinable
    public func calculateRouteMatrix(
        allow: RouteMatrixAllowOptions? = nil,
        avoid: RouteMatrixAvoidanceOptions? = nil,
        departNow: Bool? = nil,
        departureTime: String? = nil,
        destinations: [RouteMatrixDestination],
        exclude: RouteMatrixExclusionOptions? = nil,
        key: String? = nil,
        optimizeRoutingFor: RoutingObjective? = nil,
        origins: [RouteMatrixOrigin],
        routingBoundary: RouteMatrixBoundary,
        traffic: RouteMatrixTrafficOptions? = nil,
        travelMode: RouteMatrixTravelMode? = nil,
        travelModeOptions: RouteMatrixTravelModeOptions? = nil,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> CalculateRouteMatrixResponse {
        let input = CalculateRouteMatrixRequest(
            allow: allow, 
            avoid: avoid, 
            departNow: departNow, 
            departureTime: departureTime, 
            destinations: destinations, 
            exclude: exclude, 
            key: key, 
            optimizeRoutingFor: optimizeRoutingFor, 
            origins: origins, 
            routingBoundary: routingBoundary, 
            traffic: traffic, 
            travelMode: travelMode, 
            travelModeOptions: travelModeOptions
        )
        return try await self.calculateRouteMatrix(input, logger: logger)
    }

    /// Calculates a route given the following required parameters:  Origin and Destination.
    @Sendable
    @inlinable
    public func calculateRoutes(_ input: CalculateRoutesRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> CalculateRoutesResponse {
        try await self.client.execute(
            operation: "CalculateRoutes", 
            path: "/routes", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Calculates a route given the following required parameters:  Origin and Destination.
    ///
    /// Parameters:
    ///   - allow: Features that are allowed while calculating. a route
    ///   - arrivalTime: Time of arrival at the destination. Time format:YYYY-MM-DDThh:mm:ss.sssZ | YYYY-MM-DDThh:mm:ss.sss+hh:mm  Examples:  2020-04-22T17:57:24Z   2020-04-22T17:57:24+02:00
    ///   - avoid: Features that are avoided while calculating a route. Avoidance is on a best-case basis. If an avoidance can't be satisfied for a particular case, it violates the avoidance and the returned response produces a notice for the violation.
    ///   - departNow: Uses the current time as the time of departure.
    ///   - departureTime: Time of departure from thr origin. Time format:YYYY-MM-DDThh:mm:ss.sssZ | YYYY-MM-DDThh:mm:ss.sss+hh:mm  Examples:  2020-04-22T17:57:24Z   2020-04-22T17:57:24+02:00
    ///   - destination: The final position for the route. In the World Geodetic System (WGS 84) format: [longitude, latitude].
    ///   - destinationOptions: Destination related options.
    ///   - driver: Driver related options.
    ///   - exclude: Features to be strictly excluded while calculating the route.
    ///   - instructionsMeasurementSystem: Measurement system to be used for instructions within steps in the response.
    ///   - key: Optional: The API key to be used for authorization. Either an API key or valid SigV4 signature must be provided when making a request.
    ///   - languages: List of languages for instructions within steps in the response.  Instructions in the requested language are returned only if they are available.
    ///   - legAdditionalFeatures: A list of optional additional parameters such as timezone that can be requested for each result.    Elevation: Retrieves the elevation information for each location.    Incidents: Provides information on traffic incidents along the route.    PassThroughWaypoints: Indicates waypoints that are passed through without stopping.    Summary: Returns a summary of the route, including distance and duration.    Tolls: Supplies toll cost information along the route.    TravelStepInstructions: Provides step-by-step instructions for travel along the route.    TruckRoadTypes: Returns information about road types suitable for trucks.    TypicalDuration: Gives typical travel duration based on historical data.    Zones: Specifies the time zone information for each waypoint.
    ///   - legGeometryFormat: Specifies the format of the geometry returned for each leg of the route. You can  choose between two different geometry encoding formats.  FlexiblePolyline: A compact and precise encoding format for the  leg geometry. For more information on the format, see the GitHub repository for   FlexiblePolyline .  Simple: A less compact encoding, which is easier to decode but may be less precise and result in larger payloads.
    ///   - maxAlternatives: Maximum number of alternative routes to be provided in the response, if available.
    ///   - optimizeRoutingFor: Specifies the optimization criteria for calculating a route. Default Value: FastestRoute
    ///   - origin: The start position for the route.
    ///   - originOptions: Origin related options.
    ///   - spanAdditionalFeatures: A list of optional features such as SpeedLimit that can be requested for a Span. A span is a section of a Leg for which the requested features have the same values.
    ///   - tolls: Toll related options.
    ///   - traffic: Traffic related options.
    ///   - travelMode: Specifies the mode of transport when calculating a route.  Used in estimating the speed of travel and road compatibility. Default Value: Car
    ///   - travelModeOptions: Travel mode related options for the provided travel mode.
    ///   - travelStepType: Type of step returned by the response.
    ///   - waypoints: List of waypoints between the Origin and Destination.
    ///   - logger: Logger use during operation
    @inlinable
    public func calculateRoutes(
        allow: RouteAllowOptions? = nil,
        arrivalTime: String? = nil,
        avoid: RouteAvoidanceOptions? = nil,
        departNow: Bool? = nil,
        departureTime: String? = nil,
        destination: [Double],
        destinationOptions: RouteDestinationOptions? = nil,
        driver: RouteDriverOptions? = nil,
        exclude: RouteExclusionOptions? = nil,
        instructionsMeasurementSystem: MeasurementSystem? = nil,
        key: String? = nil,
        languages: [String]? = nil,
        legAdditionalFeatures: [RouteLegAdditionalFeature]? = nil,
        legGeometryFormat: GeometryFormat? = nil,
        maxAlternatives: Int? = nil,
        optimizeRoutingFor: RoutingObjective? = nil,
        origin: [Double],
        originOptions: RouteOriginOptions? = nil,
        spanAdditionalFeatures: [RouteSpanAdditionalFeature]? = nil,
        tolls: RouteTollOptions? = nil,
        traffic: RouteTrafficOptions? = nil,
        travelMode: RouteTravelMode? = nil,
        travelModeOptions: RouteTravelModeOptions? = nil,
        travelStepType: RouteTravelStepType? = nil,
        waypoints: [RouteWaypoint]? = nil,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> CalculateRoutesResponse {
        let input = CalculateRoutesRequest(
            allow: allow, 
            arrivalTime: arrivalTime, 
            avoid: avoid, 
            departNow: departNow, 
            departureTime: departureTime, 
            destination: destination, 
            destinationOptions: destinationOptions, 
            driver: driver, 
            exclude: exclude, 
            instructionsMeasurementSystem: instructionsMeasurementSystem, 
            key: key, 
            languages: languages, 
            legAdditionalFeatures: legAdditionalFeatures, 
            legGeometryFormat: legGeometryFormat, 
            maxAlternatives: maxAlternatives, 
            optimizeRoutingFor: optimizeRoutingFor, 
            origin: origin, 
            originOptions: originOptions, 
            spanAdditionalFeatures: spanAdditionalFeatures, 
            tolls: tolls, 
            traffic: traffic, 
            travelMode: travelMode, 
            travelModeOptions: travelModeOptions, 
            travelStepType: travelStepType, 
            waypoints: waypoints
        )
        return try await self.calculateRoutes(input, logger: logger)
    }

    /// Calculates the optimal order to travel between a set of waypoints to minimize either the travel time or the distance travelled during the journey, based on road network restrictions and the traffic pattern data.
    @Sendable
    @inlinable
    public func optimizeWaypoints(_ input: OptimizeWaypointsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> OptimizeWaypointsResponse {
        try await self.client.execute(
            operation: "OptimizeWaypoints", 
            path: "/optimize-waypoints", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// Calculates the optimal order to travel between a set of waypoints to minimize either the travel time or the distance travelled during the journey, based on road network restrictions and the traffic pattern data.
    ///
    /// Parameters:
    ///   - avoid: Features that are avoided while calculating a route. Avoidance is on a best-case basis. If an avoidance can't be satisfied for a particular case, this setting is ignored.
    ///   - departureTime: Departure time from the waypoint. Time format:YYYY-MM-DDThh:mm:ss.sssZ | YYYY-MM-DDThh:mm:ss.sss+hh:mm  Examples:  2020-04-22T17:57:24Z   2020-04-22T17:57:24+02:00
    ///   - destination: The final position for the route in the World Geodetic System (WGS 84) format: [longitude, latitude].
    ///   - destinationOptions: Destination related options.
    ///   - driver: Driver related options.
    ///   - exclude: Features to be strictly excluded while calculating the route.
    ///   - key: Optional: The API key to be used for authorization. Either an API key or valid SigV4 signature must be provided when making a request.
    ///   - optimizeSequencingFor: Specifies the optimization criteria for the calculated sequence. Default Value: FastestRoute.
    ///   - origin: The start position for the route.
    ///   - originOptions: Origin related options.
    ///   - traffic: Traffic-related options.
    ///   - travelMode: Specifies the mode of transport when calculating a route.  Used in estimating the speed of travel and road compatibility. Default Value: Car
    ///   - travelModeOptions: Travel mode related options for the provided travel mode.
    ///   - waypoints: List of waypoints between the Origin and Destination.
    ///   - logger: Logger use during operation
    @inlinable
    public func optimizeWaypoints(
        avoid: WaypointOptimizationAvoidanceOptions? = nil,
        departureTime: String? = nil,
        destination: [Double]? = nil,
        destinationOptions: WaypointOptimizationDestinationOptions? = nil,
        driver: WaypointOptimizationDriverOptions? = nil,
        exclude: WaypointOptimizationExclusionOptions? = nil,
        key: String? = nil,
        optimizeSequencingFor: WaypointOptimizationSequencingObjective? = nil,
        origin: [Double],
        originOptions: WaypointOptimizationOriginOptions? = nil,
        traffic: WaypointOptimizationTrafficOptions? = nil,
        travelMode: WaypointOptimizationTravelMode? = nil,
        travelModeOptions: WaypointOptimizationTravelModeOptions? = nil,
        waypoints: [WaypointOptimizationWaypoint]? = nil,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> OptimizeWaypointsResponse {
        let input = OptimizeWaypointsRequest(
            avoid: avoid, 
            departureTime: departureTime, 
            destination: destination, 
            destinationOptions: destinationOptions, 
            driver: driver, 
            exclude: exclude, 
            key: key, 
            optimizeSequencingFor: optimizeSequencingFor, 
            origin: origin, 
            originOptions: originOptions, 
            traffic: traffic, 
            travelMode: travelMode, 
            travelModeOptions: travelModeOptions, 
            waypoints: waypoints
        )
        return try await self.optimizeWaypoints(input, logger: logger)
    }

    /// The SnapToRoads action matches GPS trace to roads most likely traveled on.
    @Sendable
    @inlinable
    public func snapToRoads(_ input: SnapToRoadsRequest, logger: Logger = AWSClient.loggingDisabled) async throws -> SnapToRoadsResponse {
        try await self.client.execute(
            operation: "SnapToRoads", 
            path: "/snap-to-roads", 
            httpMethod: .POST, 
            serviceConfig: self.config, 
            input: input, 
            logger: logger
        )
    }
    /// The SnapToRoads action matches GPS trace to roads most likely traveled on.
    ///
    /// Parameters:
    ///   - key: Optional: The API key to be used for authorization. Either an API key or valid SigV4 signature must be provided when making a request.
    ///   - snappedGeometryFormat: Chooses what the returned SnappedGeometry format should be. Default Value: FlexiblePolyline
    ///   - snapRadius: The radius around the provided tracepoint that is considered for snapping.  Unit: meters  Default value: 300
    ///   - tracePoints: List of trace points to be snapped onto the road network.
    ///   - travelMode: Specifies the mode of transport when calculating a route.  Used in estimating the speed of travel and road compatibility. Default Value: Car
    ///   - travelModeOptions: Travel mode related options for the provided travel mode.
    ///   - logger: Logger use during operation
    @inlinable
    public func snapToRoads(
        key: String? = nil,
        snappedGeometryFormat: GeometryFormat? = nil,
        snapRadius: Int64? = nil,
        tracePoints: [RoadSnapTracePoint],
        travelMode: RoadSnapTravelMode? = nil,
        travelModeOptions: RoadSnapTravelModeOptions? = nil,
        logger: Logger = AWSClient.loggingDisabled        
    ) async throws -> SnapToRoadsResponse {
        let input = SnapToRoadsRequest(
            key: key, 
            snappedGeometryFormat: snappedGeometryFormat, 
            snapRadius: snapRadius, 
            tracePoints: tracePoints, 
            travelMode: travelMode, 
            travelModeOptions: travelModeOptions
        )
        return try await self.snapToRoads(input, logger: logger)
    }
}

extension GeoRoutes {
    /// Initializer required by `AWSService.with(middlewares:timeout:byteBufferAllocator:options)`. You are not able to use this initializer directly as there are not public
    /// initializers for `AWSServiceConfig.Patch`. Please use `AWSService.with(middlewares:timeout:byteBufferAllocator:options)` instead.
    public init(from: GeoRoutes, patch: AWSServiceConfig.Patch) {
        self.client = from.client
        self.config = from.config.with(patch: patch)
    }
}