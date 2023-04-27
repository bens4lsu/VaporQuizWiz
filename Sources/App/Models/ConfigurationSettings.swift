//
//  File.swift
//
//
//  Created by Ben Schultz on 10/9/22.
//

import Vapor
import NIOSSL
import wkhtmltopdf

class ConfigurationSettings: Decodable {
    
    struct Database: Decodable {
        let hostname: String
        let port: Int
        let username: String
        let password: String
        let database: String
        let certificateVerificationString: String
    }
    
    struct CryptKeys: Decodable {
        let keyStr: String
        let iv: String
    }
    
    struct Wkhtmltopdf: Decodable {
        let path: String
        let zoom: String
        let top: Int
        let right: Int
        let bottom: Int
        let left: Int
        let size: String
        
        var document: Document {
            Document(size: self.size, zoom: self.zoom, top: self.top, right: self.right, bottom: self.bottom, left: self.left, path: self.path)
        }
    }
    
    let database: ConfigurationSettings.Database
    let logLevel: String
    let cryptKeys: ConfigurationSettings.CryptKeys
    let listenOnPort: Int
    let wkhtmltopdf: Wkhtmltopdf
    
    var certificateVerification: CertificateVerification {
        if database.certificateVerificationString == "noHostnameVerification" {
            return .noHostnameVerification
        }
        else if database.certificateVerificationString == "fullVerification" {
            return .fullVerification
        }
        return .none
    }
    
    var loggerLogLevel: Logger.Level {
        Logger.Level(rawValue: logLevel) ?? .error
    }

    
    init() {
        let path = DirectoryConfiguration.detect().resourcesDirectory
        let url = URL(fileURLWithPath: path).appendingPathComponent("Config.json")
        do {
            let data = try Data(contentsOf: url)
            let decoder = try JSONDecoder().decode(ConfigurationSettings.self, from: data)
            self.database = decoder.database
            self.logLevel = decoder.logLevel
            self.cryptKeys = decoder.cryptKeys
            self.listenOnPort = decoder.listenOnPort
            self.wkhtmltopdf = decoder.wkhtmltopdf
        }
        catch {
            print ("Could not initialize app from Config.json. \n \(error)")
            exit(0)
        }
    }
}

