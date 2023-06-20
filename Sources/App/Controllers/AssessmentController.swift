//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/14/23.
//

import Foundation
import Vapor
import Fluent
import wkhtmltopdf

class AssessmentController {
    
    enum ResponseStatus: Content {
        case success(AssessmentInstanceReportContext)
        case failure(String)  // string is for redirect page
    }
    
    let passports: Passports
    let logger: Logger
    let settings: ConfigurationSettings
    var cryptKeys: ConfigurationSettings.CryptKeys { settings.cryptKeys }
    var host: ConfigurationSettings.Host { settings.host }
    var emailConfig: ConfigurationSettings.Email { settings.email }
    var baseString: String { settings.baseString }
    
    var makeDocument: () -> Document
    
    init(passports: Passports, logger: Logger, settings: ConfigurationSettings) {
        self.passports = passports
        self.logger = logger
        self.settings = settings
        
        let footerString = settings.baseString + "/pdf-footer?page=[page]&topage=[topage]"   // the wkhtmltopdf program replaces [page] and [topage] with the correct numbers.
        let wkArgs = ["--footer-html", footerString]
        
        self.makeDocument = {
            Document(size: settings.wkhtmltopdf.size
                     , zoom: settings.wkhtmltopdf.zoom
                     , top: settings.wkhtmltopdf.top
                     , right: settings.wkhtmltopdf.right
                     , bottom: settings.wkhtmltopdf.bottom
                     , left: settings.wkhtmltopdf.left
                     , path: settings.wkhtmltopdf.path
                     , wkArgs: wkArgs)
        }
    }
    
    // MARK:  Passport methods
    
