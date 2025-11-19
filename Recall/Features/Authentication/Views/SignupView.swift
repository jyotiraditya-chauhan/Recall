

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var appState: AppState
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var isSelected: Bool = false
    @State private var errorMessage: String = ""
    
    func handleSignUp(email: String, password: String) async  {
        errorMessage = ""
        
        if email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "All fields are required."
            return
        }
        
        if !email.contains("@") {
            errorMessage = "Please enter a valid email."
            return
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            return
        }
        
        if !isSelected {
            errorMessage = "You must agree to Terms & Conditions."
            return
        }
        
        await appState.signup(email: email, password: password)
        
        await MainActor.run {
            if let vmErrorMessage = appState.authViewModel.errorMessage {
                errorMessage = vmErrorMessage
            }
        }
        
        print("Sign Up Successful!")
    }
    
    
    func handleGoogleSignIn() async {
        print("Yes")
        
        await appState.signInWithGoogle()
        
        await MainActor.run(body: {
            if let vmErrorMessage = appState.authViewModel.errorMessage {
                errorMessage = vmErrorMessage
            }
        })
    }
    
    func handleAppleSignIn() async {
        await appState.signInWithApple()
        
        await MainActor.run(body: {
            if let vmErrorMessage = appState.authViewModel.errorMessage {
                errorMessage = vmErrorMessage
            }
        })
    }
    
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
                    
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .fontWeight(.regular)
                            .padding(.bottom, 8)
                    }
                    
                    
                    Button {
                        Task {
                            await handleSignUp(email: email, password: password)
                        }
                    } label: {
                        Text("Sign Up")
                            .font(.buttonText)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColor.primary)
                            .cornerRadius(30)
                    }
                    
                    
                    
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
                            Task
                            {
                                 await handleGoogleSignIn()
                            }
                        }
                        )
                        CustomOutlineButton(icon: "apple_logo", title: "Continue With Apple", action: {
                            Task {
                                await handleAppleSignIn()
                            }
                        })
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
    }
}

#Preview {
    SignupView()
        .environmentObject(Router())
        .environmentObject(AppState())
}
