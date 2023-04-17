//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/17/23.
//

import Foundation
import Vapor

class BenCrypt {
        
    class func encode(_ text:String) throws -> String {
        let key = SymmetricKey(data: BenCrypt.keyStr.data(using: .utf8)!)
        let nonce = try AES.GCM.Nonce(data: iv.data(using: .utf8)!)
        let encrypted = try AES.GCM.seal(text.data(using: .utf8)!, using: key, nonce: nonce)
        return encrypted.combined!.base64EncodedString()
    }
    
    class func decode(_ text:String) throws -> String {
        let key = SymmetricKey(data: BenCrypt.keyStr.data(using: .utf8)!)
        guard let cipherdata = Data(base64Encoded: text, options: .ignoreUnknownCharacters) else {
            throw Abort (.internalServerError, reason: "Bad ciphertext passed to BenCrypt.decode")
        }
        let sealedBox = try AES.GCM.SealedBox(combined: cipherdata)
        let decrypted = try AES.GCM.open(sealedBox, using: key)
        return String(decoding: decrypted, as: UTF8.self)
    }
    
}
