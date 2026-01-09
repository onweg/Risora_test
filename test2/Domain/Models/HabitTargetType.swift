//
//  HabitTargetType.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

enum HabitTargetType: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    
    var displayName: String {
        switch self {
        case .daily:
            return "Цель на день"
        case .weekly:
            return "Цель на неделю"
        }
    }
}


