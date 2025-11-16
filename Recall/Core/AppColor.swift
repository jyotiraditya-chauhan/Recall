//
//  AppColor.swift
//  Recall
//
//  Created by Aditya Chauhan on 14/11/25.
//


import SwiftUI
import SwiftUICore

struct AppColor{
    static let primary = Color(hex: "#7000BF")
    static let background = Color(hex: "#000000")
    static let grey = Color(hex: "#8B8B8B")
    static let white = Color(hex: "#F9F9F9")
}


extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
