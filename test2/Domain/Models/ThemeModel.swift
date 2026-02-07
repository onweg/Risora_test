//
//  ThemeModel.swift
//  test2
//

import Foundation

struct ThemeModel: Identifiable {
    let id: UUID
    let name: String
    let colorHex: String?
    let sortOrder: Int
    
    init(id: UUID = UUID(), name: String, colorHex: String? = nil, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
}
