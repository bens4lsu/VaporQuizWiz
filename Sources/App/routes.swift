import Fluent
import Vapor
import wkhtmltopdf

func routes(_ app: Application, _ passports: Passports, _ settings: ConfigurationSettings, _ logger: Logger) throws {
    
    try app.register(collection: WebRouteController(passports: passports, settings: settings, logger: logger))
    try app.register(collection: APIRouteController(passports: passports, settings: settings, logger: logger))
    
    app.get { req async throws -> View in
        
        struct Context: Encodable {
            let oneEncoded: String
            let twoEncoded: String
            let oneSeventyTwoEncoded: String
        }
        
        let oneEncoded = try BenCrypt.encode("1", keys: settings.cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let twoEncoded = try BenCrypt.encode("2", keys: settings.cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let oneSeventyTwoEncoded = try BenCrypt.encode("172", keys: settings.cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
        let context = Context(oneEncoded: oneEncoded, twoEncoded: twoEncoded, oneSeventyTwoEncoded: oneSeventyTwoEncoded)
        return try await req.view.render("message", context)
        
    }
    
    
    #if DEBUG
    app.get("pdftest") { req async throws -> Response in
        // Create document. Margins in mm, can be set individually or all at once.
        // If no margins are set, the default is 20mm.
        let document = Document(margins: 15)
        // Create a page from an HTML string.
        
        let docContent = try await ResourceFileManager.dataFromSource(req, url: "https://cnn.com")
        let page1 = Page(docContent)
        
        document.pages = [page1]
        // Render to a PDF
        let pdf = document.generatePDF(on: req.application.threadPool, eventLoop: req.eventLoop)
        // Now you can return the PDF as a response, if you want
        return try await pdf.map { data in
            return Response(
                status: .ok,
                headers: HTTPHeaders([("Content-Type", "application/pdf")]),
                body: .init(data: data)
            )
        }.get()
    }
    #endif
}


