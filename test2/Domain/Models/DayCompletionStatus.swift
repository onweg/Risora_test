//
//  DayCompletionStatus.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

struct DayCompletionStatus {
    let date: Date
    let habitId: UUID
    let isCompleted: Bool
    let canEdit: Bool // можно ли редактировать (только сегодня)
}


