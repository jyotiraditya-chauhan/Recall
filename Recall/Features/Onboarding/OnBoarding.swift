//
//  OnBoarding.swift
//  Recall
//
//  Created by Aditya Chauhan on 14/11/25.
//

import SwiftUI


struct OnBoarding: View {
    
    @EnvironmentObject var router: Router
    
    var body: some View {
        ZStack{
            AppColor.background.ignoresSafeArea()
            VStack{
                Spacer()
                Image("memoryStorage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                Spacer()


                VStack(alignment: .leading) {
                    Text("Never Forget Again").font(.headline).foregroundColor(.white).padding(.bottom, 8)
                    Text("our personal memory vault. Store anything you need to remember, anytime, anywhere").font(.bodyText).foregroundColor(.white)
                }
                Button(action: {
                    router.push(.login)
                }) {
                    ZStack{
                        Rectangle().frame(width: .infinity, height: 60, alignment: .center).foregroundColor(AppColor.primary).cornerRadius(30)
                        Text("Submit").font(.body).foregroundColor(.white)
                    }
                }.padding()
            }
        }
    }
}



#Preview {
    OnBoarding()
        .environmentObject(Router())
}
