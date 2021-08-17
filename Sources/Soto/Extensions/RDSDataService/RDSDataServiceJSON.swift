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

import Foundation

public struct RDSDataServiceDecoder {
    
    private static func parseField(field: RDSDataService.Field) -> Any? {
        if let arrayValue = field.arrayValue { return arrayValue }
        if let blobValue = field.blobValue { return blobValue }
        if let booleanValue = field.booleanValue { return booleanValue }
        if let doubleValue = field.doubleValue { return doubleValue }
        if let isNull = field.isNull { return isNull }
        if let longValue = field.longValue { return longValue }
        if let stringValue = field.stringValue { return stringValue }
        return nil
    }

    private static func parseTable(executeStatementResponse: RDSDataService.ExecuteStatementResponse) -> [[String: Any]] {
        let table = getRecords(executeStatementResponse: executeStatementResponse)
        let columns = getColumnNames(executeStatementResponse: executeStatementResponse)
        var finalTable = [[String: Any]]()
        
        for tableRow in table {
            let row = parseRow(row: tableRow, columns: columns)
            finalTable.append(row)
        }
        
        return finalTable
    }
    
    private static func parseTableToDictionary(executeStatementResponse: RDSDataService.ExecuteStatementResponse) -> [[String: Any]] {
        let table = parseTable(executeStatementResponse: executeStatementResponse)
        var finalJSON = [[String: Any]]()

        
        func parseRowToJSON(row: [String: Any]) -> [String: Any] {
            var rowJSON = [String: Any]()
            let firstRowKeys = row.keys
            for key in firstRowKeys {
                rowJSON[key] = row[key]
            }
            return rowJSON
        }
        
        _ = table.map { row in
            let currentRowJSON = parseRowToJSON(row: row)
            finalJSON.append(currentRowJSON)
        }
        
        return finalJSON
    }
    
    fileprivate static func parseTableToJSONString(executeStatementResponse: RDSDataService.ExecuteStatementResponse) throws -> String {
        let json = parseTableToDictionary(executeStatementResponse: executeStatementResponse)
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
        let jsonString = String(data: jsonData, encoding: String.Encoding.ascii) ?? ""
        return jsonString
    }
    
    fileprivate static func parseTableToJSONData(executeStatementResponse: RDSDataService.ExecuteStatementResponse) throws -> Data {
        let json = parseTableToDictionary(executeStatementResponse: executeStatementResponse)
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        return jsonData
    }
    
    private static func getColumnNames(executeStatementResponse: RDSDataService.ExecuteStatementResponse) -> [String] {
        let columnMetadata = executeStatementResponse.columnMetadata
        let columnNames = columnMetadata.map { columns -> [String] in
            return columns.map { $0.name ?? "" }.compactMap { $0 }
        } ?? []
        return columnNames
    }
    
}

extension RDSDataService.ExecuteStatementResponse {
    /// This function is part of the RDSDataService.ExecuteStatementResponse object. It can be called on self and returns a JSON string with the database results.
    /// - Returns: JSON string with the database results
    public func jsonString() throws -> String {
        return try RDSDataServiceDecoder.parseTableToJSONString(executeStatementResponse: self)
    }
    
    /// This function is part of the RDSDataService.ExecuteStatementResponse object. It can be called on self and returns a JSON data with the database results.
    /// - Returns: JSON data with the database results
    public func jsonData() throws -> Data {
        return try RDSDataServiceDecoder.parseTableToJSONData(executeStatementResponse: self)
    }
}
