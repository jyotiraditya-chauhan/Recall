//
//  SignupView.swift
//  Recall
//
//  Created by Aditya Chauhan on 16/11/25.
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSelected: Bool = false
    @State private var localError: String = ""
    
    var body: some View {
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack {
                    
                    VStack(alignment: .center) {
                        Text("Sign Up")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 4)
                        
                        Text("Complete your information below, or\nregister easily with your social account.")
                            .font(.bodyLarge)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 48)
                    .padding(.top, 24)
                    
                    
                    VStack(spacing: 8) {
                        CustomTextField(label: "Email", placeholder: "Enter Your Email", text: $email, keyboardType: .emailAddress)
                        CustomSecureField(label: "Password", placeholder: "Enter Your Password", text: $password)
                        CustomSecureField(label: "Confirm Password", placeholder: "Re-enter Password", text: $confirmPassword)
                    }
                    .padding(.bottom, 12)
                    
                    
                    HStack {
                        ZStack {
                            Circle()
                                .stroke(isSelected ? AppColor.primary : Color.gray, lineWidth: 2)
                                .frame(width: 22, height: 22)
                            
                            if isSelected {
                                Circle()
                                    .fill(AppColor.primary)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .onTapGesture {
                            isSelected.toggle()
                        }
                        
                        Text("Agree with")
                            .foregroundColor(.gray)
                            .font(.bodyText)
                        
                        Text("Terms & Conditions ")
                            .font(.bodyText)
                            .fontWeight(.bold)
                            .underline()
                            .foregroundColor(AppColor.primary)
                        
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    
                    
                    if !localError.isEmpty {
                        Text(localError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .fontWeight(.regular)
                            .padding(.bottom, 8)
                    } else if let vmError = authViewModel.errorMessage {
                        Text(vmError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.bottom, 8)
                    }
                    
                    
                    Button {
                        Task {
                            await handleSignUp()
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign Up")
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
                        CustomOutlineButton(icon: "google_logo", title: "Continue With Google", action: {
                            Task {
                                await handleGoogleSignIn()
                            }
                        })
                        .disabled(authViewModel.isLoading)
                        
                        CustomOutlineButton(icon: "apple_logo", title: "Continue With Apple", action: {
                            Task {
                                await handleAppleSignIn()
                            }
                        })
                        .disabled(authViewModel.isLoading)
                    }
                    .padding(.bottom, 52)
                    
                    
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                            .font(.bodyText)
                        
                        Text("Log In")
                            .foregroundColor(AppColor.primary)
                            .font(.bodyLarge)
                            .fontWeight(.bold)
                            .onTapGesture { router.pop() }
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
    
    private func handleSignUp() async {
        localError = ""
        
        guard validateInput() else { return }
        
        await authViewModel.signup(email: email, password: password)
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
        if email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
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
        
        if password != confirmPassword {
            localError = "Passwords do not match."
            return false
        }
        
        if !isSelected {
            localError = "You must agree to Terms & Conditions."
            return false
        }
        
        return true
    }
}

#Preview {
    SignupView()
        .environmentObject(Router())
        .environmentObject(AuthenticationViewModel.shared)
}
