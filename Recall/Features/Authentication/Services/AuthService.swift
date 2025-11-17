//
//  AuthService.swift
//  Recall
//
//  Created by GU on 17/11/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import SwiftUI


class AuthService {
        static let shared = AuthService()
       private init() {}
       
       private let auth = Auth.auth()
       private let db = Firestore.firestore()
       
       var currentFirebaseUser: User? {
           auth.currentUser
       }
    
    
    func SignUp(email: String, password: String) async throws -> UserEntity {
        let result = try await auth.createUser(withEmail: email, password: password)
        
        let user = UserEntity(
            id: result.user.uid,
            email: email,
            authProvider: .email
            
        )
        
        return user
    }
    
    
    private func saveUserDetails(_ user: UserEntity) async throws {
        guard let uid = user.id else {
            throw AuthError.invalidUserId
        }
        try await db.collection("users").document(uid).setData(user.toDictionary())
        print("User stored !")
    }
    
    
}

import FirebaseAuth

enum AuthError: LocalizedError {
    case userNotFound
    case invalidUserId
    case noRootViewController
    case googleConfigurationError
    case googleTokenError
    case notImplemented
    case weakPassword
    case emailAlreadyInUse
    case invalidEmail
    case wrongPassword
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .userNotFound: return "User not found. Please sign up first."
        case .invalidUserId: return "Invalid user ID."
        case .noRootViewController: return "Unable to present sign in screen."
        case .googleConfigurationError: return "Google Sign In configuration error."
        case .googleTokenError: return "Failed to get Google authentication token."
        case .notImplemented: return "This feature is not yet implemented."
        case .weakPassword: return "Password should be at least 6 characters."
        case .emailAlreadyInUse: return "This email is already registered."
        case .invalidEmail: return "Please enter a valid email address."
        case .wrongPassword: return "Incorrect password. Please try again."
        case .networkError: return "Network error. Please check your connection."
        case .unknown: return "An unknown error occurred."
        }
    }
}

extension AuthError {
    init(from firebaseError: NSError) {
        if let code = AuthErrorCode(rawValue: firebaseError.code) {
            switch code {
            case .weakPassword: self = .weakPassword
            case .emailAlreadyInUse: self = .emailAlreadyInUse
            case .invalidEmail: self = .invalidEmail
            case .wrongPassword: self = .wrongPassword
            case .networkError: self = .networkError
            case .userNotFound: self = .userNotFound
            default: self = .unknown
            }
        } else {
            self = .unknown
            print("Unmapped Firebase error: \(firebaseError.localizedDescription) (\(firebaseError.code))")
        }
    }
}
