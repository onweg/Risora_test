//
//  HabitType.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

enum HabitType: String, CaseIterable {
    case good = "good"
    case bad = "bad"
    
    var displayName: String {
        switch self {
        case .good:
            return "Полезная"
        case .bad:
            return "Вредная"
        }
    }
}


