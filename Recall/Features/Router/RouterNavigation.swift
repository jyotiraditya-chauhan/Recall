import SwiftUI
import Foundation



final class Router: ObservableObject {
    @Published var stack: [AppRoute] = []

    func push(_ route: AppRoute) {
        stack.append(route)
    }
    
    func pop() {
        stack.removeLast()
    }
    
    func popToRoot() {
        stack.removeAll()
    }
}
