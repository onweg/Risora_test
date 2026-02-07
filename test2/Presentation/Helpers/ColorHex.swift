//
//  ColorHex.swift
//  test2
//

import SwiftUI
import UIKit

extension Color {
    /// Создаёт цвет из строки вида "#RRGGBB" или "RRGGBB".
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 else { return nil }
        let r = Int(s.prefix(2), radix: 16).map { Double($0) / 255 }
        let g = Int(s.dropFirst(2).prefix(2), radix: 16).map { Double($0) / 255 }
        let b = Int(s.suffix(2), radix: 16).map { Double($0) / 255 }
        guard let r = r, let g = g, let b = b else { return nil }
        self.init(red: r, green: g, blue: b)
    }
}

extension Color {
    /// Строка в формате "#RRGGBB" для сохранения.
    var hexString: String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else { return nil }
        let r = Int((components[0] * 255).rounded())
        let g = Int((components[1] * 255).rounded())
        let b = Int((components[2] * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
