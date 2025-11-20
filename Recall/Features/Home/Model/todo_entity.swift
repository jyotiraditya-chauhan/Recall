//
//  todo_entity.swift
//  Recall
//
//  Created by GU on 20/11/25.
//

import Foundation
import SwiftUI

struct Todo: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let date: String
    let color: Color
}
