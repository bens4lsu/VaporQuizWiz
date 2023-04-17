import Fluent
import Vapor

struct RouteController: RouteCollection {
    
    let ac: AssessmentController
     
    
    init(passports: Passports) {
        self.ac = AssessmentController(passports: passports)
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(":aid", use: newInstance)
    }

    private func newInstance(_ req: Request) async throws -> Response {
        guard let aidStr = req.parameters.get("aid"),
              let aid = try Int(BenCrypt.decode(aidStr))
        else {
            throw Abort(.badRequest, reason: "Invalid assessment token")
        }
        
        return try await ac.new(req, aid: aid).encodeResponse(for: req)
    }
    
    //private func presentation(_ req: Request, ) async throws
}
