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

    let auth = Auth.auth()
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

        try await saveUserDetails(user, false)
        return user
    }


    private func saveUserDetails(_ user: UserEntity,_ isNew: Bool) async throws {
        guard let uid = user.id else {
            throw AuthError.invalidUserId
        }
        try await db.collection("users").document(uid).setData(user.toDictionary())
    }

    private func updateUserTimestamp(_ user: UserEntity) async throws {
        guard let uid = user.id else {
            throw AuthError.invalidUserId
        }
        try await db.collection("users").document(uid).updateData([
            "updated_at": Timestamp(date: user.updatedAt)
        ])
    }

    func signIn(email: String, password: String) async throws -> UserEntity {
        let result = try await auth.signIn(withEmail: email, password: password)

        let userDoc = try await db.collection("users").document(result.user.uid).getDocument()

        if userDoc.exists, let data = userDoc.data(),
           let existingUser = UserEntity.fromDictionary(data, id: result.user.uid) {
            var updatedUser = existingUser
            updatedUser.updatedAt = Date()
            try await updateUserTimestamp(updatedUser)
            return updatedUser
        } else {
            let user = UserEntity(
                id: result.user.uid,
                email: email,
                authProvider: .email
            )
            try await saveUserDetails(user, true)
            return user
        }
    }

    @MainActor
    func googleSignIn() async throws -> UserEntity {

        guard let topVC = UIApplication.shared.topViewController() else {
            throw AuthError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.unknown
        }

        let accessToken = result.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user

        let isNewUser = authResult.additionalUserInfo?.isNewUser ?? true

        if isNewUser {
            let userEntity = UserEntity(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                fullName: firebaseUser.displayName ?? "",
                authProvider: .google,
                createdAt: Date(),
                notificationsEnabled: true,
                isPremium: false
            )
            try await saveUserDetails(userEntity, true)
            return userEntity
        } else {
            let userDoc = try await db.collection("users").document(firebaseUser.uid).getDocument()

            if userDoc.exists, let data = userDoc.data(),
               var existingUser = UserEntity.fromDictionary(data, id: firebaseUser.uid) {
                existingUser.updatedAt = Date()
                try await updateUserTimestamp(existingUser)
                return existingUser
            } else {
                let userEntity = UserEntity(
                    id: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    fullName: firebaseUser.displayName ?? "",
                    authProvider: .google,
                    createdAt: Date(),
                    notificationsEnabled: true,
                    isPremium: false
                )
                try await saveUserDetails(userEntity, true)
                return userEntity
            }
        }
    }

    func signOut() throws {
        try auth.signOut()
    }
}


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
    case userCancelled
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
        case .userCancelled: return nil
        case .unknown: return "An unknown error occurred."
        }
    }
}

extension AuthError {
    init(from firebaseError: NSError) {
        if firebaseError.domain == "com.google.GIDSignIn" && firebaseError.code == -5 {
            self = .userCancelled
            return
        }

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
        }
    }
}

extension AuthError: Equatable {
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.userNotFound, .userNotFound),
             (.invalidUserId, .invalidUserId),
             (.noRootViewController, .noRootViewController),
             (.googleConfigurationError, .googleConfigurationError),
             (.googleTokenError, .googleTokenError),
             (.notImplemented, .notImplemented),
             (.weakPassword, .weakPassword),
             (.emailAlreadyInUse, .emailAlreadyInUse),
             (.invalidEmail, .invalidEmail),
             (.wrongPassword, .wrongPassword),
             (.networkError, .networkError),
             (.userCancelled, .userCancelled),
             (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}
