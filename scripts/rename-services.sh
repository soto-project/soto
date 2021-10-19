#!/bin/sh

function moveService() {
    oldName=$1
    name=$2
    
    git mv --force Sources/Soto/Services/"$oldName"/"$oldName"_API.swift Sources/Soto/Services/"$name"/"$name"_API.swift
    git mv --force Sources/Soto/Services/"$oldName"/"$oldName"_Error.swift Sources/Soto/Services/"$name"/"$name"_Error.swift
    git mv --force Sources/Soto/Services/"$oldName"/"$oldName"_Shapes.swift Sources/Soto/Services/"$name"/"$name"_Shapes.swift
    if [ -f Sources/Soto/Services/"$name"/"$name"_Paginator.swift ]; then
        git mv --force Sources/Soto/Services/"$oldName"/"$oldName"_Paginator.swift Sources/Soto/Services/"$name"/"$name"_Paginator.swift
    fi
    if [ -f Sources/Soto/Services/"$name"/"$name"_Waiter.swift ]; then
        git mv --force Sources/Soto/Services/"$oldName"/"$oldName"_Waiter.swift Sources/Soto/Services/"$name"/"$name"_Waiter.swift
    fi
}

moveService CodeStarconnections CodeStarConnections
moveService CostandUsageReportService CostAndUsageReportService
moveService ElasticLoadBalancingv2 ElasticLoadBalancingV2
moveService FinSpaceData FinspaceData
moveService SESV2 SESv2
