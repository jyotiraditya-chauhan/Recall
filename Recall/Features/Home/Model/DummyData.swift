//
//  DummyData.swift
//  Recall
//
//  Created by GU on 20/11/25.
//

import SwiftUI

let todoColors: [Color] = [
    Color(red: 225/255, green: 245/255, blue: 254/255),
    Color(red: 240/255, green: 231/255, blue: 255/255),
    Color(red: 255/255, green: 231/255, blue: 227/255),
    Color(red: 228/255, green: 241/255, blue: 255/255),
    Color(red: 255/255, green: 249/255, blue: 217/255),
    Color(red: 250/255, green: 233/255, blue: 255/255)
]

let dummyTodos: [Todo] = [
    Todo(category: "Assignment", title: "Physics Assignment", date: "October 10, 12:15 AM", color: todoColors[0]),
    Todo(category: "Lab Test", title: "Microprocessor final lab test", date: "October 10, 12:15 AM", color: todoColors[1]),
    Todo(category: "Assignment", title: "Digital Electronics lab", date: "October 10, 12:15 AM", color: todoColors[2]),
    Todo(category: "Task", title: "Microprocessor final lab test", date: "October 10, 12:15 AM", color: todoColors[3]),
    Todo(category: "Home Works", title: "10 Home works pending", date: "October 10, 12:15 AM", color: todoColors[4]),
    Todo(category: "Assignment", title: "Chemistry Assignment", date: "October 10, 12:15 AM", color: todoColors[5]),
]
