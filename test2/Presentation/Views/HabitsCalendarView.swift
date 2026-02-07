//
//  HabitsCalendarView.swift
//  test2
//

import SwiftUI

/// Главный экран: сверху календарь месяца (цифры в кружках), по свайпу вверх сворачивается в одну строку дней; снизу таймлайн выбранного дня.
struct HabitsCalendarView: View {
    @ObservedObject var viewModel: HabitsListViewModel
    @State private var displayedMonthStart: Date
    @State private var calendarExpanded: Bool = true
    var onEditHabit: (HabitModel) -> Void = { _ in }
    var onDeleteHabit: (UUID, String) -> Void = { _, _ in }

    private let calendar = Calendar.current
    private let weekdaySymbols = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    private let dayCircleSize: CGFloat = 40

    init(viewModel: HabitsListViewModel, onEditHabit: @escaping (HabitModel) -> Void = { _ in }, onDeleteHabit: @escaping (UUID, String) -> Void = { _, _ in }) {
        self.viewModel = viewModel
        self.onEditHabit = onEditHabit
        self.onDeleteHabit = onDeleteHabit
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: viewModel.selectedDate)) ?? Date()
        _displayedMonthStart = State(initialValue: start)
    }

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: displayedMonthStart)
    }

    private var numberOfDaysInMonth: Int {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonthStart) else { return 0 }
        return range.count
    }

    private var firstWeekdayOffset: Int {
        let weekday = calendar.component(.weekday, from: displayedMonthStart)
        return (weekday - 2 + 7) % 7
    }

    private func dayLabel(for date: Date) -> String {
        if calendar.isDateInToday(date) { return "Сегодня" }
        if calendar.isDateInTomorrow(date) { return "Завтра" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }

    private func date(forDay day: Int) -> Date? {
        calendar.date(byAdding: .day, value: day - 1, to: displayedMonthStart)
    }

    /// Номер дня в месяце для selectedDate (1-based), если он в displayedMonth; иначе nil.
    private var selectedDayInMonth: Int? {
        guard calendar.isDate(viewModel.selectedDate, equalTo: displayedMonthStart, toGranularity: .month) else { return nil }
        return calendar.component(.day, from: viewModel.selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // ——— Календарь: либо полная сетка, либо одна строка дней ———
            VStack(spacing: calendarExpanded ? 14 : 8) {
                // Строка месяц/год и стрелки (или свёрнутая подпись + раскрыть)
                HStack {
                    Button {
                        if let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonthStart) {
                            displayedMonthStart = prev
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    .opacity(calendarExpanded ? 1 : 0.6)
                    Spacer()
                    Text(monthYearTitle)
                        .font(calendarExpanded ? .headline : .subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    if calendarExpanded {
                        Button {
                            if let next = calendar.date(byAdding: .month, value: 1, to: displayedMonthStart) {
                                displayedMonthStart = next
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.body.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button {
                            withAnimation(.easeOut(duration: 0.25)) { calendarExpanded = true }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.body.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 4)

                if calendarExpanded {
                    // Заголовки дней недели
                    HStack(spacing: 0) {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Сетка дней — цифры в кружках
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
                    let totalCells = firstWeekdayOffset + numberOfDaysInMonth
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(0..<totalCells, id: \.self) { index in
                            if index < firstWeekdayOffset {
                                Color.clear
                                    .frame(width: dayCircleSize, height: dayCircleSize)
                            } else {
                                let day = index - firstWeekdayOffset + 1
                                if let date = date(forDay: day) {
                                    DayCircleCell(
                                        day: day,
                                        size: dayCircleSize,
                                        isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                                        isToday: calendar.isDateInToday(date)
                                    ) {
                                        viewModel.selectDate(date)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                } else {
                    // Свёрнутый вид: одна горизонтальная строка дней (текущий день просмотра в центре/на виду)
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(1...numberOfDaysInMonth, id: \.self) { day in
                                    if let date = date(forDay: day) {
                                        DayCircleCell(
                                            day: day,
                                            size: dayCircleSize,
                                            isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                                            isToday: calendar.isDateInToday(date)
                                        ) {
                                            viewModel.selectDate(date)
                                        }
                                        .id(day)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .onAppear {
                            if let d = selectedDayInMonth {
                                proxy.scrollTo(d, anchor: .center)
                            }
                        }
                        .onChange(of: viewModel.selectedDate) { _, _ in
                            if let d = selectedDayInMonth {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(d, anchor: .center)
                                }
                            }
                        }
                    }
                    .frame(height: dayCircleSize + 8)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if calendarExpanded, value.translation.height < -40 {
                            withAnimation(.easeOut(duration: 0.25)) { calendarExpanded = false }
                        } else if !calendarExpanded, value.translation.height > 40 {
                            withAnimation(.easeOut(duration: 0.25)) { calendarExpanded = true }
                        }
                    }
            )

            Divider()
                .opacity(0.5)

            // ——— Таймлайн выбранного дня снизу (с красной полосой текущего времени) ———
            DayTimelineView(
                date: viewModel.selectedDate,
                dayLabel: dayLabel(for: viewModel.selectedDate),
                items: viewModel.habitsForDate(viewModel.selectedDate),
                themeName: { viewModel.themeName(for: $0) },
                themeColor: { viewModel.themeColor(for: $0) },
                onToggle: { viewModel.toggleHabit($0, date: $1) },
                onEditHabit: onEditHabit,
                onDeleteHabit: onDeleteHabit
            )
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onChange(of: viewModel.selectedDate) { _, newDate in
            let newMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: newDate)) ?? displayedMonthStart
            if !calendar.isDate(displayedMonthStart, equalTo: newMonthStart, toGranularity: .month) {
                displayedMonthStart = newMonthStart
            }
        }
    }
}

/// Кружок с номером дня (на тёмном фоне приложения, без серого блока).
private struct DayCircleCell: View {
    let day: Int
    let size: CGFloat
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    private var fillColor: Color {
        if isSelected { return Color.accentColor }
        if isToday { return Color.red.opacity(0.85) }
        return Color.primary.opacity(0.08)
    }

    private var textColor: Color {
        if isSelected || isToday { return .white }
        return .primary
    }

    var body: some View {
        Button(action: action) {
            Text("\(day)")
                .font(.system(size: size * 0.4, weight: isToday || isSelected ? .semibold : .regular))
                .foregroundColor(textColor)
                .frame(width: size, height: size)
                .background(Circle().fill(fillColor))
        }
        .buttonStyle(.plain)
    }
}
