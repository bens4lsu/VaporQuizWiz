//
//  File.swift
//
//
//  Created by Ben Schultz on 1/22/21.
//

import Foundation
import Vapor
import Fluent
import FluentMySQLDriver

class SecurityController: RouteCollection {
    
    let settings: ConfigurationSettings
    let logger: Logger
    let baseUrl: String
    
    init(_ settings: ConfigurationSettings, _ logger: Logger, baseUrl: String) {
        self.settings = settings
        self.logger = logger
        self.baseUrl = baseUrl
    }
    
    
    func boot(routes: RoutesBuilder) throws {
        routes.group("security") { group in
            group.get("login", use: renderLogin)
            group.get("change-password", use: renderUserCreate)
            group.get("request-password-reset", use: renderPasswordResetForm)
            group.get("check-email", use: renderCheckEmail)
            group.get("password-reset-process", ":resetString", use: verifyPasswordResetRequest)
            group.post("login", use: login)
            group.post("request-password-reset", use: sendPWResetEmail)
            group.post("password-reset-process", ":resetString", use: verifyAndChangePassword)
        }
    }
    
    // MARK:  Methods connected to routes that return Views
    private func renderLogin(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("users-login")
    }
    
    private func renderUserCreate(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("users-create")
    }
    
    
    private func renderCheckEmail(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("users-password-check-email")
    }
    
    
    // MARK:  Methods connected to routes that return data
    
    private func login(_ req: Request) async throws -> Response {
        struct Form: Content {
            var email: String?
            var password: String?
        }
        
        let content = try req.content.decode(Form.self)
        
        guard let email = content.email, let password = content.password else {
            throw Abort(.badRequest)
        }
        
        guard email.count > 0, password.count > 0 else {
            throw Abort(.badRequest)
        }
        
        let userMatches = try await User.query(on: req.db).filter(\.$emailAddress == email).all()
        
        let user: User =  try {
            guard userMatches.count < 2 else {
                throw Abort(.unauthorized, reason: "More than one user exists with that email address.")
            }
            
            guard userMatches.count == 1 else {
                throw Abort(.unauthorized, reason: "No user exists for that email address.")
            }
            
            let user = userMatches[0]
            
            // verify that password submitted matches
            guard try Bcrypt.verify(password, created: user.passwordHash) else {
                throw Abort(.unauthorized, reason: "Could not verify password.")
            }
            
            // login success
            guard user.isActive else {
                throw Abort(.unauthorized, reason: "User's system access has been revoked.")
            }
            // figure out which repos user has permission to see, and update the session.
            // done
            return user
        }()
        
        SessionController.setUserId(req, user.id!)
        SessionController.setIsAdmin(req, user.isAdmin)
        
        return req.redirect(to: "/x")
    }
    
    
    // MARK: Static methods - used for verification in other controllers
    
    static func redirectToLogin(_ req: Request) -> EventLoopFuture<Response> {
        SessionController.kill(req)
        return req.eventLoop.makeSucceededFuture(req.redirect(to: "./security/login"))
    }
    
    static func userAuthorized(_ req: Request) throws -> Bool {
        return try SessionController.getUserId(req) == nil
    }
}


// MARK:  Password reset methods

extension SecurityController {
    
    private func renderPasswordResetForm(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("users-password-reset")
    }
    
