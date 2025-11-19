//
//  HomeView.swift
//  Recall
//
//  Created by Aditya Chauhan on 16/11/25.
//

import SwiftUI



struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: Router
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    if let user = appState.currentUser {
                        VStack(spacing: 20) {
                            Text("Welcome!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(user.displayName)
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text(user.email)
                                .font(.body)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Button {
                                Task {
                                    await logout()
                                }
                            } label: {
                                Text("Logout")
                                    .font(.buttonText)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(AppColor.primary)
                                    .cornerRadius(30)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        Text("Loading...")
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func logout() async {
        await appState.logout()
    }
}


#Preview {
    HomeView()
        .environmentObject(AppState())
        .environmentObject(Router())
}
