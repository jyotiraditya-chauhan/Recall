//
//  ShortcutView.swift
//  Recall
//
//  Created by Aditya Chauhan on 17/11/25.
//
import AppIntents
import SwiftUI
import Combine

struct ShortcutView: View {
    var body: some View {
        Text("Shortcuts")
    }
}





extension Notification.Name {
    static let openHomeScreen = Notification.Name("openHomeScreen")
}

