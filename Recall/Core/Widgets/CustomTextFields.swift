//
//  CustomTextFields.swift
//  Recall
//
//  Created by Aditya Chauhan on 16/11/25.
//


import SwiftUI

struct CustomTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.buttonText)
                .foregroundColor(AppColor.grey)
            
            TextField(placeholder, text: $text)
                .font(.bodyText)
                .foregroundColor(.white)
                .padding()
                .background(Color(hex: "#1C1C1C"))
                .cornerRadius(12)
                .autocapitalization(.none)
                .keyboardType(keyboardType)
        }
    }
}

struct CustomSecureField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.buttonText)
                .foregroundColor(AppColor.grey)
            
            SecureField(placeholder, text: $text)
                .font(.bodyText)
                .foregroundColor(.white)
                .padding()
                .background(Color(hex: "#1C1C1C"))
                .cornerRadius(12)
                .autocapitalization(.none)
        }
    }
}
