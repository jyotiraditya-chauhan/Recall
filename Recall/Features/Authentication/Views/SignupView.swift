import SwiftUI


struct SignupView: View{
    @EnvironmentObject var router: Router
    @State private var conteroller: String = "";
    @State private var isSelected: Bool = false;
    func handletap() {
        print("Hello")
    }
    var body: some View{
        ZStack{
            Color.black.ignoresSafeArea()
            
            VStack {
                
                VStack(alignment: .center){
                    
                    Text("Sign Up").font(.headline).fontWeight(.bold).foregroundColor(.white).padding(.bottom, 4)
                    Text("Complete your information below, or\n register easily with your social account.")
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    
                }.padding(.bottom, 48).padding(.top, 48)
                
                
                VStack() {
                    
                    CustomTextField(label: "Email", placeholder: "Enter Your Email", text: $conteroller).padding(.bottom, 8)
                    
                    CustomTextField(label: "Password", placeholder: "Enter Your password", text: $conteroller)
                    
                    CustomTextField(label: "Confirm Password", placeholder: "Enter Your confirm password", text: $conteroller)
                    
                }.padding(.bottom, 12)
                
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
                    }.onTapGesture {
                        isSelected = !isSelected
                    }
                    
                    Text("Agree with").font(.bodyText).foregroundColor(.gray)
                    Text("Terms & Conditions ").font(.bodyText).fontWeight(.bold).underline(true, color: AppColor.primary).foregroundColor(AppColor.primary)
                    Spacer()
                    
                }
                .padding(.bottom, 28)

                
                Button(action: handletap) {
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

                VStack{
                    CustomOutlineButton(icon: "google_logo", title: "Continue With Google", action: handletap)
                    CustomOutlineButton(icon: "apple_logo", title: "Continue With Apple", action: handletap)
                    
                }.padding(.bottom, 52)
                HStack{
                    Text("Already have an account?").font(.bodyText).foregroundColor(.gray)
                    Text("Log in").font(.bodyLarge).fontWeight(.bold).foregroundColor(AppColor.primary).onTapGesture {
                        router.pop()
                    }
                }.padding(.bottom, 16)
                Spacer()
                
            }.scrollDismissesKeyboard(.automatic)
                .padding()
        }
    }
}




#Preview {
    SignupView()
}

