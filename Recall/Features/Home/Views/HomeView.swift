//
//  HomeView.swift
//  Recall
//
//  Created by Aditya Chauhan on 16/11/25.
//

import SwiftUI



struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var router: Router
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    if let user = authViewModel.currentUser {
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
                                    await handleLogout()
                                }
                            } label: {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Logout")
                                        .font(.buttonText)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColor.primary)
                            .cornerRadius(30)
                            .disabled(authViewModel.isLoading)
                            .padding(.horizontal)
                        }
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func handleLogout() async {
        await authViewModel.logout()
    }
}


#Preview {
    HomeView()
        .environmentObject(AuthenticationViewModel.shared)
        .environmentObject(Router())
}
