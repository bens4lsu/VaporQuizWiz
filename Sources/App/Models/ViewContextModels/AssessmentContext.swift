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
    let introText: String
    let aboveTitle: String
    let additionalQuestions: [CustomQuestion]
    let nameQuestionNumber: Int
    let emailQuestionNumber: Int
    let reportAdditionalStylesheet: String?
    let qaAdditionalStylesheet: String?
    
    var aidEncryptedForUrl: String {
        aidEncrypted.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
    }
    
    var urlForNewInstance: String {
        let cs = ConfigurationSettings()
        return cs.baseString + "/" + aidEncryptedForUrl
    }
    
    var embedCode: String {
        """
        <iframe src="\(urlForNewInstance)" style="width:100%; height:800px;display:block; margin-left:auto; margin-right:auto;" frameborder="0" scrolling="no" id="MQWcontent" name="MQWcontent"></iframe><script type="text/javascript"> function receiveMessage(event) {   if (! isNaN(event.data)) {  var iframe = document.getElementById('MQWcontent');  iframe.style.height = iframe.height = event.data + "px"; }  document.body.scrollTop = document.documentElement.scrollTop = 0; }  if(typeof window.addEventListener != 'undefined'){  window.addEventListener('message', receiveMessage, false); } else if(typeof window.attachEvent != 'undefined') {  window.attachEvent('onmessage', receiveMessage); }</script>
        """
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
        self.reportAdditionalStylesheet = assessment?.reportAdditionalStylesheet
        self.qaAdditionalStylesheet = assessment?.qaAdditionalStylesheet
        
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
        
        let filename = "intro-\(passportModel.passportType.rawValue).htm"
        let path = "SurveyIntros/\(id)"
        let customIntroText = try? ResourceFileManager.readFile(filename, inPath: path, app: req.application)
        self.introText = customIntroText ?? passportModel.intro

        self.aboveTitle = (try? ResourceFileManager.readFile("above-title.htm", inPath: path, app: req.application)) ?? ""
        
        let path2 = "AdditionalInfo/\(id)"
        let additionalQuestions = (try? ResourceFileManager.customQuestionsFrom(app: req.application, folderPath: path2)) ?? [CustomQuestion]()
        nameQuestionNumber = additionalQuestions.count + 9
        emailQuestionNumber = additionalQuestions.count + 10
        self.additionalQuestions = additionalQuestions
    }
    
    
}
