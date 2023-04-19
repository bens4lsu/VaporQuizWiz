//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/18/23.
//

import Foundation
import Vapor

class ResourceFileManager {
    
    static func readFile(_ filename: String, inPath: String, app: Application) throws -> String {
        let path = app.directory.resourcesDirectory
            .appending(inPath + "/")
            .appending(filename)
        let contents = try String(contentsOfFile: path)
        return contents
    }
    
    static func parseLabels(_ fileContents: String, filename: String) throws -> [String] {
        let lines = fileContents.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        guard lines.count == 8 else {
            throw Abort(.internalServerError, reason: "file at \(filename) improperly configured.  Should contain eight lines of text.")
        }
        return lines
    }
}
