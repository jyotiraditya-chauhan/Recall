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
       
       private let auth = Auth.auth()
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
        print("User stored !")
    }
    
    private func updateUserTimestamp(_ user: UserEntity) async throws {
        guard let uid = user.id else {
            throw AuthError.invalidUserId
        }
        try await db.collection("users").document(uid).updateData([
            "updated_at": Timestamp(date: user.updatedAt)
        ])
        print("User timestamp updated!")
    }
    
    func signIn(email: String, password: String) async throws -> UserEntity {
        let result = try await auth.signIn(withEmail: email, password: password)
        
        // Fetch existing user data from Firestore
        let userDoc = try await db.collection("users").document(result.user.uid).getDocument()
        
        if userDoc.exists, let data = userDoc.data(),
           let existingUser = UserEntity.fromDictionary(data, id: result.user.uid) {
            // Update the updatedAt field for existing user
            var updatedUser = existingUser
            updatedUser.updatedAt = Date()
            try await updateUserTimestamp(updatedUser)
            return updatedUser
        } else {
            // Create new user record if doesn't exist
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
            print("Unable to find top view controller")
            throw AuthError.noRootViewController
        }


        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)


        guard let idToken = result.user.idToken?.tokenString else {
            print("Unable to fetch Google ID token")
            throw AuthError.unknown
        }

        let accessToken = result.user.accessToken.tokenString

    
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: accessToken)


        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user
        
        

        let isNewUser = authResult.additionalUserInfo?.isNewUser ?? true
        
        if isNewUser {
            // New user - create complete profile
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
            print("🔥 Google Sign-In Success (New User): \(firebaseUser.email ?? "")")
            return userEntity
        } else {
            // Existing user - fetch from Firestore and update timestamp
            let userDoc = try await db.collection("users").document(firebaseUser.uid).getDocument()
            
            if userDoc.exists, let data = userDoc.data(),
               var existingUser = UserEntity.fromDictionary(data, id: firebaseUser.uid) {
                existingUser.updatedAt = Date()
                try await updateUserTimestamp(existingUser)
                print("🔥 Google Sign-In Success (Existing User): \(existingUser.email)")
                return existingUser
            } else {
                // Fallback - create new user if Firestore data doesn't exist
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
                print("🔥 Google Sign-In Success (Fallback New User): \(firebaseUser.email ?? "")")
                return userEntity
            }
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    

    @MainActor
    func signInWithApple() async throws -> UserEntity {
        print("🍎 Starting Apple Sign-In process...")
        
        // Check if Apple Sign-In is available
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        // For iOS 13.0+, Apple Sign-In should always be available on actual devices
        // But let's add some basic checks
        print("🍎 Apple Sign-In provider created successfully")
        
        let nonce = randomNonceString()
        currentNonce = nonce
        print("🍎 Generated nonce: \(nonce)")
        
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        print("🍎 Created authorization request with scopes: fullName, email")
        print("🍎 SHA256 nonce: \(sha256(nonce))")
        
        let authController = ASAuthorizationController(authorizationRequests: [request])
        print("🍎 Created authorization controller")
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = AppleSignInDelegate(continuation: continuation, currentNonce: nonce, authService: self)
            authController.delegate = delegate
            authController.presentationContextProvider = delegate
            
            print("🍎 Set delegate and presentation context provider")
            
            // Keep reference to prevent deallocation
            objc_setAssociatedObject(authController, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            print("🍎 About to perform requests...")
            DispatchQueue.main.async {
                authController.performRequests()
                print("🍎 performRequests() called")
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
        print("🍎 processAppleSignIn called")
        print("🍎 Nonce: \(nonce)")
        
        guard let idToken = credential.identityToken else {
            print("🍎 ERROR: No identity token in credential")
            throw AuthError.unknown
        }
        
        guard let idTokenString = String(data: idToken, encoding: .utf8) else {
            print("🍎 ERROR: Cannot convert identity token to string")
            throw AuthError.unknown
        }
        
        print("🍎 Identity token string obtained successfully")
        
        print("🍎 Creating Firebase credential...")
        let firebaseCredential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                              rawNonce: nonce,
                                                              fullName: credential.fullName)
        
        print("🍎 Signing in with Firebase...")
        let authResult = try await Auth.auth().signIn(with: firebaseCredential)
        print("🍎 Firebase sign-in successful")
        let firebaseUser = authResult.user
        
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let isNewUser = authResult.additionalUserInfo?.isNewUser ?? true
        
        if isNewUser {
            // New user - create complete profile
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
            print("🍎 Apple Sign-In Success (New User): \(userEntity.email)")
            return userEntity
        } else {
            // Existing user - fetch from Firestore and update timestamp
            let userDoc = try await db.collection("users").document(firebaseUser.uid).getDocument()
            
            if userDoc.exists, let data = userDoc.data(),
               var existingUser = UserEntity.fromDictionary(data, id: firebaseUser.uid) {
                existingUser.updatedAt = Date()
                try await updateUserTimestamp(existingUser)
                print("🍎 Apple Sign-In Success (Existing User): \(existingUser.email)")
                return existingUser
            } else {
                // Fallback - create new user if Firestore data doesn't exist
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
                print("🍎 Apple Sign-In Success (Fallback New User): \(userEntity.email)")
                return userEntity
            }
        }
    }
}

// MARK: - Apple Sign-In Delegate
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
        print("🍎 Apple Sign-In: didCompleteWithAuthorization called")
        print("🍎 Authorization type: \(type(of: authorization.credential))")
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            print("🍎 Apple ID Credential received")
            print("🍎 User ID: \(appleIDCredential.user)")
            print("🍎 Email: \(appleIDCredential.email ?? "No email")")
            print("🍎 Full Name: \(appleIDCredential.fullName?.description ?? "No name")")
            print("🍎 Identity Token: \(appleIDCredential.identityToken != nil ? "Present" : "Missing")")
            print("🍎 Authorization Code: \(appleIDCredential.authorizationCode != nil ? "Present" : "Missing")")
            
            Task {
                do {
                    let userEntity = try await authService.processAppleSignIn(credential: appleIDCredential, nonce: currentNonce)
                    continuation.resume(returning: userEntity)
                } catch {
                    print("🍎 Error in processAppleSignIn: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        } else {
            print("🍎 ERROR: Authorization credential is not ASAuthorizationAppleIDCredential")
            continuation.resume(throwing: AuthError.unknown)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("🍎 Apple Sign-In: didCompleteWithError called")
        print("🍎 Error: \(error)")
        print("🍎 Error domain: \(error._domain)")
        print("🍎 Error code: \(error._code)")
        
        if let authError = error as? ASAuthorizationError {
            print("🍎 ASAuthorizationError code: \(authError.code.rawValue)")
            print("🍎 ASAuthorizationError description: \(authError.localizedDescription)")
            
            switch authError.code {
            case .canceled:
                print("🍎 User cancelled Apple Sign-In")
                continuation.resume(throwing: AuthError.userCancelled)
            case .failed:
                print("🍎 Apple Sign-In failed")
                continuation.resume(throwing: AuthError.unknown)
            case .invalidResponse:
                print("🍎 Invalid response from Apple Sign-In")
                continuation.resume(throwing: AuthError.unknown)
            case .notHandled:
                print("🍎 Apple Sign-In not handled")
                continuation.resume(throwing: AuthError.unknown)
            case .unknown:
                print("🍎 Unknown Apple Sign-In error")
                continuation.resume(throwing: AuthError.unknown)
            @unknown default:
                print("🍎 Unknown Apple Sign-In error case")
                continuation.resume(throwing: AuthError.unknown)
            }
        } else {
            print("🍎 Non-ASAuthorizationError: \(error)")
            continuation.resume(throwing: error)
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = UIApplication.shared.currentWindow {
            return window
        }
        
        // Fallback to creating a new window if needed
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
        // Check for Google Sign-In cancellation (error code -5)
        if firebaseError.domain == "com.google.GIDSignIn" && firebaseError.code == -5 {
            self = .userCancelled
            return
        }
        
        // Check for Apple Sign-In specific errors
        if firebaseError.domain == "com.apple.AuthenticationServices.AuthorizationError" {
            print("🍎 Apple Sign-In AuthorizationError: \(firebaseError.code)")
            switch firebaseError.code {
            case 1001: // ASAuthorizationError.canceled
                self = .userCancelled
                return
            case 1000: // ASAuthorizationError.unknown  
                self = .unknown
                return
            case 1002: // ASAuthorizationError.invalidResponse
                self = .unknown
                return
            case 1003: // ASAuthorizationError.notHandled
                self = .unknown
                return
            case 1004: // ASAuthorizationError.failed
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
            print("⚠️ Unmapped Firebase error: \(firebaseError.localizedDescription) (\(firebaseError.code))")
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
