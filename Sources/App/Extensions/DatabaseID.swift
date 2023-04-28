//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/27/23.
//

import Foundation
import Vapor
import Fluent
import FluentMySQLDriver

extension DatabaseID {
    static let emailDb = DatabaseID(string: "emailDb")
}

//static func configureDatabase(_ app: Application) throws {
//    try app.databases.use(.mysql(hostname: <#T##String#>, username: <#T##String#>, password: <#T##String#>), as: .emailDb)
//}
