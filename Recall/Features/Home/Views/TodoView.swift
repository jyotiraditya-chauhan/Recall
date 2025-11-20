//
//  TodoView.swift
//  Recall
//
//  Created by GU on 20/11/25.
//

import SwiftUI

struct TodoCard: View {
    let todo: Todo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Text(todo.category)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(todo.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .lineLimit(2)
            
            Spacer()
            
            HStack {
                Text(todo.date)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(width: 170, height: 140)
        .background(todo.color)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}
