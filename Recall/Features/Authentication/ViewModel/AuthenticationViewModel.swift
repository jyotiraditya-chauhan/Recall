//
//  AuthenticationViewModel.swift
//  Recall
//
//  Created by Aditya Chauhan on 17/11/25.
//


import Foundation
import SwiftUI
import FirebaseAuth
import GoogleSignIn

protocol AuthenticationViewModelProtocol {
    func login(email: String, password: String) async
    func signup(email: String, password: String) async 
    func signInWithGoogle() async
    func signInWithApple() async
    func logout() async
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
           guard authService.currentFirebaseUser != nil else {
               isAuthenticated = false
               currentUser = nil
               return
           }
           
           if let firebaseUser = authService.currentFirebaseUser {
               isAuthenticated = true
               // Fetch user data from Firestore
               Task {
                   // This will be implemented when we fetch from Firestore
                   // For now, create a basic user model
                   currentUser = UserEntity(
                       id: firebaseUser.uid,
                       email: firebaseUser.email ?? ""
                   )
               }
           }
       }
    
    func signup(email: String, password: String) async {
        
           isLoading = true
           errorMessage = nil
           
           do {
            
               let user = try await authService.SignUp(
                   email: email,
                   password: password,
               )
               

               currentUser = user
               isAuthenticated = true
               
               print("✅ Sign up successful: \(user.email)")
               
           } catch let error as AuthError {
            
               errorMessage = error.errorDescription
               print("❌ Sign up error: \(error)")
               
           } catch {

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
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            print("✅ Login successful: \(user.email)")
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            print("❌ Login error: \(error)")
        } catch {
            if let nsError = error as NSError? {
                let authError = AuthError(from: nsError)
                errorMessage = authError.errorDescription
            } else {
                errorMessage = "An unexpected error occurred"
            }
            print("❌ Login error: \(error)")
        }
        
        isLoading = false
    }

   


    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.googleSignIn()
            currentUser = user
            isAuthenticated = true
            print("✅ Google Sign-In successful: \(user.email)")
            
        } catch let error as AuthError {
            // Don't show error if user cancelled
            if error != .userCancelled {  // ← ADD THIS CHECK
                errorMessage = error.errorDescription
                print("❌ Google Sign-In error: \(error)")
            } else {
                print("ℹ️ User cancelled Google Sign-In")  // ← JUST LOG IT
            }
            
        } catch {
            if let nsError = error as NSError? {
                let authError = AuthError(from: nsError)
                
                // Don't show error if user cancelled
                if authError != .userCancelled {  // ← ADD THIS CHECK
                    errorMessage = authError.errorDescription
                    print("❌ Google Sign-In error: \(authError)")
                } else {
                    print("ℹ️ User cancelled Google Sign-In")  // ← JUST LOG IT
                }
            } else {
                errorMessage = "An unexpected error occurred"
                print("❌ Google Sign-In error: \(error)")
            }
        }
        
        isLoading = false
    }
    
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signInWithApple()
            currentUser = user
            isAuthenticated = true
            print("🍎 Apple Sign-In successful: \(user.email)")
            
        } catch let error as AuthError {
            if error != .userCancelled {
                errorMessage = error.errorDescription
                print("❌ Apple Sign-In error: \(error)")
            } else {
                print("ℹ️ User cancelled Apple Sign-In")
            }
            
        } catch {
            if let nsError = error as NSError? {
                let authError = AuthError(from: nsError)
                
                if authError != .userCancelled {
                    errorMessage = authError.errorDescription
                    print("❌ Apple Sign-In error: \(authError)")
                } else {
                    print("ℹ️ User cancelled Apple Sign-In")
                }
            } else {
                errorMessage = "An unexpected error occurred"
                print("❌ Apple Sign-In error: \(error)")
            }
        }
        
        isLoading = false
    }

      func logout() async  {
          
          do {
              try authService.signOut()
              currentUser = nil
              isAuthenticated = false
              print("User logged out")
          } catch {
//              throw error
              
          }
      }
}



