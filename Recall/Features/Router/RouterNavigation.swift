import SwiftUI
import Foundation



final class Router: ObservableObject {
    @Published var stack: [AppRoute] = []

    func push(_ route: AppRoute) {
        stack.append(route)
    }
    
    func pop() {
        guard !stack.isEmpty else { return }
        stack.removeLast()
    }
    
    func popToRoot() {
        stack.removeAll()
    }
    
    
       func replace(with route: AppRoute) {
           if !stack.isEmpty {
               stack.removeLast()
           }
           stack.append(route)
       }
       
       func navigateTo(_ route: AppRoute) {
           stack.removeAll()
           stack.append(route)
       }
}
