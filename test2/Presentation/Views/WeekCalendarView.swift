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
    var onPreviousWeek: (() -> Void)?
    var onNextWeek: (() -> Void)?
    
    @State private var dragOffset: CGFloat = 0
    
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
            if onPreviousWeek != nil {
                Button(action: { onPreviousWeek?() }) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.accentColor)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            
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
                    .buttonStyle(.plain)
                }
            }
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width < -threshold {
                            onNextWeek?()
                        } else if value.translation.width > threshold {
                            onPreviousWeek?()
                        }
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = 0
                        }
                    }
            )
            
            if onNextWeek != nil {
                Button(action: { onNextWeek?() }) {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.accentColor)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
    }
    
    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
}



