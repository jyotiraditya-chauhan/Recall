//
//  CustomOutlineButton.swift
//  Recall
//
//  Created by Aditya Chauhan on 16/11/25.
//

import SwiftUI

struct CustomOutlineButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                
                   if isLoading {
                                       ProgressView()
                                           .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                           .frame(width: 28, height: 28)
                                   } else {
                                       Image(icon)
                                           .resizable()
                                           .frame(width: 28, height: 28)
                                   }
                    
                    Text(title)
                        .font(.buttonText)
                        .foregroundColor(.white)
                
                
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppColor.background)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(30)
        }
    }
}
