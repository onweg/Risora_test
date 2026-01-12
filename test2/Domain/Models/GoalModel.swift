//
//  GoalModel.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

struct GoalModel: Identifiable {
    let id: UUID
    let title: String
    let motivation: String
    let relatedHabitIds: [UUID] // ID привычек, связанных с этой целью
    let createdAt: Date
    let sortOrder: Int // Порядок сортировки в списке
    
    init(
        id: UUID = UUID(),
        title: String,
        motivation: String,
        relatedHabitIds: [UUID] = [],
        createdAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.motivation = motivation
        self.relatedHabitIds = relatedHabitIds
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}
