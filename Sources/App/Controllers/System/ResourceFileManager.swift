//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/18/23.
//

import Foundation
import Vapor
import wkhtmltopdf


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
    
    static func dataFromSource(_ req: Request, url: String) async throws -> String {
        let uri = URI(string: url)
        let headers = HTTPHeaders([("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0")])
        let response = try await req.client.get(uri, headers: headers).get()
        
        guard var body = response.body,
              let returnString = body.readString(length: body.readableBytes)
        else {
            throw Abort (.internalServerError, reason: "Unable to read response from \(url)")
        }
        return returnString
    }
    
    
    static func viewToString(_ req: Request, _ template: String, _ context: any Content) async throws -> String {
        let data = try await req.view.render(template, context).get().data
        return String(buffer: data).replacingOccurrences(of: "&amp;", with: "&")
    }

}
