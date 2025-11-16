
import SwiftUI


struct ContentView: View {
    var body: some View {
        RoutingView {
            OnBoarding()
        }
    }
}


#Preview{
    ContentView()
        .environmentObject(Router())
}
