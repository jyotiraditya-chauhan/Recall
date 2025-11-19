//
//  ContentView.swift
//  Recall
//
//  Created by Aditya Chauhan on 14/11/25.
//

import SwiftUI


struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var router: Router
    
    var body: some View {
        RoutingView {
            if authViewModel.isAuthenticated {
                HomeView()
            } else {
                OnBoarding()
            }
        }
        .onAppear {
            handleInitialNavigation()
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                router.navigateTo(.home)
            } else {
                router.popToRoot()
            }
        }
    }
    
    private func handleInitialNavigation() {
        if authViewModel.isAuthenticated {
            router.navigateTo(.home)
        }
    }
}


#Preview{
    ContentView()
        .environmentObject(Router())
        .environmentObject(AuthenticationViewModel.shared)
}
