import SwiftUI


struct RoutingView<Root: View>: View {
    @EnvironmentObject var router: Router
    let root: () -> Root
    
    init(@ViewBuilder root: @escaping () -> Root) {
        self.root = root
    }
    
    var body: some View {
        NavigationStack(path: $router.stack) {
            root()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .onboarding:
                        OnBoarding() .navigationBarBackButtonHidden(true)
                    case .login:
                        LoginView() .navigationBarBackButtonHidden(true)
                    case .signup:
                        SignupView() .navigationBarBackButtonHidden(true)
                        
                    case .home:
                        HomeView().navigationBarBackButtonHidden(true)
                    }
                }
        }
    }
}

