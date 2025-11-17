

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var router: Router
    @StateObject private var viewModel = AuthenticationViewModel()
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var isSelected: Bool = false
    @State private var errorMessage: String = ""
    
    func handleOnTap() {
        print("On Top")
    }
    
    func handleSignUp(email: String, password: String)async  {
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
        
        Task{
            await viewModel.signUp(email: email, password: password)
            
            if viewModel.isAuthenticated {
                router.replace(with: .home)
            }
        }
        
        
        
        print("Sign Up Successful!")
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
                        CustomTextField(label: "Email", placeholder: "Enter Your Email", text: $email)
                        CustomTextField(label: "Password", placeholder: "Enter Your Password", text: $password)
                        CustomTextField(label: "Confirm Password", placeholder: "Re-enter Password", text: $confirmPassword)
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
                        CustomOutlineButton(icon: "google_logo", title: "Continue With Google", action: handleOnTap)
                        CustomOutlineButton(icon: "apple_logo", title: "Continue With Apple", action: handleOnTap)
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
}