    func new(_ req: Request, aid: Int) async throws -> AssessmentInstanceContext {
        try await AssessmentInstanceContext(req, forAssessmentId: aid, passports: passports, keys: cryptKeys)
    }
    
    
    func existingContext(_ req: Request, aid: Int, instance: Int) async throws -> AssessmentInstanceContext {
        return try await AssessmentInstanceContext(req, assessmentId: aid, instance: instance, passports: passports, keys:cryptKeys)
    }
    
    
    func reportContext(_ req: Request, aidStr: String, instanceStr: String) async throws -> AssessmentInstanceReportContext {
        let decodedAid = (try? BenCrypt.decode(aidStr, keys: cryptKeys)) ?? ""
        let decodedInstance = (try? BenCrypt.decode(instanceStr, keys: cryptKeys)) ?? ""
                
        guard let aid = Int(decodedAid),
              let instance = Int(decodedInstance)
        else {
            throw Abort (.badRequest, reason: "Invalid assessment ID or instance ID token passed in request to retrieve report")
        }
        
        let assessmentInstanceReportContext = try await existingContext(req, aid: aid, instance: instance).reportContext(req, withDetails: [], host: host)
        var assessmentInstanceDetails = [AssessmentInstanceDetailContext]()
        
        
        guard let passport = passports[assessmentInstanceReportContext.passportType] else {
            throw Abort (.internalServerError, reason: "Could not find domain list for \(assessmentInstanceReportContext.passportType)")
        }
        
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for domain in passport.domains {
                async let context = try getResponseRow(req, assessmentInstanceId: instance, domainType: domain.domainType)?
                    .context(app: req.application, passportModel: passport)
                if let addme = try await context {
                    assessmentInstanceDetails.append(addme)
                }
            }
        }
        assessmentInstanceReportContext.updateDetails(details: assessmentInstanceDetails)
        return assessmentInstanceReportContext
        
    }

    
    
    func processResponse(_ req: Request, variables: [String: String]) async throws -> ResponseStatus {
        
        let decodedAid = (try? BenCrypt.decode(variables["aid"] ?? "", keys: cryptKeys)) ?? ""
        let decodedInstance = (try? BenCrypt.decode(variables["instance"] ?? "", keys: cryptKeys)) ?? ""
        
        guard let aid = Int(decodedAid),
              let instance = Int(decodedInstance),
              let passportTypeString = variables["passportType"],
              let passportType = PassportType(rawValue: passportTypeString),
              let name = variables["name"],
              let email = variables["email"]
        else {
            logger.debug("Error validating aid, instance, or passportType:  aid = \(variables["aid"] ?? "nil"), instance = \(variables["instance"] ?? "nil"), passportType = \(variables["passportType"] ?? "nil")")
            return try await handleErrorResponse(req, variables)
        }
        
        let assessmentInstanceContext = try await existingContext(req, aid: aid, instance: instance)
        assessmentInstanceContext.name = name
        assessmentInstanceContext.email = email
        var resultRowsToUpdate = [AssessmentInstanceDetail]()
        var resultRowsContext = [AssessmentInstanceDetailContext]()
        
        for i in 1...8 {
            let labelNow = "single_\(i)a"
            let labelGoal = "single_\(i)b"
            
            guard let ansNow = validAnswer(variables[labelNow]),
                  let ansGoal = validAnswer(variables[labelGoal]),
                  let passportModel = passports[passportType]
            else {
                logger.debug("Error validating numeric responses or domain type:  ansNow = \(variables[labelNow] ?? "nil"), ansGoal = \(variables[labelGoal] ?? "nil"), passportDomainType = \(passports[passportType]?.domains[i].domainType.rawValue ?? "nil")")
                return try await handleErrorResponse(req, variables)
            }
            
            let passportDomain = passportModel.domains[i-1]
            let aiResult = AssessmentInstanceDetail(assessmentId: aid, assessmentInstanceId: instance, passportDomainType: passportDomain.domainType, now: ansNow, goal: ansGoal)
            resultRowsToUpdate.append(aiResult)
            
            let resultRowContext = AssessmentInstanceDetailContext(app: req.application, aid: aid, order: i, domain: passportDomain, now: ansNow, goal: ansGoal)
            resultRowsContext.append(resultRowContext)
        }
        
        // save answers to database
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            
            for i in 0..<resultRowsToUpdate.count {
                let row = resultRowsToUpdate[i]
                async let _ = try updateResponseRow(req, row: row)
            }
            let tmpInstance = try await existingInstance(req, aic: assessmentInstanceContext)
            async let _ = updateInstance(req, instance: tmpInstance, name: name, email: email)
            if emailConfig.enableEmailSend {
                async let _ = requestEmailNotifications(req, assessmentInstanceContext: assessmentInstanceContext)
            }
            else {
                logger.info("Skipping email send due to configuration.")
            }
        }
        
        // save additional info answers to database
        let additionalFields = assessmentInstanceContext.assessment.additionalQuestions
        for field in additionalFields {
            if let answer = variables[field.id] {
                try await AssessmentAdditionalInfo(assessmentInstanceId: assessmentInstanceContext.id,
                                                   assessmentId: assessmentInstanceContext.assessment.id,
                                                   additionalInfoKey: field.id, additionalInfoValue: answer)
                    .save(on: req.db)
            }
        }
        
        let resultContext = try assessmentInstanceContext.reportContext(req, withDetails: resultRowsContext, host: host)
        return .success(resultContext)
    }
    
    
    func pageToPDF(_ req: Request, pageType: PDFPageType, aidStr: String, instanceStr: String) async throws -> Response {
        let port = req.application.http.server.configuration.port
        let htmlPage = "http://localhost:\(port)/\(pageType.pathPartForHtmlVersion)/\(aidStr.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)/\(instanceStr.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        let docContent = try await ResourceFileManager.dataFromSource(req, url: htmlPage)
        let page1 = Page(docContent)
        //let document = Document(size: "Letter", zoom: "1.3", top: 10, right: 10, bottom: 10, left: 10, wkArgs: wkArgs)
        let document = makeDocument()
        document.pages = [page1]
        let pdf = try await document.generatePDF(on: req.application.threadPool, eventLoop: req.eventLoop).get()
        return Response(status: .ok, headers: HTTPHeaders([("Content-Type", "application/pdf")]), body: .init(data: pdf))
    }
    
