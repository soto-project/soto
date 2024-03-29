//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2023 the Soto project authors
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

import SotoCore

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension KinesisVideoWebRTCStorage {
    // MARK: Async API Calls

    ///  Join the ongoing one way-video and/or multi-way audio WebRTC session as  a video producing device for an input channel. If there’s no existing  session for the channel, a new streaming session needs to be created, and the Amazon Resource Name (ARN) of the signaling channel must be provided.  Currently for the SINGLE_MASTER type, a video producing device is able to ingest both audio and video media into a stream, while viewers can only ingest audio. Both a video producing device  and viewers can join the session first, and wait for other participants. While participants are having peer to peer conversations through webRTC,  the ingested media session will be stored into the Kinesis Video Stream. Multiple viewers are able to playback real-time media. Customers can also use existing Kinesis Video Streams features like  HLS or DASH playback, Image generation, and more with ingested WebRTC media.  Assume that only one video producing device client can be associated with a session for the channel. If more than one  client joins the session of a specific channel as a video producing device, the most recent client request takes precedence.
    public func joinStorageSession(_ input: JoinStorageSessionInput, logger: Logger = AWSClient.loggingDisabled, on eventLoop: EventLoop? = nil) async throws {
        return try await self.client.execute(operation: "JoinStorageSession", path: "/joinStorageSession", httpMethod: .POST, serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }
}
