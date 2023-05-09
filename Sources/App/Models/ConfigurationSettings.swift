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
        let mailDb: String
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
    }
    
    struct Host: Decodable, Encodable {
        let listenOnPort: Int
        let proto: String
        let server: String
    }
    
    struct Email: Decodable {
        let fromName: String
        let fromAddress: String
        let enableEmailSend: Bool
    }
    
    let database: ConfigurationSettings.Database
    let logLevel: String
    let cryptKeys: ConfigurationSettings.CryptKeys
    let wkhtmltopdf: Wkhtmltopdf
    let host: Host
    let email: Email
    let resetKeyExpDuration: Int
    let minPWCharacters: Int
    
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
    
    var baseString: String {
        var portStr = ":\(self.host.listenOnPort)"
        if self.host.server != "localhost" && self.host.server != "127.0.0.1" {
            portStr = ""
        }
        return  "\(self.host.proto)://\(self.host.server)\(portStr)"
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
            self.wkhtmltopdf = decoder.wkhtmltopdf
            self.host = decoder.host
            self.email = decoder.email
            self.resetKeyExpDuration = decoder.resetKeyExpDuration
            self.minPWCharacters = decoder.minPWCharacters
        }
        catch {
            print ("Could not initialize app from Config.json. \n \(error)")
            exit(0)
        }
    }
}

