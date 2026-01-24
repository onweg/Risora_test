//
//  GameAttemptModel.swift
//  test2
//
//  Created by Arkadiy on 19.01.2026.
//

import Foundation

struct GameAttemptModel: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date?
    let startingLives: Int
    let endingLives: Int?
    let isActive: Bool
}
