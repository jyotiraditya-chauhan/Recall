//
//  AuthenticationViewModel.swift
//  Recall
//
//  Created by Aditya Chauhan on 17/11/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

protocol AuthenticationViewModelProtocol {
    func login(email: String, password: String) async
    func signup(email: String, password: String) async
    func signInWithGoogle() async
    func logout() async
}

@MainActor
class AuthenticationViewModel: AuthenticationViewModelProtocol, ObservableObject {
    
    static let shared = AuthenticationViewModel()
    
    @Published var currentUser: UserEntity?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    private let authService = AuthService.shared
    private let db = Firestore.firestore()
    
    private init() {
        checkAuthenticationState()
        setupAuthStateListener()
    }
    
    private func checkAuthenticationState() {
        guard let firebaseUser = authService.currentFirebaseUser else {
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        isAuthenticated = true
        
        Task {
            await fetchUserData(uid: firebaseUser.uid)
        }
    }
    
    private func setupAuthStateListener() {
        authService.auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.isAuthenticated = true
                Task {
                    await self?.fetchUserData(uid: user.uid)
                }
            } else {
                self?.isAuthenticated = false
                self?.currentUser = nil
            }
        }
    }
    
    private func fetchUserData(uid: String) async {
        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            
            if userDoc.exists,
               let data = userDoc.data(),
               let user = UserEntity.fromDictionary(data, id: uid) {
                self.currentUser = user
            }
        } catch {
            
        }
    }
    
    func signup(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.SignUp(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            handleUnknownError(error)
        }
        
        isLoading = false
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            handleUnknownError(error)
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        print("Google auth started")
        do {
            let user = try await authService.googleSignIn()
            currentUser = user
            isAuthenticated = true
        } catch let error as AuthError {
            if error != .userCancelled {
                errorMessage = error.errorDescription
                print("Google auth canceled: $\(error.errorDescription)")
            }
        } catch {
            handleUnknownError(error, isCancellable: true)
        }
        
        isLoading = false
    }
    
    func logout() async {
        do {
            try authService.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = "Failed to logout"
        }
    }
    
    private func handleUnknownError(_ error: Error, isCancellable: Bool = false) {
        if let nsError = error as NSError? {
            let authError = AuthError(from: nsError)
            
            if isCancellable && authError == .userCancelled {
                return
            } else {
                errorMessage = authError.errorDescription
            }
        } else {
            errorMessage = "An unexpected error occurred"
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
