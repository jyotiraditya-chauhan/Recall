import SwiftUI

struct LoginView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var appState: AppState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    
    @MainActor
    func handleLogin() async {
        errorMessage = ""
        
        if email.isEmpty || password.isEmpty {
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
        
        await appState.login(email: email, password: password)
        
        await MainActor.run {
            if let vmErrorMessage = appState.authViewModel.errorMessage {
                errorMessage = vmErrorMessage
            }
        }
    }
    
    @MainActor
    func handleGoogleSignIn() async {
        errorMessage = ""
        await appState.signInWithGoogle()
        
        await MainActor.run {
            if let vmErrorMessage = appState.authViewModel.errorMessage {
                errorMessage = vmErrorMessage
            }
        }
    }
    
    @MainActor
    func handleAppleSignIn() async {
        errorMessage = ""
        await appState.signInWithApple()
        
        await MainActor.run {
            if let vmErrorMessage = appState.authViewModel.errorMessage {
                errorMessage = vmErrorMessage
            }
        }
    }
    
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
                            Task {
                                await handleLogin()
                            }
                        } label: {
                            Text("Forget Password")
                                .font(.bodyText)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }

                    }
                    .padding(.bottom, 30)
                    
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.bottom, 8)
                    }
                    
                    
                    Button {
                        Task {
                            await handleLogin()
                        }
                    } label: {
                        Text("Submit")
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
                        CustomOutlineButton(icon: "google_logo",
                                            title: "Continue With Google",
                                            action: {
                            Task{
                                await handleGoogleSignIn()
                            }
                        })
                        
                        CustomOutlineButton(icon: "apple_logo",
                                            title: "Continue With Apple",
                                            action: {
                            Task{
                                await handleAppleSignIn()
                            }
                        })
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
    }
}

#Preview {
    LoginView()
        .environmentObject(Router())
        .environmentObject(AppState())
}
