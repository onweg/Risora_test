//
//  HabitFrequency.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

enum HabitFrequency: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case multipleTimesPerWeek = "multipleTimesPerWeek"
    
    var displayName: String {
        switch self {
        case .daily:
            return "Раз в день"
        case .weekly:
            return "Раз в неделю"
        case .multipleTimesPerWeek:
            return "Несколько раз в неделю"
        }
    }
    
    var requiredCountPerWeek: Int {
        switch self {
        case .daily:
            return 7
        case .weekly:
            return 1
        case .multipleTimesPerWeek:
            return 3 // по умолчанию 3 раза в неделю
        }
    }
}


