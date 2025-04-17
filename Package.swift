// swift-tools-version:5.9
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

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency=complete")
]

let package = Package(
    name: "soto",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "SotoACM", targets: ["SotoACM"]),
        .library(name: "SotoACMPCA", targets: ["SotoACMPCA"]),
        .library(name: "SotoAPIGateway", targets: ["SotoAPIGateway"]),
        .library(name: "SotoARCZonalShift", targets: ["SotoARCZonalShift"]),
        .library(name: "SotoAccessAnalyzer", targets: ["SotoAccessAnalyzer"]),
        .library(name: "SotoAccount", targets: ["SotoAccount"]),
        .library(name: "SotoAmp", targets: ["SotoAmp"]),
        .library(name: "SotoAmplify", targets: ["SotoAmplify"]),
        .library(name: "SotoAmplifyBackend", targets: ["SotoAmplifyBackend"]),
        .library(name: "SotoAmplifyUIBuilder", targets: ["SotoAmplifyUIBuilder"]),
        .library(name: "SotoApiGatewayManagementApi", targets: ["SotoApiGatewayManagementApi"]),
        .library(name: "SotoApiGatewayV2", targets: ["SotoApiGatewayV2"]),
        .library(name: "SotoAppConfig", targets: ["SotoAppConfig"]),
        .library(name: "SotoAppConfigData", targets: ["SotoAppConfigData"]),
        .library(name: "SotoAppFabric", targets: ["SotoAppFabric"]),
        .library(name: "SotoAppIntegrations", targets: ["SotoAppIntegrations"]),
        .library(name: "SotoAppMesh", targets: ["SotoAppMesh"]),
        .library(name: "SotoAppRunner", targets: ["SotoAppRunner"]),
        .library(name: "SotoAppStream", targets: ["SotoAppStream"]),
        .library(name: "SotoAppSync", targets: ["SotoAppSync"]),
        .library(name: "SotoAppTest", targets: ["SotoAppTest"]),
        .library(name: "SotoAppflow", targets: ["SotoAppflow"]),
        .library(name: "SotoApplicationAutoScaling", targets: ["SotoApplicationAutoScaling"]),
        .library(name: "SotoApplicationCostProfiler", targets: ["SotoApplicationCostProfiler"]),
        .library(name: "SotoApplicationDiscoveryService", targets: ["SotoApplicationDiscoveryService"]),
        .library(name: "SotoApplicationInsights", targets: ["SotoApplicationInsights"]),
        .library(name: "SotoApplicationSignals", targets: ["SotoApplicationSignals"]),
        .library(name: "SotoArtifact", targets: ["SotoArtifact"]),
        .library(name: "SotoAthena", targets: ["SotoAthena"]),
        .library(name: "SotoAuditManager", targets: ["SotoAuditManager"]),
        .library(name: "SotoAutoScaling", targets: ["SotoAutoScaling"]),
        .library(name: "SotoAutoScalingPlans", targets: ["SotoAutoScalingPlans"]),
        .library(name: "SotoB2bi", targets: ["SotoB2bi"]),
        .library(name: "SotoBCMDataExports", targets: ["SotoBCMDataExports"]),
        .library(name: "SotoBCMPricingCalculator", targets: ["SotoBCMPricingCalculator"]),
        .library(name: "SotoBackup", targets: ["SotoBackup"]),
        .library(name: "SotoBackupGateway", targets: ["SotoBackupGateway"]),
        .library(name: "SotoBackupSearch", targets: ["SotoBackupSearch"]),
        .library(name: "SotoBatch", targets: ["SotoBatch"]),
        .library(name: "SotoBedrock", targets: ["SotoBedrock"]),
        .library(name: "SotoBedrockAgent", targets: ["SotoBedrockAgent"]),
        .library(name: "SotoBedrockAgentRuntime", targets: ["SotoBedrockAgentRuntime"]),
        .library(name: "SotoBedrockDataAutomation", targets: ["SotoBedrockDataAutomation"]),
        .library(name: "SotoBedrockDataAutomationRuntime", targets: ["SotoBedrockDataAutomationRuntime"]),
        .library(name: "SotoBedrockRuntime", targets: ["SotoBedrockRuntime"]),
        .library(name: "SotoBilling", targets: ["SotoBilling"]),
        .library(name: "SotoBillingconductor", targets: ["SotoBillingconductor"]),
        .library(name: "SotoBraket", targets: ["SotoBraket"]),
        .library(name: "SotoBudgets", targets: ["SotoBudgets"]),
        .library(name: "SotoChatbot", targets: ["SotoChatbot"]),
        .library(name: "SotoChime", targets: ["SotoChime"]),
        .library(name: "SotoChimeSDKIdentity", targets: ["SotoChimeSDKIdentity"]),
        .library(name: "SotoChimeSDKMediaPipelines", targets: ["SotoChimeSDKMediaPipelines"]),
        .library(name: "SotoChimeSDKMeetings", targets: ["SotoChimeSDKMeetings"]),
        .library(name: "SotoChimeSDKMessaging", targets: ["SotoChimeSDKMessaging"]),
        .library(name: "SotoChimeSDKVoice", targets: ["SotoChimeSDKVoice"]),
        .library(name: "SotoCleanRooms", targets: ["SotoCleanRooms"]),
        .library(name: "SotoCleanRoomsML", targets: ["SotoCleanRoomsML"]),
        .library(name: "SotoCloud9", targets: ["SotoCloud9"]),
        .library(name: "SotoCloudControl", targets: ["SotoCloudControl"]),
        .library(name: "SotoCloudDirectory", targets: ["SotoCloudDirectory"]),
        .library(name: "SotoCloudFormation", targets: ["SotoCloudFormation"]),
        .library(name: "SotoCloudFront", targets: ["SotoCloudFront"]),
        .library(name: "SotoCloudFrontKeyValueStore", targets: ["SotoCloudFrontKeyValueStore"]),
        .library(name: "SotoCloudHSM", targets: ["SotoCloudHSM"]),
        .library(name: "SotoCloudHSMV2", targets: ["SotoCloudHSMV2"]),
        .library(name: "SotoCloudSearch", targets: ["SotoCloudSearch"]),
        .library(name: "SotoCloudSearchDomain", targets: ["SotoCloudSearchDomain"]),
        .library(name: "SotoCloudTrail", targets: ["SotoCloudTrail"]),
        .library(name: "SotoCloudTrailData", targets: ["SotoCloudTrailData"]),
        .library(name: "SotoCloudWatch", targets: ["SotoCloudWatch"]),
        .library(name: "SotoCloudWatchEvents", targets: ["SotoCloudWatchEvents"]),
        .library(name: "SotoCloudWatchLogs", targets: ["SotoCloudWatchLogs"]),
        .library(name: "SotoCodeArtifact", targets: ["SotoCodeArtifact"]),
        .library(name: "SotoCodeBuild", targets: ["SotoCodeBuild"]),
        .library(name: "SotoCodeCatalyst", targets: ["SotoCodeCatalyst"]),
        .library(name: "SotoCodeCommit", targets: ["SotoCodeCommit"]),
        .library(name: "SotoCodeConnections", targets: ["SotoCodeConnections"]),
        .library(name: "SotoCodeDeploy", targets: ["SotoCodeDeploy"]),
        .library(name: "SotoCodeGuruProfiler", targets: ["SotoCodeGuruProfiler"]),
        .library(name: "SotoCodeGuruReviewer", targets: ["SotoCodeGuruReviewer"]),
        .library(name: "SotoCodeGuruSecurity", targets: ["SotoCodeGuruSecurity"]),
        .library(name: "SotoCodePipeline", targets: ["SotoCodePipeline"]),
        .library(name: "SotoCodeStarConnections", targets: ["SotoCodeStarConnections"]),
        .library(name: "SotoCodeStarNotifications", targets: ["SotoCodeStarNotifications"]),
        .library(name: "SotoCognitoIdentity", targets: ["SotoCognitoIdentity"]),
        .library(name: "SotoCognitoIdentityProvider", targets: ["SotoCognitoIdentityProvider"]),
        .library(name: "SotoCognitoSync", targets: ["SotoCognitoSync"]),
        .library(name: "SotoComprehend", targets: ["SotoComprehend"]),
        .library(name: "SotoComprehendMedical", targets: ["SotoComprehendMedical"]),
        .library(name: "SotoComputeOptimizer", targets: ["SotoComputeOptimizer"]),
        .library(name: "SotoConfigService", targets: ["SotoConfigService"]),
        .library(name: "SotoConnect", targets: ["SotoConnect"]),
        .library(name: "SotoConnectCampaigns", targets: ["SotoConnectCampaigns"]),
        .library(name: "SotoConnectCampaignsV2", targets: ["SotoConnectCampaignsV2"]),
        .library(name: "SotoConnectCases", targets: ["SotoConnectCases"]),
        .library(name: "SotoConnectContactLens", targets: ["SotoConnectContactLens"]),
        .library(name: "SotoConnectParticipant", targets: ["SotoConnectParticipant"]),
        .library(name: "SotoControlCatalog", targets: ["SotoControlCatalog"]),
        .library(name: "SotoControlTower", targets: ["SotoControlTower"]),
        .library(name: "SotoCostAndUsageReportService", targets: ["SotoCostAndUsageReportService"]),
        .library(name: "SotoCostExplorer", targets: ["SotoCostExplorer"]),
        .library(name: "SotoCostOptimizationHub", targets: ["SotoCostOptimizationHub"]),
        .library(name: "SotoCustomerProfiles", targets: ["SotoCustomerProfiles"]),
        .library(name: "SotoDAX", targets: ["SotoDAX"]),
        .library(name: "SotoDLM", targets: ["SotoDLM"]),
        .library(name: "SotoDSQL", targets: ["SotoDSQL"]),
        .library(name: "SotoDataBrew", targets: ["SotoDataBrew"]),
        .library(name: "SotoDataExchange", targets: ["SotoDataExchange"]),
        .library(name: "SotoDataPipeline", targets: ["SotoDataPipeline"]),
        .library(name: "SotoDataSync", targets: ["SotoDataSync"]),
        .library(name: "SotoDataZone", targets: ["SotoDataZone"]),
        .library(name: "SotoDatabaseMigrationService", targets: ["SotoDatabaseMigrationService"]),
        .library(name: "SotoDeadline", targets: ["SotoDeadline"]),
        .library(name: "SotoDetective", targets: ["SotoDetective"]),
        .library(name: "SotoDevOpsGuru", targets: ["SotoDevOpsGuru"]),
        .library(name: "SotoDeviceFarm", targets: ["SotoDeviceFarm"]),
        .library(name: "SotoDirectConnect", targets: ["SotoDirectConnect"]),
        .library(name: "SotoDirectoryService", targets: ["SotoDirectoryService"]),
        .library(name: "SotoDirectoryServiceData", targets: ["SotoDirectoryServiceData"]),
        .library(name: "SotoDocDB", targets: ["SotoDocDB"]),
        .library(name: "SotoDocDBElastic", targets: ["SotoDocDBElastic"]),
        .library(name: "SotoDrs", targets: ["SotoDrs"]),
        .library(name: "SotoDynamoDB", targets: ["SotoDynamoDB"]),
        .library(name: "SotoDynamoDBStreams", targets: ["SotoDynamoDBStreams"]),
        .library(name: "SotoEBS", targets: ["SotoEBS"]),
        .library(name: "SotoEC2", targets: ["SotoEC2"]),
        .library(name: "SotoEC2InstanceConnect", targets: ["SotoEC2InstanceConnect"]),
        .library(name: "SotoECR", targets: ["SotoECR"]),
        .library(name: "SotoECRPublic", targets: ["SotoECRPublic"]),
        .library(name: "SotoECS", targets: ["SotoECS"]),
        .library(name: "SotoEFS", targets: ["SotoEFS"]),
        .library(name: "SotoEKS", targets: ["SotoEKS"]),
        .library(name: "SotoEKSAuth", targets: ["SotoEKSAuth"]),
        .library(name: "SotoEMR", targets: ["SotoEMR"]),
        .library(name: "SotoEMRContainers", targets: ["SotoEMRContainers"]),
        .library(name: "SotoEMRServerless", targets: ["SotoEMRServerless"]),
        .library(name: "SotoElastiCache", targets: ["SotoElastiCache"]),
        .library(name: "SotoElasticBeanstalk", targets: ["SotoElasticBeanstalk"]),
        .library(name: "SotoElasticLoadBalancing", targets: ["SotoElasticLoadBalancing"]),
        .library(name: "SotoElasticLoadBalancingV2", targets: ["SotoElasticLoadBalancingV2"]),
        .library(name: "SotoElasticTranscoder", targets: ["SotoElasticTranscoder"]),
        .library(name: "SotoElasticsearchService", targets: ["SotoElasticsearchService"]),
        .library(name: "SotoEntityResolution", targets: ["SotoEntityResolution"]),
        .library(name: "SotoEventBridge", targets: ["SotoEventBridge"]),
        .library(name: "SotoEvidently", targets: ["SotoEvidently"]),
        .library(name: "SotoFIS", targets: ["SotoFIS"]),
        .library(name: "SotoFMS", targets: ["SotoFMS"]),
        .library(name: "SotoFSx", targets: ["SotoFSx"]),
        .library(name: "SotoFinspace", targets: ["SotoFinspace"]),
        .library(name: "SotoFinspaceData", targets: ["SotoFinspaceData"]),
        .library(name: "SotoFirehose", targets: ["SotoFirehose"]),
        .library(name: "SotoForecast", targets: ["SotoForecast"]),
        .library(name: "SotoForecastquery", targets: ["SotoForecastquery"]),
        .library(name: "SotoFraudDetector", targets: ["SotoFraudDetector"]),
        .library(name: "SotoFreeTier", targets: ["SotoFreeTier"]),
        .library(name: "SotoGameLift", targets: ["SotoGameLift"]),
        .library(name: "SotoGameLiftStreams", targets: ["SotoGameLiftStreams"]),
        .library(name: "SotoGeoMaps", targets: ["SotoGeoMaps"]),
        .library(name: "SotoGeoPlaces", targets: ["SotoGeoPlaces"]),
        .library(name: "SotoGeoRoutes", targets: ["SotoGeoRoutes"]),
        .library(name: "SotoGlacier", targets: ["SotoGlacier"]),
        .library(name: "SotoGlobalAccelerator", targets: ["SotoGlobalAccelerator"]),
        .library(name: "SotoGlue", targets: ["SotoGlue"]),
        .library(name: "SotoGrafana", targets: ["SotoGrafana"]),
        .library(name: "SotoGreengrass", targets: ["SotoGreengrass"]),
        .library(name: "SotoGreengrassV2", targets: ["SotoGreengrassV2"]),
        .library(name: "SotoGroundStation", targets: ["SotoGroundStation"]),
        .library(name: "SotoGuardDuty", targets: ["SotoGuardDuty"]),
        .library(name: "SotoHealth", targets: ["SotoHealth"]),
        .library(name: "SotoHealthLake", targets: ["SotoHealthLake"]),
        .library(name: "SotoIAM", targets: ["SotoIAM"]),
        .library(name: "SotoIVS", targets: ["SotoIVS"]),
        .library(name: "SotoIVSRealTime", targets: ["SotoIVSRealTime"]),
        .library(name: "SotoIdentityStore", targets: ["SotoIdentityStore"]),
        .library(name: "SotoImagebuilder", targets: ["SotoImagebuilder"]),
        .library(name: "SotoInspector", targets: ["SotoInspector"]),
        .library(name: "SotoInspector2", targets: ["SotoInspector2"]),
        .library(name: "SotoInspectorScan", targets: ["SotoInspectorScan"]),
        .library(name: "SotoInternetMonitor", targets: ["SotoInternetMonitor"]),
        .library(name: "SotoInvoicing", targets: ["SotoInvoicing"]),
        .library(name: "SotoIoT", targets: ["SotoIoT"]),
        .library(name: "SotoIoTAnalytics", targets: ["SotoIoTAnalytics"]),
        .library(name: "SotoIoTDataPlane", targets: ["SotoIoTDataPlane"]),
        .library(name: "SotoIoTDeviceAdvisor", targets: ["SotoIoTDeviceAdvisor"]),
        .library(name: "SotoIoTEvents", targets: ["SotoIoTEvents"]),
        .library(name: "SotoIoTEventsData", targets: ["SotoIoTEventsData"]),
        .library(name: "SotoIoTFleetHub", targets: ["SotoIoTFleetHub"]),
        .library(name: "SotoIoTFleetWise", targets: ["SotoIoTFleetWise"]),
        .library(name: "SotoIoTJobsDataPlane", targets: ["SotoIoTJobsDataPlane"]),
        .library(name: "SotoIoTManagedIntegrations", targets: ["SotoIoTManagedIntegrations"]),
        .library(name: "SotoIoTSecureTunneling", targets: ["SotoIoTSecureTunneling"]),
        .library(name: "SotoIoTSiteWise", targets: ["SotoIoTSiteWise"]),
        .library(name: "SotoIoTThingsGraph", targets: ["SotoIoTThingsGraph"]),
        .library(name: "SotoIoTTwinMaker", targets: ["SotoIoTTwinMaker"]),
        .library(name: "SotoIoTWireless", targets: ["SotoIoTWireless"]),
        .library(name: "SotoIvschat", targets: ["SotoIvschat"]),
        .library(name: "SotoKMS", targets: ["SotoKMS"]),
        .library(name: "SotoKafka", targets: ["SotoKafka"]),
        .library(name: "SotoKafkaConnect", targets: ["SotoKafkaConnect"]),
        .library(name: "SotoKendra", targets: ["SotoKendra"]),
        .library(name: "SotoKendraRanking", targets: ["SotoKendraRanking"]),
        .library(name: "SotoKeyspaces", targets: ["SotoKeyspaces"]),
        .library(name: "SotoKinesis", targets: ["SotoKinesis"]),
        .library(name: "SotoKinesisAnalytics", targets: ["SotoKinesisAnalytics"]),
        .library(name: "SotoKinesisAnalyticsV2", targets: ["SotoKinesisAnalyticsV2"]),
        .library(name: "SotoKinesisVideo", targets: ["SotoKinesisVideo"]),
        .library(name: "SotoKinesisVideoArchivedMedia", targets: ["SotoKinesisVideoArchivedMedia"]),
        .library(name: "SotoKinesisVideoMedia", targets: ["SotoKinesisVideoMedia"]),
        .library(name: "SotoKinesisVideoSignaling", targets: ["SotoKinesisVideoSignaling"]),
        .library(name: "SotoKinesisVideoWebRTCStorage", targets: ["SotoKinesisVideoWebRTCStorage"]),
        .library(name: "SotoLakeFormation", targets: ["SotoLakeFormation"]),
        .library(name: "SotoLambda", targets: ["SotoLambda"]),
        .library(name: "SotoLaunchWizard", targets: ["SotoLaunchWizard"]),
        .library(name: "SotoLexModelBuildingService", targets: ["SotoLexModelBuildingService"]),
        .library(name: "SotoLexModelsV2", targets: ["SotoLexModelsV2"]),
        .library(name: "SotoLexRuntimeService", targets: ["SotoLexRuntimeService"]),
        .library(name: "SotoLexRuntimeV2", targets: ["SotoLexRuntimeV2"]),
        .library(name: "SotoLicenseManager", targets: ["SotoLicenseManager"]),
        .library(name: "SotoLicenseManagerLinuxSubscriptions", targets: ["SotoLicenseManagerLinuxSubscriptions"]),
        .library(name: "SotoLicenseManagerUserSubscriptions", targets: ["SotoLicenseManagerUserSubscriptions"]),
        .library(name: "SotoLightsail", targets: ["SotoLightsail"]),
        .library(name: "SotoLocation", targets: ["SotoLocation"]),
        .library(name: "SotoLookoutEquipment", targets: ["SotoLookoutEquipment"]),
        .library(name: "SotoLookoutMetrics", targets: ["SotoLookoutMetrics"]),
        .library(name: "SotoLookoutVision", targets: ["SotoLookoutVision"]),
        .library(name: "SotoM2", targets: ["SotoM2"]),
        .library(name: "SotoMQ", targets: ["SotoMQ"]),
        .library(name: "SotoMTurk", targets: ["SotoMTurk"]),
        .library(name: "SotoMWAA", targets: ["SotoMWAA"]),
        .library(name: "SotoMachineLearning", targets: ["SotoMachineLearning"]),
        .library(name: "SotoMacie2", targets: ["SotoMacie2"]),
        .library(name: "SotoMailManager", targets: ["SotoMailManager"]),
        .library(name: "SotoManagedBlockchain", targets: ["SotoManagedBlockchain"]),
        .library(name: "SotoManagedBlockchainQuery", targets: ["SotoManagedBlockchainQuery"]),
        .library(name: "SotoMarketplaceAgreement", targets: ["SotoMarketplaceAgreement"]),
        .library(name: "SotoMarketplaceCatalog", targets: ["SotoMarketplaceCatalog"]),
        .library(name: "SotoMarketplaceCommerceAnalytics", targets: ["SotoMarketplaceCommerceAnalytics"]),
        .library(name: "SotoMarketplaceDeployment", targets: ["SotoMarketplaceDeployment"]),
        .library(name: "SotoMarketplaceEntitlementService", targets: ["SotoMarketplaceEntitlementService"]),
        .library(name: "SotoMarketplaceMetering", targets: ["SotoMarketplaceMetering"]),
        .library(name: "SotoMarketplaceReporting", targets: ["SotoMarketplaceReporting"]),
        .library(name: "SotoMediaConnect", targets: ["SotoMediaConnect"]),
        .library(name: "SotoMediaConvert", targets: ["SotoMediaConvert"]),
        .library(name: "SotoMediaLive", targets: ["SotoMediaLive"]),
        .library(name: "SotoMediaPackage", targets: ["SotoMediaPackage"]),
        .library(name: "SotoMediaPackageV2", targets: ["SotoMediaPackageV2"]),
        .library(name: "SotoMediaPackageVod", targets: ["SotoMediaPackageVod"]),
        .library(name: "SotoMediaStore", targets: ["SotoMediaStore"]),
        .library(name: "SotoMediaStoreData", targets: ["SotoMediaStoreData"]),
        .library(name: "SotoMediaTailor", targets: ["SotoMediaTailor"]),
        .library(name: "SotoMedicalImaging", targets: ["SotoMedicalImaging"]),
        .library(name: "SotoMemoryDB", targets: ["SotoMemoryDB"]),
        .library(name: "SotoMgn", targets: ["SotoMgn"]),
        .library(name: "SotoMigrationHub", targets: ["SotoMigrationHub"]),
        .library(name: "SotoMigrationHubConfig", targets: ["SotoMigrationHubConfig"]),
        .library(name: "SotoMigrationHubOrchestrator", targets: ["SotoMigrationHubOrchestrator"]),
        .library(name: "SotoMigrationHubRefactorSpaces", targets: ["SotoMigrationHubRefactorSpaces"]),
        .library(name: "SotoMigrationHubStrategy", targets: ["SotoMigrationHubStrategy"]),
        .library(name: "SotoNeptune", targets: ["SotoNeptune"]),
        .library(name: "SotoNeptuneGraph", targets: ["SotoNeptuneGraph"]),
        .library(name: "SotoNeptunedata", targets: ["SotoNeptunedata"]),
        .library(name: "SotoNetworkFirewall", targets: ["SotoNetworkFirewall"]),
        .library(name: "SotoNetworkFlowMonitor", targets: ["SotoNetworkFlowMonitor"]),
        .library(name: "SotoNetworkManager", targets: ["SotoNetworkManager"]),
        .library(name: "SotoNetworkMonitor", targets: ["SotoNetworkMonitor"]),
        .library(name: "SotoNotifications", targets: ["SotoNotifications"]),
        .library(name: "SotoNotificationsContacts", targets: ["SotoNotificationsContacts"]),
        .library(name: "SotoOAM", targets: ["SotoOAM"]),
        .library(name: "SotoOSIS", targets: ["SotoOSIS"]),
        .library(name: "SotoObservabilityAdmin", targets: ["SotoObservabilityAdmin"]),
        .library(name: "SotoOmics", targets: ["SotoOmics"]),
        .library(name: "SotoOpenSearch", targets: ["SotoOpenSearch"]),
        .library(name: "SotoOpenSearchServerless", targets: ["SotoOpenSearchServerless"]),
        .library(name: "SotoOpsWorks", targets: ["SotoOpsWorks"]),
        .library(name: "SotoOpsWorksCM", targets: ["SotoOpsWorksCM"]),
        .library(name: "SotoOrganizations", targets: ["SotoOrganizations"]),
        .library(name: "SotoOutposts", targets: ["SotoOutposts"]),
        .library(name: "SotoPCS", targets: ["SotoPCS"]),
        .library(name: "SotoPI", targets: ["SotoPI"]),
        .library(name: "SotoPanorama", targets: ["SotoPanorama"]),
        .library(name: "SotoPartnerCentralSelling", targets: ["SotoPartnerCentralSelling"]),
        .library(name: "SotoPaymentCryptography", targets: ["SotoPaymentCryptography"]),
        .library(name: "SotoPaymentCryptographyData", targets: ["SotoPaymentCryptographyData"]),
        .library(name: "SotoPcaConnectorAd", targets: ["SotoPcaConnectorAd"]),
        .library(name: "SotoPcaConnectorScep", targets: ["SotoPcaConnectorScep"]),
        .library(name: "SotoPersonalize", targets: ["SotoPersonalize"]),
        .library(name: "SotoPersonalizeEvents", targets: ["SotoPersonalizeEvents"]),
        .library(name: "SotoPersonalizeRuntime", targets: ["SotoPersonalizeRuntime"]),
        .library(name: "SotoPinpoint", targets: ["SotoPinpoint"]),
        .library(name: "SotoPinpointEmail", targets: ["SotoPinpointEmail"]),
        .library(name: "SotoPinpointSMSVoice", targets: ["SotoPinpointSMSVoice"]),
        .library(name: "SotoPinpointSMSVoiceV2", targets: ["SotoPinpointSMSVoiceV2"]),
        .library(name: "SotoPipes", targets: ["SotoPipes"]),
        .library(name: "SotoPolly", targets: ["SotoPolly"]),
        .library(name: "SotoPricing", targets: ["SotoPricing"]),
        .library(name: "SotoPrivateNetworks", targets: ["SotoPrivateNetworks"]),
        .library(name: "SotoProton", targets: ["SotoProton"]),
        .library(name: "SotoQApps", targets: ["SotoQApps"]),
        .library(name: "SotoQBusiness", targets: ["SotoQBusiness"]),
        .library(name: "SotoQConnect", targets: ["SotoQConnect"]),
        .library(name: "SotoQLDB", targets: ["SotoQLDB"]),
        .library(name: "SotoQLDBSession", targets: ["SotoQLDBSession"]),
        .library(name: "SotoQuickSight", targets: ["SotoQuickSight"]),
        .library(name: "SotoRAM", targets: ["SotoRAM"]),
        .library(name: "SotoRDS", targets: ["SotoRDS"]),
        .library(name: "SotoRDSData", targets: ["SotoRDSData"]),
        .library(name: "SotoRUM", targets: ["SotoRUM"]),
        .library(name: "SotoRbin", targets: ["SotoRbin"]),
        .library(name: "SotoRedshift", targets: ["SotoRedshift"]),
        .library(name: "SotoRedshiftData", targets: ["SotoRedshiftData"]),
        .library(name: "SotoRedshiftServerless", targets: ["SotoRedshiftServerless"]),
        .library(name: "SotoRekognition", targets: ["SotoRekognition"]),
        .library(name: "SotoRepostspace", targets: ["SotoRepostspace"]),
        .library(name: "SotoResiliencehub", targets: ["SotoResiliencehub"]),
        .library(name: "SotoResourceExplorer2", targets: ["SotoResourceExplorer2"]),
        .library(name: "SotoResourceGroups", targets: ["SotoResourceGroups"]),
        .library(name: "SotoResourceGroupsTaggingAPI", targets: ["SotoResourceGroupsTaggingAPI"]),
        .library(name: "SotoRoboMaker", targets: ["SotoRoboMaker"]),
        .library(name: "SotoRolesAnywhere", targets: ["SotoRolesAnywhere"]),
        .library(name: "SotoRoute53", targets: ["SotoRoute53"]),
        .library(name: "SotoRoute53Domains", targets: ["SotoRoute53Domains"]),
        .library(name: "SotoRoute53Profiles", targets: ["SotoRoute53Profiles"]),
        .library(name: "SotoRoute53RecoveryCluster", targets: ["SotoRoute53RecoveryCluster"]),
        .library(name: "SotoRoute53RecoveryControlConfig", targets: ["SotoRoute53RecoveryControlConfig"]),
        .library(name: "SotoRoute53RecoveryReadiness", targets: ["SotoRoute53RecoveryReadiness"]),
        .library(name: "SotoRoute53Resolver", targets: ["SotoRoute53Resolver"]),
        .library(name: "SotoS3", targets: ["SotoS3"]),
        .library(name: "SotoS3Control", targets: ["SotoS3Control"]),
        .library(name: "SotoS3Outposts", targets: ["SotoS3Outposts"]),
        .library(name: "SotoS3Tables", targets: ["SotoS3Tables"]),
        .library(name: "SotoSES", targets: ["SotoSES"]),
        .library(name: "SotoSESv2", targets: ["SotoSESv2"]),
        .library(name: "SotoSFN", targets: ["SotoSFN"]),
        .library(name: "SotoSMS", targets: ["SotoSMS"]),
        .library(name: "SotoSNS", targets: ["SotoSNS"]),
        .library(name: "SotoSQS", targets: ["SotoSQS"]),
        .library(name: "SotoSSM", targets: ["SotoSSM"]),
        .library(name: "SotoSSMContacts", targets: ["SotoSSMContacts"]),
        .library(name: "SotoSSMIncidents", targets: ["SotoSSMIncidents"]),
        .library(name: "SotoSSMQuickSetup", targets: ["SotoSSMQuickSetup"]),
        .library(name: "SotoSSO", targets: ["SotoSSO"]),
        .library(name: "SotoSSOAdmin", targets: ["SotoSSOAdmin"]),
        .library(name: "SotoSSOOIDC", targets: ["SotoSSOOIDC"]),
        .library(name: "SotoSTS", targets: ["SotoSTS"]),
        .library(name: "SotoSWF", targets: ["SotoSWF"]),
        .library(name: "SotoSageMaker", targets: ["SotoSageMaker"]),
        .library(name: "SotoSageMakerA2IRuntime", targets: ["SotoSageMakerA2IRuntime"]),
        .library(name: "SotoSageMakerFeatureStoreRuntime", targets: ["SotoSageMakerFeatureStoreRuntime"]),
        .library(name: "SotoSageMakerGeospatial", targets: ["SotoSageMakerGeospatial"]),
        .library(name: "SotoSageMakerMetrics", targets: ["SotoSageMakerMetrics"]),
        .library(name: "SotoSageMakerRuntime", targets: ["SotoSageMakerRuntime"]),
        .library(name: "SotoSagemakerEdge", targets: ["SotoSagemakerEdge"]),
        .library(name: "SotoSavingsPlans", targets: ["SotoSavingsPlans"]),
        .library(name: "SotoScheduler", targets: ["SotoScheduler"]),
        .library(name: "SotoSchemas", targets: ["SotoSchemas"]),
        .library(name: "SotoSecretsManager", targets: ["SotoSecretsManager"]),
        .library(name: "SotoSecurityHub", targets: ["SotoSecurityHub"]),
        .library(name: "SotoSecurityIR", targets: ["SotoSecurityIR"]),
        .library(name: "SotoSecurityLake", targets: ["SotoSecurityLake"]),
        .library(name: "SotoServerlessApplicationRepository", targets: ["SotoServerlessApplicationRepository"]),
        .library(name: "SotoServiceCatalog", targets: ["SotoServiceCatalog"]),
        .library(name: "SotoServiceCatalogAppRegistry", targets: ["SotoServiceCatalogAppRegistry"]),
        .library(name: "SotoServiceDiscovery", targets: ["SotoServiceDiscovery"]),
        .library(name: "SotoServiceQuotas", targets: ["SotoServiceQuotas"]),
        .library(name: "SotoShield", targets: ["SotoShield"]),
        .library(name: "SotoSigner", targets: ["SotoSigner"]),
        .library(name: "SotoSimSpaceWeaver", targets: ["SotoSimSpaceWeaver"]),
        .library(name: "SotoSnowDeviceManagement", targets: ["SotoSnowDeviceManagement"]),
        .library(name: "SotoSnowball", targets: ["SotoSnowball"]),
        .library(name: "SotoSocialMessaging", targets: ["SotoSocialMessaging"]),
        .library(name: "SotoSsmSap", targets: ["SotoSsmSap"]),
        .library(name: "SotoStorageGateway", targets: ["SotoStorageGateway"]),
        .library(name: "SotoSupplyChain", targets: ["SotoSupplyChain"]),
        .library(name: "SotoSupport", targets: ["SotoSupport"]),
        .library(name: "SotoSupportApp", targets: ["SotoSupportApp"]),
        .library(name: "SotoSynthetics", targets: ["SotoSynthetics"]),
        .library(name: "SotoTaxSettings", targets: ["SotoTaxSettings"]),
        .library(name: "SotoTextract", targets: ["SotoTextract"]),
        .library(name: "SotoTimestreamInfluxDB", targets: ["SotoTimestreamInfluxDB"]),
        .library(name: "SotoTimestreamQuery", targets: ["SotoTimestreamQuery"]),
        .library(name: "SotoTimestreamWrite", targets: ["SotoTimestreamWrite"]),
        .library(name: "SotoTnb", targets: ["SotoTnb"]),
        .library(name: "SotoTranscribe", targets: ["SotoTranscribe"]),
        .library(name: "SotoTranscribeStreaming", targets: ["SotoTranscribeStreaming"]),
        .library(name: "SotoTransfer", targets: ["SotoTransfer"]),
        .library(name: "SotoTranslate", targets: ["SotoTranslate"]),
        .library(name: "SotoTrustedAdvisor", targets: ["SotoTrustedAdvisor"]),
        .library(name: "SotoVPCLattice", targets: ["SotoVPCLattice"]),
        .library(name: "SotoVerifiedPermissions", targets: ["SotoVerifiedPermissions"]),
        .library(name: "SotoVoiceID", targets: ["SotoVoiceID"]),
        .library(name: "SotoWAF", targets: ["SotoWAF"]),
        .library(name: "SotoWAFRegional", targets: ["SotoWAFRegional"]),
        .library(name: "SotoWAFV2", targets: ["SotoWAFV2"]),
        .library(name: "SotoWellArchitected", targets: ["SotoWellArchitected"]),
        .library(name: "SotoWisdom", targets: ["SotoWisdom"]),
        .library(name: "SotoWorkDocs", targets: ["SotoWorkDocs"]),
        .library(name: "SotoWorkMail", targets: ["SotoWorkMail"]),
        .library(name: "SotoWorkMailMessageFlow", targets: ["SotoWorkMailMessageFlow"]),
        .library(name: "SotoWorkSpaces", targets: ["SotoWorkSpaces"]),
        .library(name: "SotoWorkSpacesThinClient", targets: ["SotoWorkSpacesThinClient"]),
        .library(name: "SotoWorkSpacesWeb", targets: ["SotoWorkSpacesWeb"]),
        .library(name: "SotoXRay", targets: ["SotoXRay"]),
    ],
    dependencies: [
        .package(url: "https://github.com/soto-project/soto-core.git", from: "7.6.0")
    ],
    targets: [
        .target(
            name: "SotoACM",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ACM",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoACMPCA",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ACMPCA",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAPIGateway",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/APIGateway",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoARCZonalShift",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ARCZonalShift",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAccessAnalyzer",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AccessAnalyzer",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAccount",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Account",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAmp",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Amp",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAmplify",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Amplify",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAmplifyBackend",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AmplifyBackend",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAmplifyUIBuilder",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AmplifyUIBuilder",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoApiGatewayManagementApi",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ApiGatewayManagementApi",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoApiGatewayV2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ApiGatewayV2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAppConfig",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AppConfig",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAppConfigData",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AppConfigData",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAppFabric",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AppFabric",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAppIntegrations",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AppIntegrations",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAppMesh",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AppMesh",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAppRunner",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AppRunner",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAppStream",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AppStream",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAppSync",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AppSync",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAppTest",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AppTest",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAppflow",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Appflow",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoApplicationAutoScaling",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ApplicationAutoScaling",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoApplicationCostProfiler",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ApplicationCostProfiler",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoApplicationDiscoveryService",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ApplicationDiscoveryService",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoApplicationInsights",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ApplicationInsights",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoApplicationSignals",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ApplicationSignals",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoArtifact",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Artifact",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAthena",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Athena",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAuditManager",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AuditManager",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAutoScaling",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AutoScaling",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoAutoScalingPlans",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/AutoScalingPlans",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoB2bi",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/B2bi",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBCMDataExports",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/BCMDataExports",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBCMPricingCalculator",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/BCMPricingCalculator",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBackup",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Backup",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBackupGateway",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/BackupGateway",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBackupSearch",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/BackupSearch",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBatch",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Batch",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBedrock",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Bedrock",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBedrockAgent",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/BedrockAgent",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBedrockAgentRuntime",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/BedrockAgentRuntime",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBedrockDataAutomation",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/BedrockDataAutomation",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBedrockDataAutomationRuntime",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/BedrockDataAutomationRuntime",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBedrockRuntime",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/BedrockRuntime",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBilling",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Billing",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBillingconductor",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Billingconductor",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBraket",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Braket",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoBudgets",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Budgets",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoChatbot",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Chatbot",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoChime",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Chime",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoChimeSDKIdentity",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ChimeSDKIdentity",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoChimeSDKMediaPipelines",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ChimeSDKMediaPipelines",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoChimeSDKMeetings",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ChimeSDKMeetings",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoChimeSDKMessaging",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ChimeSDKMessaging",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoChimeSDKVoice",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ChimeSDKVoice",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCleanRooms",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CleanRooms",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCleanRoomsML",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CleanRoomsML",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloud9",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Cloud9",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudControl",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudControl",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudDirectory",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudDirectory",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudFormation",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudFormation",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudFront",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudFront",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudFrontKeyValueStore",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudFrontKeyValueStore",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudHSM",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudHSM",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudHSMV2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudHSMV2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudSearch",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudSearch",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudSearchDomain",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudSearchDomain",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudTrail",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudTrail",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudTrailData",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudTrailData",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudWatch",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudWatch",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudWatchEvents",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudWatchEvents",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCloudWatchLogs",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CloudWatchLogs",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodeArtifact",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodeArtifact",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodeBuild",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodeBuild",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodeCatalyst",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodeCatalyst",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodeCommit",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodeCommit",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodeConnections",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodeConnections",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodeDeploy",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodeDeploy",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodeGuruProfiler",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodeGuruProfiler",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodeGuruReviewer",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodeGuruReviewer",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodeGuruSecurity",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodeGuruSecurity",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodePipeline",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodePipeline",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodeStarConnections",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodeStarConnections",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCodeStarNotifications",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CodeStarNotifications",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "_SotoCognitoIdentityGenerated",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CognitoIdentity",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCognitoIdentityProvider",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CognitoIdentityProvider",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCognitoSync",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CognitoSync",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoComprehend",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Comprehend",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoComprehendMedical",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ComprehendMedical",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoComputeOptimizer",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ComputeOptimizer",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoConfigService",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ConfigService",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoConnect",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Connect",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoConnectCampaigns",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ConnectCampaigns",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoConnectCampaignsV2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ConnectCampaignsV2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoConnectCases",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ConnectCases",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoConnectContactLens",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ConnectContactLens",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoConnectParticipant",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ConnectParticipant",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoControlCatalog",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ControlCatalog",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoControlTower",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ControlTower",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCostAndUsageReportService",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CostAndUsageReportService",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCostExplorer",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CostExplorer",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCostOptimizationHub",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CostOptimizationHub",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoCustomerProfiles",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/CustomerProfiles",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDAX",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DAX",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDLM",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DLM",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDSQL",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DSQL",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDataBrew",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DataBrew",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDataExchange",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DataExchange",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDataPipeline",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DataPipeline",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDataSync",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DataSync",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDataZone",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DataZone",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDatabaseMigrationService",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DatabaseMigrationService",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDeadline",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Deadline",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDetective",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Detective",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDevOpsGuru",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DevOpsGuru",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDeviceFarm",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DeviceFarm",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDirectConnect",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DirectConnect",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDirectoryService",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DirectoryService",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDirectoryServiceData",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DirectoryServiceData",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDocDB",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DocDB",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDocDBElastic",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DocDBElastic",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDrs",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Drs",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "_SotoDynamoDBGenerated",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DynamoDB",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDynamoDBStreams",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/DynamoDBStreams",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEBS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/EBS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEC2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/EC2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEC2InstanceConnect",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/EC2InstanceConnect",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoECR",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ECR",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoECRPublic",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ECRPublic",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoECS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ECS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEFS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/EFS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEKS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/EKS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEKSAuth",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/EKSAuth",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEMR",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/EMR",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEMRContainers",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/EMRContainers",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEMRServerless",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/EMRServerless",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoElastiCache",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ElastiCache",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoElasticBeanstalk",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ElasticBeanstalk",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoElasticLoadBalancing",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ElasticLoadBalancing",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoElasticLoadBalancingV2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ElasticLoadBalancingV2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoElasticTranscoder",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ElasticTranscoder",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoElasticsearchService",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ElasticsearchService",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEntityResolution",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/EntityResolution",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEventBridge",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/EventBridge",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoEvidently",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Evidently",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoFIS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/FIS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoFMS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/FMS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoFSx",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/FSx",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoFinspace",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Finspace",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoFinspaceData",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/FinspaceData",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoFirehose",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Firehose",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoForecast",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Forecast",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoForecastquery",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Forecastquery",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoFraudDetector",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/FraudDetector",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoFreeTier",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/FreeTier",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGameLift",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/GameLift",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGameLiftStreams",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/GameLiftStreams",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGeoMaps",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/GeoMaps",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGeoPlaces",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/GeoPlaces",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGeoRoutes",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/GeoRoutes",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGlacier",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Glacier",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGlobalAccelerator",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/GlobalAccelerator",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGlue",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Glue",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGrafana",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Grafana",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGreengrass",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Greengrass",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGreengrassV2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/GreengrassV2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGroundStation",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/GroundStation",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoGuardDuty",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/GuardDuty",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoHealth",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Health",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoHealthLake",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/HealthLake",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIAM",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IAM",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIVS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IVS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIVSRealTime",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IVSRealTime",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIdentityStore",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IdentityStore",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoImagebuilder",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Imagebuilder",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoInspector",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Inspector",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoInspector2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Inspector2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoInspectorScan",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/InspectorScan",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoInternetMonitor",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/InternetMonitor",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoInvoicing",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Invoicing",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoT",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoT",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTAnalytics",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTAnalytics",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTDataPlane",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTDataPlane",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTDeviceAdvisor",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTDeviceAdvisor",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTEvents",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTEvents",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTEventsData",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTEventsData",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTFleetHub",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTFleetHub",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTFleetWise",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTFleetWise",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTJobsDataPlane",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTJobsDataPlane",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTManagedIntegrations",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTManagedIntegrations",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTSecureTunneling",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTSecureTunneling",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTSiteWise",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTSiteWise",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTThingsGraph",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTThingsGraph",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTTwinMaker",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTTwinMaker",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIoTWireless",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/IoTWireless",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoIvschat",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Ivschat",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKMS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/KMS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKafka",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Kafka",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKafkaConnect",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/KafkaConnect",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKendra",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Kendra",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKendraRanking",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/KendraRanking",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKeyspaces",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Keyspaces",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKinesis",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Kinesis",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKinesisAnalytics",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/KinesisAnalytics",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKinesisAnalyticsV2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/KinesisAnalyticsV2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKinesisVideo",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/KinesisVideo",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKinesisVideoArchivedMedia",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/KinesisVideoArchivedMedia",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKinesisVideoMedia",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/KinesisVideoMedia",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKinesisVideoSignaling",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/KinesisVideoSignaling",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoKinesisVideoWebRTCStorage",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/KinesisVideoWebRTCStorage",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLakeFormation",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LakeFormation",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLambda",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Lambda",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLaunchWizard",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LaunchWizard",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLexModelBuildingService",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LexModelBuildingService",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLexModelsV2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LexModelsV2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLexRuntimeService",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LexRuntimeService",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLexRuntimeV2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LexRuntimeV2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLicenseManager",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LicenseManager",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLicenseManagerLinuxSubscriptions",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LicenseManagerLinuxSubscriptions",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLicenseManagerUserSubscriptions",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LicenseManagerUserSubscriptions",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLightsail",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Lightsail",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLocation",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Location",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLookoutEquipment",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LookoutEquipment",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLookoutMetrics",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LookoutMetrics",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoLookoutVision",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/LookoutVision",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoM2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/M2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMQ",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MQ",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMTurk",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MTurk",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMWAA",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MWAA",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMachineLearning",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MachineLearning",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMacie2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Macie2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMailManager",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MailManager",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoManagedBlockchain",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ManagedBlockchain",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoManagedBlockchainQuery",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ManagedBlockchainQuery",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMarketplaceAgreement",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MarketplaceAgreement",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMarketplaceCatalog",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MarketplaceCatalog",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMarketplaceCommerceAnalytics",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MarketplaceCommerceAnalytics",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMarketplaceDeployment",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MarketplaceDeployment",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMarketplaceEntitlementService",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MarketplaceEntitlementService",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMarketplaceMetering",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MarketplaceMetering",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMarketplaceReporting",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MarketplaceReporting",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMediaConnect",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MediaConnect",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMediaConvert",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MediaConvert",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMediaLive",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MediaLive",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMediaPackage",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MediaPackage",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMediaPackageV2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MediaPackageV2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMediaPackageVod",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MediaPackageVod",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMediaStore",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MediaStore",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMediaStoreData",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MediaStoreData",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMediaTailor",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MediaTailor",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMedicalImaging",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MedicalImaging",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMemoryDB",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MemoryDB",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMgn",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Mgn",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMigrationHub",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MigrationHub",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMigrationHubConfig",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MigrationHubConfig",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMigrationHubOrchestrator",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MigrationHubOrchestrator",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMigrationHubRefactorSpaces",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MigrationHubRefactorSpaces",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoMigrationHubStrategy",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/MigrationHubStrategy",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoNeptune",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Neptune",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoNeptuneGraph",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/NeptuneGraph",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoNeptunedata",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Neptunedata",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoNetworkFirewall",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/NetworkFirewall",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoNetworkFlowMonitor",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/NetworkFlowMonitor",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoNetworkManager",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/NetworkManager",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoNetworkMonitor",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/NetworkMonitor",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoNotifications",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Notifications",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoNotificationsContacts",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/NotificationsContacts",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoOAM",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/OAM",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoOSIS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/OSIS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoObservabilityAdmin",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ObservabilityAdmin",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoOmics",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Omics",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoOpenSearch",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/OpenSearch",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoOpenSearchServerless",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/OpenSearchServerless",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoOpsWorks",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/OpsWorks",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoOpsWorksCM",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/OpsWorksCM",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoOrganizations",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Organizations",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoOutposts",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Outposts",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPCS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PCS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPI",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PI",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPanorama",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Panorama",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPartnerCentralSelling",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PartnerCentralSelling",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPaymentCryptography",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PaymentCryptography",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPaymentCryptographyData",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PaymentCryptographyData",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPcaConnectorAd",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PcaConnectorAd",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPcaConnectorScep",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PcaConnectorScep",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPersonalize",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Personalize",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPersonalizeEvents",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PersonalizeEvents",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPersonalizeRuntime",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PersonalizeRuntime",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPinpoint",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Pinpoint",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPinpointEmail",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PinpointEmail",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPinpointSMSVoice",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PinpointSMSVoice",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPinpointSMSVoiceV2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PinpointSMSVoiceV2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPipes",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Pipes",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPolly",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Polly",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPricing",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Pricing",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoPrivateNetworks",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/PrivateNetworks",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoProton",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Proton",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoQApps",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/QApps",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoQBusiness",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/QBusiness",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoQConnect",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/QConnect",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoQLDB",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/QLDB",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoQLDBSession",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/QLDBSession",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoQuickSight",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/QuickSight",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRAM",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/RAM",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRDS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/RDS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRDSData",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/RDSData",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRUM",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/RUM",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRbin",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Rbin",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRedshift",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Redshift",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRedshiftData",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/RedshiftData",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRedshiftServerless",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/RedshiftServerless",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRekognition",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Rekognition",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRepostspace",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Repostspace",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoResiliencehub",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Resiliencehub",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoResourceExplorer2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ResourceExplorer2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoResourceGroups",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ResourceGroups",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoResourceGroupsTaggingAPI",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ResourceGroupsTaggingAPI",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRoboMaker",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/RoboMaker",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRolesAnywhere",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/RolesAnywhere",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRoute53",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Route53",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRoute53Domains",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Route53Domains",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRoute53Profiles",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Route53Profiles",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRoute53RecoveryCluster",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Route53RecoveryCluster",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRoute53RecoveryControlConfig",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Route53RecoveryControlConfig",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRoute53RecoveryReadiness",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Route53RecoveryReadiness",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoRoute53Resolver",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Route53Resolver",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "_SotoS3Generated",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/S3",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoS3Control",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/S3Control",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoS3Outposts",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/S3Outposts",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoS3Tables",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/S3Tables",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSES",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SES",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSESv2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SESv2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSFN",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SFN",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSMS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SMS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSNS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SNS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSQS",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SQS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSSM",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SSM",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSSMContacts",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SSMContacts",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSSMIncidents",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SSMIncidents",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSSMQuickSetup",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SSMQuickSetup",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSSO",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SSO",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSSOAdmin",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SSOAdmin",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSSOOIDC",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SSOOIDC",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "_SotoSTSGenerated",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/STS",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSWF",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SWF",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSageMaker",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SageMaker",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSageMakerA2IRuntime",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SageMakerA2IRuntime",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSageMakerFeatureStoreRuntime",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SageMakerFeatureStoreRuntime",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSageMakerGeospatial",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SageMakerGeospatial",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSageMakerMetrics",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SageMakerMetrics",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSageMakerRuntime",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SageMakerRuntime",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSagemakerEdge",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SagemakerEdge",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSavingsPlans",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SavingsPlans",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoScheduler",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Scheduler",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSchemas",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Schemas",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSecretsManager",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SecretsManager",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSecurityHub",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SecurityHub",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSecurityIR",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SecurityIR",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSecurityLake",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SecurityLake",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoServerlessApplicationRepository",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ServerlessApplicationRepository",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoServiceCatalog",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ServiceCatalog",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoServiceCatalogAppRegistry",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ServiceCatalogAppRegistry",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoServiceDiscovery",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ServiceDiscovery",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoServiceQuotas",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/ServiceQuotas",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoShield",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Shield",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSigner",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Signer",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSimSpaceWeaver",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SimSpaceWeaver",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSnowDeviceManagement",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SnowDeviceManagement",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSnowball",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Snowball",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSocialMessaging",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SocialMessaging",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSsmSap",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SsmSap",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoStorageGateway",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/StorageGateway",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSupplyChain",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SupplyChain",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSupport",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Support",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSupportApp",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/SupportApp",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSynthetics",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Synthetics",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoTaxSettings",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/TaxSettings",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoTextract",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Textract",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoTimestreamInfluxDB",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/TimestreamInfluxDB",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoTimestreamQuery",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/TimestreamQuery",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoTimestreamWrite",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/TimestreamWrite",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoTnb",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Tnb",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoTranscribe",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Transcribe",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoTranscribeStreaming",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/TranscribeStreaming",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoTransfer",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Transfer",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoTranslate",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Translate",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoTrustedAdvisor",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/TrustedAdvisor",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoVPCLattice",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/VPCLattice",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoVerifiedPermissions",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/VerifiedPermissions",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoVoiceID",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/VoiceID",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoWAF",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/WAF",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoWAFRegional",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/WAFRegional",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoWAFV2",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/WAFV2",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoWellArchitected",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/WellArchitected",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoWisdom",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/Wisdom",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoWorkDocs",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/WorkDocs",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoWorkMail",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/WorkMail",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoWorkMailMessageFlow",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/WorkMailMessageFlow",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoWorkSpaces",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/WorkSpaces",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoWorkSpacesThinClient",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/WorkSpacesThinClient",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoWorkSpacesWeb",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/WorkSpacesWeb",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoXRay",
            dependencies: [.product(name: "SotoCore", package: "soto-core")],
            path: "./Sources/Soto/Services/XRay",
            swiftSettings: swiftSettings
        ),
        // Service extensions
        .target(
            name: "SotoCognitoIdentity",
            dependencies: [.product(name: "SotoCore", package: "soto-core"), "_SotoCognitoIdentityGenerated"],
            path: "./Sources/Soto/Extensions/CognitoIdentity",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoDynamoDB",
            dependencies: [.product(name: "SotoCore", package: "soto-core"), "_SotoDynamoDBGenerated"],
            path: "./Sources/Soto/Extensions/DynamoDB",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoS3",
            dependencies: [.product(name: "SotoCore", package: "soto-core"), "_SotoS3Generated"],
            path: "./Sources/Soto/Extensions/S3",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SotoSTS",
            dependencies: [.product(name: "SotoCore", package: "soto-core"), "_SotoSTSGenerated"],
            path: "./Sources/Soto/Extensions/STS",
            swiftSettings: swiftSettings
        ),

        .testTarget(
            name: "SotoTests",
            dependencies: [
                "SotoACM",
                "SotoAPIGateway",
                "SotoApiGatewayV2",
                "SotoCloudFront",
                "SotoCloudTrail",
                "SotoDynamoDB",
                "SotoEC2",
                "SotoGlacier",
                "SotoIAM",
                "SotoLambda",
                "SotoRoute53",
                "SotoS3",
                "SotoS3Control",
                "SotoSES",
                "SotoSNS",
                "SotoSQS",
                "SotoSSM",
                "SotoSTS",
                "SotoTimestreamWrite",
            ]
        ),
    ]
)
