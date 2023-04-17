
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    
    let walkawayPassport = try PassportModel(app, forPassportType: .walkaway)
    let expansionPassport = try PassportModel(app, forPassportType: .expansion)
    let passports: Passports = [.walkaway: walkawayPassport, .expansion: expansionPassport]
    
    
    // register routes

    try routes(app, passports)
    
}
