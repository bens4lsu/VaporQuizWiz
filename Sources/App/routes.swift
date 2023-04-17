import Fluent
import Vapor

func routes(_ app: Application, _ passports: Passports, _ settings: ConfigurationSettings) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }
    
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    try app.register(collection: RouteController(passports: passports, settings: settings))
    
}
