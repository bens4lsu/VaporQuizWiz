import Fluent
import Vapor

func routes(_ app: Application, _ passports: Passports, _ settings: ConfigurationSettings, _ logger: Logger) throws {
    
    try app.register(collection: WebRouteController(passports: passports, settings: settings, logger: logger))
    try app.register(collection: APIRouteController(passports: passports, settings: settings, logger: logger))
    
    app.get { req async in
        
        
        let oneEncoded = try BenCrypt.encode("1", keys: settings.cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let twoEncoded = try BenCrypt.encode("2", keys: settings.cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        logger.debug("http://localhost:8080/\(oneEncoded)")
        logger.debug("http://localhost:8080/\(twoEncoded)")
        
        return """
            Successfully connected to passport host.
        
            WARNING:  The below information should be removed before deploying assessments for production:
        
            https://passports.candjinnovations.com/\(oneEncoded)
            https://passports.candjinnovations.com/\(twoEncoded)
        """
        
    }
}
