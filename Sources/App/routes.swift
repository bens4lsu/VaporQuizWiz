import Fluent
import Vapor

func routes(_ app: Application, _ passports: Passports, _ settings: ConfigurationSettings, _ logger: Logger) throws {
    
    try app.register(collection: WebRouteController(passports: passports, settings: settings, logger: logger))
    try app.register(collection: APIRouteController(passports: passports, settings: settings, logger: logger))
    
    app.get { req async throws -> View in
        
        struct Context: Encodable {
            let message: String
        }
        
        let oneEncoded = try BenCrypt.encode("1", keys: settings.cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let twoEncoded = try BenCrypt.encode("2", keys: settings.cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
        let oneSeventyTwoEncoded = try BenCrypt.encode("172", keys: settings.cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
        let context = Context(message: """
            Successfully connected to passport host.
        
            WARNING:  The below information should be removed before deploying assessments for production.
        
            
            Run as new user --
        
                 Walkaway:  <a href="/\(oneEncoded)">https://passports.candjinnovations.com/\(oneEncoded)</a>
            
                 Expansion: <a href="/\(twoEncoded)">https://passports.candjinnovations.com/\(twoEncoded)</a>
        
        
           See reports for previously-takeen assessments:
        
                Walkawway mixed: <a href="/report/\(oneEncoded)/\(oneSeventyTwoEncoded)">https://passports.candjinnovations.com/report/\(oneEncoded)/\(oneSeventyTwoEncoded)</a>
        
            See qa summary for previously-takeen assessments:
                
                Walkawway mixed: <a href="/qasummary/\(oneEncoded)/\(oneSeventyTwoEncoded)">https://passports.candjinnovations.com/qasummary/\(oneEncoded)/\(oneSeventyTwoEncoded)</a>
        
        """)
        
        return try await req.view.render("message", context)
        
    }
}
