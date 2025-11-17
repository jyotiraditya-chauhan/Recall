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
    func login(email: String, password: String) async throws -> UserModel
    func signup(email: String, password: String) async throws -> UserModel
       func signInWithGoogle() async throws -> UserModel
       func logout() async throws
}

@MainActor
class AuthenticationViewModel: AuthenticationViewModelProtocol {
    
    func login(email: String, password: String) async throws -> UserModel {
          try await Task.sleep(nanoseconds: 500_000_000) // simulate API delay
          return UserModel(id: UUID().uuidString, email: email)
      }

      func signup(email: String, password: String) async throws -> UserModel {
          try await Task.sleep(nanoseconds: 500_000_000)
          return UserModel(id: UUID().uuidString, email: email)
      }

      func signInWithGoogle() async throws -> UserModel {
          try await Task.sleep(nanoseconds: 500_000_000)
          return UserModel(id: UUID().uuidString, email: "googleuser@gmail.com")
      }

      func logout() async throws {
          print("User logged out")
      }
}
