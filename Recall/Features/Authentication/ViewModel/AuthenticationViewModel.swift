//
//  AuthenticationViewModel.swift
//  Recall
//
//  Created by Aditya Chauhan on 17/11/25.
//


import Foundation
import SwiftUI
import FirebaseAuth

protocol AuthenticationViewModelProtocol {
//    var isLoading: Bool { get set }
//    var userModel: UserEntity { get set }
    func login(email: String, password: String) async throws -> UserEntity
//    func signup(email: String, password: String) async throws -> UserEntity
    func signInWithGoogle() async throws -> UserEntity
    func logout() async throws
}

@MainActor
class AuthenticationViewModel: AuthenticationViewModelProtocol, ObservableObject {
 
    
    @Published var currentUser: UserEntity?
      @Published var isLoading = false
      @Published var errorMessage: String?
      @Published var isAuthenticated = false
      private let authService = AuthService.shared
      
    
      
      init() {
          checkAuthenticationState()
      }
    
    func checkAuthenticationState() {
           if let firebaseUser = authService.currentFirebaseUser {
               isAuthenticated = true
               // Fetch user data from Firestore
               Task {
//                   do {
                       // This will be implemented when we fetch from Firestore
                       // For now, create a basic user model
                       currentUser = UserEntity(
                           id: firebaseUser.uid,
                           email: firebaseUser.email ?? ""
                       )
//                   } catch {
//                       print("Error fetching user: \(error)")
//                   }
               }
           }
       }
    
    func signUp(email: String, password: String) async {
        
           isLoading = true
           errorMessage = nil
           
           do {
               // 3. Call service
               let user = try await authService.SignUp(
                   email: email,
                   password: password,
               )
               
               // 4. Update state
               currentUser = user
               isAuthenticated = true
               
               print("✅ Sign up successful: \(user.email)")
               
           } catch let error as AuthError {
            
               errorMessage = error.errorDescription
               print("❌ Sign up error: \(error)")
               
           } catch {
               // Handle Firebase errors
               if let nsError = error as NSError? {
                   let authError = AuthError(from: nsError)
                   errorMessage = authError.errorDescription
               } else {
                   errorMessage = "An unexpected error occurred"
               }
               print("❌ Sign up error: \(error)")
           }
           

           isLoading = false
       }
    
    func login(email: String, password: String) async throws -> UserEntity {
          try await Task.sleep(nanoseconds: 500_000_000) // simulate API delay
          return UserEntity(id: UUID().uuidString, email: email)
      }

   

      func signInWithGoogle() async throws -> UserEntity {
          try await Task.sleep(nanoseconds: 500_000_000)
          return UserEntity(id: UUID().uuidString, email: "googleuser@gmail.com")
      }

      func logout() async throws {
          print("User logged out")
      }
}



