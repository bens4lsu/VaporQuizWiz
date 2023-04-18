
import Vapor
import Fluent
import FluentMySQLDriver

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    
    let walkawayPassport = try PassportModel(app, forPassportType: .walkaway)
    let expansionPassport = try PassportModel(app, forPassportType: .expansion)
    let passports: Passports = [.walkaway: walkawayPassport, .expansion: expansionPassport]
    
    let settings = ConfigurationSettings()
    
    var logger = Logger(label: "logger")
    logger.logLevel = settings.loggerLogLevel
    #if DEBUG
    logger.debug("Running in debug.")
    #endif
    
    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = settings.certificateVerification
    
    
    app.databases.use(.mysql(
        hostname: settings.database.hostname,
        port: settings.database.port,
        username: settings.database.username,
        password: settings.database.password,
        database: settings.database.database,
        tlsConfiguration: tls
    ), as: .mysql)
    
    
    // register routes

    try routes(app, passports, settings, logger)
    
    #if DEBUG
    let oneEncoded = try BenCrypt.encode("1", keys: settings.cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!

    logger.debug("http://localhost:8080/\(oneEncoded)")
    #endif
}