//    func reportPdfLink(aic: AssessmentInstanceContext) -> String {
//        "\(baseString)/pdf/report/\(aic.assessment.aidEncryptedForUrl))/\(aic.instanceIdEncryptedForUrl)"
//    }
//
//    func qaPdfLink(aic: AssessmentInstanceContext) -> String {
//        "\(baseString)/pdf/qAndASummary/\(aic.assessment.aidEncryptedForUrl)/\(aic.instanceIdEncryptedForUrl)"
//    }
    
    
    // MARK: Private
    
    private func validAnswer(_ answer: String?) -> Int? {
        guard let answer = answer,
              let int = Int(answer)
        else {
            return nil
        }
        guard int <= 12 && int >= 1 else {
            return nil
        }
        return int
    }
    
    
    private func handleErrorResponse(_ req: Request, _ variables: [String: String]) async throws -> ResponseStatus {
        guard let aid = Int(variables["aid"] ?? "") else {
            throw Abort (.internalServerError, reason: "Form submitted without data to identify the assessment being used.")
        }
        let aidStr = try BenCrypt.encode(String(aid), keys: cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        return .failure("/\(aidStr)")
    }
    
    
    private func updateInstance(_ req: Request, instance: AssessmentInstance, name: String, email: String) async throws {
        instance.name = name
        instance.email = email
        instance.dateComplete = Date()
        try await instance.update(on: req.db)
    }
    
    
    private func existingInstance(_ req: Request, aic: AssessmentInstanceContext) async throws -> AssessmentInstance {
        let instance = aic.id
        guard let assessmentInstance = try await AssessmentInstance.find(instance, on: req.db) else {
            throw Abort(.internalServerError, reason: "Assessment instance not found for id \(aic.id)")
        }
        return assessmentInstance
    }
    
    
    private func updateResponseRow(_ req: Request, row: AssessmentInstanceDetail) async throws {
        if let aidRow = try await getResponseRow(req, assessmentInstanceId: row.assessmentInstanceId, domainType: row.passportDomainType) {
            try await aidRow.update(on: req.db)
        }
        else {
            let aidRow = AssessmentInstanceDetail(assessmentId: row.assessmentId, assessmentInstanceId: row.assessmentInstanceId, passportDomainType: row.passportDomainType, now: row.now, goal: row.goal)
            try await aidRow.save(on: req.db)
        }
    }
    
    
    private func getResponseRow(_ req: Request, assessmentInstanceId: Int, domainType: PassportDomainType) async throws -> AssessmentInstanceDetail? {
        try await AssessmentInstanceDetail.query(on: req.db)
            .filter(\.$assessmentInstanceId == assessmentInstanceId)
            .filter(\.$passportDomainType == domainType)
            .first()
    }
    
    private func requestEmailNotifications(_ req: Request, assessmentInstanceContext: AssessmentInstanceContext) async throws {
        struct SubjectContext: Content {
            let assessmentName: String
        }
        
        struct BodyContext: Content {
            let takerName: String
            let takerEmail: String
            let reportLink: String
            let qaLink: String
            let assessmentName: String
        }
        
        guard let name = assessmentInstanceContext.name,
              let email = assessmentInstanceContext.email
        else {
            throw Abort (.internalServerError, reason: "Attempt to send email without name or email address.")
        }
        
        async let distributionListTask = emailDistributionList(req, assessmentId: assessmentInstanceContext.assessment.id)
        let subjectContext = SubjectContext(assessmentName: assessmentInstanceContext.assessment.name)
        let reportPdfLink = baseString + assessmentInstanceContext.reportLinkPdf
        let qaPdfLink = baseString + assessmentInstanceContext.qaLinkPdf
        let bodyContext = BodyContext(takerName: name, takerEmail: email, reportLink: reportPdfLink, qaLink: qaPdfLink, assessmentName: assessmentInstanceContext.assessment.name)
        
        async let subjectLineTask = ResourceFileManager.viewToString(req, "EmailSubject", subjectContext)
        async let bodyTask = ResourceFileManager.viewToString(req, "EmailBody", bodyContext)
        
        let (subjectLine, body, distributionList) = (try await subjectLineTask, try await bodyTask, try await distributionListTask)
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for recipient in distributionList {
                let mailqEntry = MailQueue(emailAddressFrom: emailConfig.fromAddress, emailAddressTo: recipient, subject: subjectLine, body: body, fromName: emailConfig.fromName)
                async let _ = mailqEntry.save(on: req.db(.emailDb))
            }
        }
    }
    
    private func emailDistributionList(_ req: Request, assessmentId: Int) async throws -> [String] {
        try await AssessmentEmail.query(on: req.db).filter(\.$assessmentId == assessmentId).all().map { row in
            row.emailAddress
        }
    }
}
