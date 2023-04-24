import Fluent
import Vapor

func routes(_ app: Application, _ passports: Passports, _ settings: ConfigurationSettings, _ logger: Logger) throws {
    
    try app.register(collection: WebRouteController(passports: passports, settings: settings, logger: logger))
    try app.register(collection: APIRouteController(passports: passports, settings: settings, logger: logger))
    
    app.get { req async in
        "Succesfully connected to Passport Host."
        
    }
}
