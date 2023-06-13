import Vapor
import Leaf

struct WebRouteController: RouteCollection {
    
    let adminC: AdminController
    var ac: AssessmentController { adminC.ac }
    var settings: ConfigurationSettings { adminC.ac.settings }
    var logger: Logger { adminC.ac.logger }

    
    init(adminController: AdminController) {
        self.adminC = adminController
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(":aid", use: newInstance)
        routes.post("evaluation", use: processAssessment)
        routes.get("report", ":aid", ":instance", use: report)
        routes.get("qAndASummary", ":aid", ":instance", use: qaSummary)
        routes.get("pdf", "**", use: pdfLanding)
        routes.get("pdfresult", ":page", ":aid", ":instance", use: returnPdf )
        routes.get("pdf-footer", use: pdfFooter)
        routes.get("x", use:admin)
    }
    
    
    private func newInstance(_ req: Request) async throws -> View {
        guard let aidStr = req.parameters.get("aid"),
              let aid = try Int(BenCrypt.decode(aidStr, keys: settings.cryptKeys))
        else {
            throw Abort(.badRequest, reason: "Invalid assessment token")
        }
        let instance = try await ac.new(req, aid: aid)
        return try await req.view.render("QPage", instance)
    }

    
    private func report(_ req: Request) async throws -> View {
        let (aidStr, instanceStr) = try aidAndInstance(req)
        let context = try await ac.reportContext(req, aidStr: aidStr, instanceStr: instanceStr)
        print (context)
        return try await req.view.render("Report", context)
    }
    
    
    private func qaSummary(_ req: Request) async throws -> View {
        let (aidStr, instanceStr) = try aidAndInstance(req)
        let context = try await ac.reportContext(req, aidStr: aidStr, instanceStr: instanceStr)
        return try await req.view.render("QASummary", context)
    }
    
    private func processAssessment(_ req: Request) async throws -> Response {
        let variables = try req.content.decode([String: String].self)
//        for (key, value) in variables {
//            print("\(key): \(value)")
//        }
        let result = try await ac.processResponse(req, variables: variables)
        switch result {
        case .success(let resultContext):
            return try await req.view.render("Report", resultContext).encodeResponse(for: req)
        case .failure(let redirectPath):
            return req.redirect(to: redirectPath)
        }
    }
    
    private func pdfLanding(_ req: Request) async throws -> View {
        try await req.view.render("PDFLander")
    }
    
    private func returnPdf (_ req: Request) async throws -> Response {
        
        guard let pageType = req.parameters.get("page"),
              let pdfPageType = PDFPageType(rawValue: pageType)
        else {
            throw Abort(.badRequest, reason: "PDF file requested with invalid document type.")
        }
        let (aidStr, instanceStr) = try aidAndInstance(req)
        return try await ac.pageToPDF(req, pageType: pdfPageType, aidStr: aidStr, instanceStr: instanceStr)
    }
    
    private func pdfFooter (_ req: Request) async throws -> View {
        struct Context: Content {
            let page: String
            let ofPage: String
        }
        
        let queryParameters = try req.query.decode([String:String].self)
        //logger.debug("\(queryParameters["topage"])")
        let page = queryParameters["page"] ?? ""
        let ofPage = queryParameters["topage"] ?? "11"
        return try await req.view.render("PdfFooter", Context(page: page, ofPage: ofPage))
    }
    
    
    private func aidAndInstance(_ req: Request) throws -> (String, String) {
        guard let aidStr = req.parameters.get("aid"),
              let instanceStr = req.parameters.get("instance")
        else {
            throw Abort(.badRequest, reason: "Invalid assessment or instance token on request for report")
        }
        return (aidStr, instanceStr)
    }
    
    private func admin(_ req: Request) async throws -> View {
        try await req.view.render("Admin", adminC.adminContext(req))
    }
    
    
    
}
