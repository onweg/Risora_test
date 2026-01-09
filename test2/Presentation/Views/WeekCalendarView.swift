//
//  WeekCalendarView.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI

struct WeekCalendarView: View {
    let weekDays: [Date]
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { date in
                Button(action: {
                    onDateSelected(date)
                }) {
                    VStack(spacing: 8) {
                        Text(dayFormatter.string(from: date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(dateFormatter.string(from: date))
                            .font(.headline)
                            .foregroundColor(isSelected(date) ? .white : .primary)
                            .frame(width: 36, height: 36)
                            .background(isSelected(date) ? Color.blue : Color.clear)
                            .clipShape(Circle())
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
}



