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
import AuthenticationServices
import CryptoKit


class AuthService {
    static let shared = AuthService()
    private init() {}
    
    let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private var currentNonce: String?
    
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
    

    @MainActor
    func signInWithApple() async throws -> UserEntity {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authController = ASAuthorizationController(authorizationRequests: [request])
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = AppleSignInDelegate(continuation: continuation, currentNonce: nonce, authService: self)
            authController.delegate = delegate
            authController.presentationContextProvider = delegate
            
            objc_setAssociatedObject(authController, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            DispatchQueue.main.async {
                authController.performRequests()
            }
        }
    }
    

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func processAppleSignIn(credential: ASAuthorizationAppleIDCredential, nonce: String) async throws -> UserEntity {
        guard let idToken = credential.identityToken else {
            throw AuthError.unknown
        }
        
        guard let idTokenString = String(data: idToken, encoding: .utf8) else {
            throw AuthError.unknown
        }
        
        let firebaseCredential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                              rawNonce: nonce,
                                                              fullName: credential.fullName)
        
        let authResult = try await Auth.auth().signIn(with: firebaseCredential)
        let firebaseUser = authResult.user
        
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let isNewUser = authResult.additionalUserInfo?.isNewUser ?? true
        
        if isNewUser {
            let userEntity = UserEntity(
                id: firebaseUser.uid,
                email: credential.email ?? firebaseUser.email ?? "",
                fullName: fullName.isEmpty ? firebaseUser.displayName ?? "" : fullName,
                authProvider: .apple,
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
                    email: credential.email ?? firebaseUser.email ?? "",
                    fullName: fullName.isEmpty ? firebaseUser.displayName ?? "" : fullName,
                    authProvider: .apple,
                    createdAt: Date(),
                    notificationsEnabled: true,
                    isPremium: false
                )
                try await saveUserDetails(userEntity, true)
                return userEntity
            }
        }
    }
}


class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<UserEntity, Error>
    private let currentNonce: String
    private let authService: AuthService
    
    init(continuation: CheckedContinuation<UserEntity, Error>, currentNonce: String, authService: AuthService) {
        self.continuation = continuation
        self.currentNonce = currentNonce
        self.authService = authService
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            Task {
                do {
                    let userEntity = try await authService.processAppleSignIn(credential: appleIDCredential, nonce: currentNonce)
                    continuation.resume(returning: userEntity)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } else {
            continuation.resume(throwing: AuthError.unknown)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                continuation.resume(throwing: AuthError.userCancelled)
            case .failed:
                continuation.resume(throwing: AuthError.unknown)
            case .invalidResponse:
                continuation.resume(throwing: AuthError.unknown)
            case .notHandled:
                continuation.resume(throwing: AuthError.unknown)
            case .unknown:
                continuation.resume(throwing: AuthError.unknown)
            @unknown default:
                continuation.resume(throwing: AuthError.unknown)
            }
        } else {
            continuation.resume(throwing: error)
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = UIApplication.shared.currentWindow {
            return window
        }
        
        if let windowScene = UIApplication.shared.firstWindowScene {
            return UIWindow(windowScene: windowScene)
        }
        
        return UIWindow()
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
    case appleSignInNotSupported
    case appleSignInMissingEntitlements
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
        case .appleSignInNotSupported: return "Apple Sign-In is not supported on this device."
        case .appleSignInMissingEntitlements: return "Apple Sign-In is not properly configured. Please contact support."
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
        
        if firebaseError.domain == "com.apple.AuthenticationServices.AuthorizationError" {
            switch firebaseError.code {
            case 1001:
                self = .userCancelled
                return
            case 1000:
                self = .unknown
                return
            case 1002:
                self = .unknown
                return
            case 1003:
                self = .unknown
                return
            case 1004:
                self = .unknown
                return
            default:
                self = .unknown
                return
            }
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
             (.appleSignInNotSupported, .appleSignInNotSupported),
             (.appleSignInMissingEntitlements, .appleSignInMissingEntitlements),
             (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}
