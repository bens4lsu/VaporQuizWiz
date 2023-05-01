
import Vapor
import Fluent
import FluentMySQLDriver
import Leaf

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    
    let walkawayPassport = try PassportModel(app, forPassportType: .walkaway)
    let expansionPassport = try PassportModel(app, forPassportType: .expansion)
    let passports: Passports = [.walkaway: walkawayPassport, .expansion: expansionPassport]
    
    let settings = ConfigurationSettings()
    
    app.http.server.configuration.port = settings.host.listenOnPort

    
    var logger = Logger(label: "logger")
    logger.logLevel = settings.loggerLogLevel
    #if DEBUG
    logger.debug("Running in debug.")
    
    let threeEncrypted = try BenCrypt.encode("3", keys: settings.cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    let fourEncrypted = try BenCrypt.encode("4", keys: settings.cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    
    logger.debug("link for Walkaway: /a/\(threeEncrypted ?? "")")
    logger.debug("link for Expansion: /a/\(fourEncrypted ?? "")")
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
    
    app.databases.use(.mysql(
        hostname: settings.database.hostname,
        port: settings.database.port,
        username: settings.database.username,
        password: settings.database.password,
        database: "Mailer",
        tlsConfiguration: tls
    ), as: .emailDb)
    
    app.views.use(.leaf)
    app.leaf.tags["indexedValue"] = IndexedValue()
    
    
    // Serves files from `Public/` directory
    let fileMiddleware = FileMiddleware(
        publicDirectory: app.directory.publicDirectory
    )
    app.middleware.use(fileMiddleware)
    
    
    
    // register routes

    try routes(app, passports, settings, logger)
    
    print ("\(app.http.server.configuration.hostname)   \(app.http.server.configuration.port)   \(app.http.client.configuration.httpVersion)")
 
}