    private func sendPWResetEmail(_ req: Request) async throws -> Response {
        struct Form: Content {
            var emailAddress: String?
        }
        
        struct Context: Content {
            var resetLink: String
        }
        
        let content = try req.content.decode(Form.self)
        let email = content.emailAddress ?? ""
        
        guard email.count > 0 else {
            throw Abort(.badRequest, reason:  "No email address received for password reset.")
        }
        
        let userMatches = try await User.query(on: req.db).filter(\.$emailAddress == email).all()
        let user: User = try {
            guard userMatches.count < 2 else {
                throw Abort(.unauthorized, reason: "More than one user exists with that email address.")
            }
            
            guard userMatches.count == 1 else {
                throw Abort(.unauthorized, reason: "No user exists for that email address.")
            }
            
            let user = userMatches[0]
            return user
        }()
        let userId = user.id!
        let resetRequest = PasswordResetRequest(id: nil, exp: Date().addingTimeInterval(TimeInterval(settings.resetKeyExpDuration)), userId: userId)
        try await resetRequest.save(on: req.db)  // sets resetRequest.id
                            
        let resetKey: String = try {
            guard let resetKey = resetRequest.id?.uuidString else {
                throw Abort(.internalServerError, reason: "Error getting unique key for tracking password reset request.")
            }
            return resetKey
        }()
                        
        // TODO:  Delete expired keys
        // TODO:  Delete any older (even unexpired) keys for this user.
        
        let resetLink = "\(baseUrl)/security/password-reset-process/\(resetKey)"
        let emailBodyContext = Context(resetLink: resetLink)
        let body = try await ResourceFileManager.viewToString(req, "EmailBodyPwReset", emailBodyContext)
        let subject = try await ResourceFileManager.viewToString(req, "EmailSubjectPwReset", "")
        let mailqEntry = MailQueue(emailAddressFrom: settings.email.fromAddress, emailAddressTo: user.emailAddress, subject: subject, body: body, fromName: settings.email.fromName)
        try await mailqEntry.save(on: req.db(.emailDb))
        return req.redirect(to: "/security/check-email")
    }
    
    
    private func verifyKey(_ req: Request, resetKey: String) async throws -> PasswordResetRequest {
        
        guard let uuid = UUID(resetKey) else {
            throw Abort(.badRequest, reason: "No reset token read in request for password reset.")
        }
        
        let resetRequestW = try await PasswordResetRequest.query(on: req.db).filter(\.$id == uuid).filter(\.$exp >= Date()).first()
        guard let resetRequest = resetRequestW else {
            throw Abort(.badRequest, reason: "Reset link was invalid or expired.")
        }
        return resetRequest
    }
     
    
    private func verifyPasswordResetRequest(req: Request) async throws -> View {
        print (req.parameters)
        guard let parameter = req.parameters.get("resetString") else {
            throw Abort(.badRequest, reason: "Invalid password reset parameter received.")
        }
        
        let _ = try await verifyKey(req, resetKey: parameter)
        let context = ["resetKey" : parameter]
        return try await req.view.render("users-password-change-form", context)
    }
    
    private func verifyAndChangePassword(req: Request) async throws -> View {
        struct PostVars: Content {
            let pw1: String
            let pw2: String
            let resetKey: String
        }
        
        let vars = try req.content.decode(PostVars.self)
        let pw1 = vars.pw1
        let pw2 = vars.pw2
        let resetKey = vars.resetKey
        
        guard let _ = UUID(vars.resetKey) else {
            throw Abort(.badRequest, reason: "Invalid password reset key.")
        }
        
        
        
        guard pw1 == pw2 else {
            throw Abort(.badRequest, reason: "Form submitted two passwords that don't match.")
        }
        
        let resetRequest: PasswordResetRequest = try await verifyKey(req, resetKey: resetKey)
  
        #warning("bms - password enforcement")
        // TODO:  enforce minimum password requirement (configuration?)
        // TODO:  verify no white space.  any other invalid characrters?
                
        let changeTask = try await changePassword(req, userId: resetRequest.userId, newPassword: pw1)
        return try await req.view.render("users-password-change-success")
    }
    
    func changePassword(_ req: Request, userId: UUID, newPassword: String) async throws -> HTTPResponseStatus {
        let userMatch = try await User.query(on:req.db).filter(\.$id == userId).all()
        let user = userMatch[0]
        let passwordHash = try Bcrypt.hash(newPassword)
        user.passwordHash = passwordHash
        try await user.save(on: req.db)
        return HTTPResponseStatus.ok
    }
}

