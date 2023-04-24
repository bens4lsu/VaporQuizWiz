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
        
        let context = Context(message: """
            Successfully connected to passport host.
        
            WARNING:  The below information should be removed before deploying assessments for production:
        
            https://passports.candjinnovations.com/\(oneEncoded)
            https://passports.candjinnovations.com/\(twoEncoded)
        """)
        
        return try await req.view.render("message", context)
        
    }
}
