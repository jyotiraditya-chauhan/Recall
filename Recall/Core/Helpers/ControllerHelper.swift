//
//  ControllerHelper.swift
//  Recall
//
//  Created by Aditya Chauhan on 17/11/25.
//

import UIKit

extension UIApplication {
    @MainActor
    func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let ctrl = controller ?? keyWindow?.rootViewController

        if let nav = ctrl as? UINavigationController {
            return topViewController(controller: nav.visibleViewController)
        }

        if let tab = ctrl as? UITabBarController {
            return topViewController(controller: tab.selectedViewController)
        }

        if let presented = ctrl?.presentedViewController {
            return topViewController(controller: presented)
        }

        return ctrl
    }

    var keyWindow: UIWindow? {
        return connectedScenes
            .compactMap { scene in
                (scene as? UIWindowScene)?.windows.first(where: \.isKeyWindow)
            }
            .first
    }
    
    var firstWindowScene: UIWindowScene? {
        return connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }
    
    var currentWindow: UIWindow? {
        return keyWindow ?? firstWindowScene?.windows.first
    }
}
