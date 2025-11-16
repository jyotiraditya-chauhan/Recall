import SwiftUI


struct LoginView: View{
    @EnvironmentObject var router: Router
    @State private var conteroller: String = "";
    
    func handletap() {
        print("Hello")
    }
    var body: some View{
        ZStack{
            Color.black.ignoresSafeArea()
            
            VStack {
                
                VStack(alignment: .center){
                    
                    Text("Sign In").font(.headline).fontWeight(.bold).foregroundColor(.white).padding(.bottom, 4)
                    Text("Home back, you've been used").font(.bodyLarge).fontWeight(.medium).foregroundColor(.gray)
                    
                }.padding(.bottom, 48).padding(.top, 48)
                
                
                VStack() {
                    
                    CustomTextField(label: "Email", placeholder: "Enter Your Email", text: $conteroller).padding(.bottom, 8)
                    
                    CustomTextField(label: "Password", placeholder: "Enter Your password", text: $conteroller)
                    
                }.padding(.bottom, 12)
                
                HStack {
                    Spacer()
                    Button(action: handletap){
                        Text("Forget Password")
                            .font(.bodyText)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
                .padding(.bottom, 48)

                
                Button(action: handletap) {
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

                VStack{
                    CustomOutlineButton(icon: "google_logo", title: "Continue With Google", action: handletap)
                    CustomOutlineButton(icon: "apple_logo", title: "Continue With Apple", action: handletap)
                    
                }.padding(.bottom, 52)
                HStack{
                    Text("Don't have an account?").font(.bodyText).foregroundColor(.gray)
                    Text("Sign Up").font(.bodyLarge).fontWeight(.bold).foregroundColor(AppColor.primary).onTapGesture {
                        router.push(.signup)
                    }
                }
                Spacer()
                
            }.scrollDismissesKeyboard(.automatic)
                .padding()
        }
    }
}




#Preview {
    LoginView()
}

