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
    
    
       func replace(with route: AppRoute) {
           if !stack.isEmpty {
               stack.removeLast()
           }
           stack.append(route)
       }
}
