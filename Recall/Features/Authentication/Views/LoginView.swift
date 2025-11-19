//
//  LoginView.swift
//  Recall
//
//  Created by Aditya Chauhan on 16/11/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var localError: String = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack {
                    
                    VStack(alignment: .center) {
                        Text("Sign In")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 4)
                        
                        Text("Welcome back, you've been missed")
                            .font(.bodyLarge)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 48)
                    .padding(.top, 48)
                    
                    
                    VStack(spacing: 8) {
                        CustomTextField(label: "Email",
                                        placeholder: "Enter Your Email",
                                        text: $email,
                                        keyboardType: .emailAddress)
                        
                        CustomSecureField(label: "Password",
                                        placeholder: "Enter Your Password",
                                        text: $password)
                    }
                    .padding(.bottom, 12)
                    
                    
                    HStack {
                        Spacer()
                        Button {
                            
                        } label: {
                            Text("Forget Password")
                                .font(.bodyText)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.bottom, 30)
                    
                    
                    if !localError.isEmpty {
                        Text(localError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.bottom, 8)
                    } else if let vmError = authViewModel.errorMessage {
                        Text(vmError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.bottom, 8)
                    }
                    
                    
                    Button {
                        Task {
                            await handleLogin()
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Submit")
                                .font(.buttonText)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColor.primary)
                    .cornerRadius(30)
                    .disabled(authViewModel.isLoading)
                    
                    
                    HStack {
                        Rectangle().frame(height: 0.5).foregroundColor(.gray)
                        Text("OR")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Rectangle().frame(height: 0.5).foregroundColor(.gray)
                    }
                    .padding(.vertical, 10)
                    
                    
                    VStack(spacing: 10) {
                        CustomOutlineButton(icon: "google_logo",
                                            title: "Continue With Google",
                                            action: {
                            Task{
                                await handleGoogleSignIn()
                            }
                        })
                        .disabled(authViewModel.isLoading)
                        
                        CustomOutlineButton(icon: "apple_logo",
                                            title: "Continue With Apple",
                                            action: {
                            Task{
                                await handleAppleSignIn()
                            }
                        })
                        .disabled(authViewModel.isLoading)
                    }
                    .padding(.bottom, 52)
                    
                    
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                            .font(.bodyText)
                        
                        Text("Sign Up")
                            .foregroundColor(AppColor.primary)
                            .font(.bodyLarge)
                            .fontWeight(.bold)
                            .onTapGesture {
                                router.push(.signup)
                            }
                    }
                    .padding(.bottom, 16)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.automatic)
        }
        .onAppear {
            authViewModel.clearError()
            localError = ""
        }
    }
    
    private func handleLogin() async {
        localError = ""
        
        guard validateInput() else { return }
        
        await authViewModel.login(email: email, password: password)
    }
    
    private func handleGoogleSignIn() async {
        localError = ""
        await authViewModel.signInWithGoogle()
    }
    
    private func handleAppleSignIn() async {
        localError = ""
        await authViewModel.signInWithApple()
    }
    
    private func validateInput() -> Bool {
        if email.isEmpty || password.isEmpty {
            localError = "All fields are required."
            return false
        }
        
        if !email.contains("@") {
            localError = "Please enter a valid email."
            return false
        }
        
        if password.count < 6 {
            localError = "Password must be at least 6 characters."
            return false
        }
        
        return true
    }
}

#Preview {
    LoginView()
        .environmentObject(Router())
        .environmentObject(AuthenticationViewModel.shared)
}
