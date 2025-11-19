
import SwiftUI


struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: Router
    
    var body: some View {
        RoutingView {
            if appState.isAuthenticated {
                HomeView()
            } else {
                OnBoarding()
            }
        }
        .onAppear {
            handleInitialNavigation()
        }
        .onChange(of: appState.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                router.navigateTo(.home)
            } else {
                router.popToRoot()
            }
        }
    }
    
    private func handleInitialNavigation() {
        if appState.isAuthenticated {
            router.navigateTo(.home)
        }
    }
}


#Preview{
    ContentView()
        .environmentObject(Router())
        .environmentObject(AppState())
}
