import Foundation
import Vapor


final class AssessmentContext: Content {
    let id: Int
    let name: String
    let disclosureText: String
    let passportModel: PassportModel
    let logoFileName: String
    let companyContactInfo: String
    let aidEncrypted: String
    
    var aidEncryptedForUrl: String {
        aidEncrypted.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
    }
    
    init(_ req: Request, id: Int, passports: Passports, keys: ConfigurationSettings.CryptKeys) async throws {
        let assessment = try await Assessment.find(id, on: req.db)
        
        guard let id = assessment?.id,
              let name = assessment?.name,
              let disclosureText = assessment?.disclosureText,
              let logoFileName = assessment?.logoFileName,
              let companyContactInfo = assessment?.companyContactInfo
        else {
            throw Abort (.internalServerError, reason: "Error loading assessment \(id) from database.")
        }
        
        self.id = id
        self.name = name
        self.disclosureText = disclosureText
        self.logoFileName = logoFileName
        self.companyContactInfo = companyContactInfo
        
        guard let walkaway = passports[.walkaway],
              let expansion = passports[.expansion]
        else {
            throw Abort(.internalServerError, reason: "passports[.walkaway] or passports[.expansion] not properly intitialized.")
        }
        
        if name.lowercased().contains("walkaway") {
            self.passportModel = walkaway
        }
        else if name.lowercased().contains("expansion") {
            self.passportModel = expansion
        }
        else {
            throw Abort(.internalServerError, reason: "Can not initialize passport model.  Assessment name should contain either \"Walkaway\" or \"Expansion\"")
        }
        
        self.aidEncrypted = try BenCrypt.encode(String(id), keys: keys)
    }
    
    
}
