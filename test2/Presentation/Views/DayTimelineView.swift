//
//  DayTimelineView.swift
//  test2
//

import SwiftUI

private let startHour = 6
private let endHour = 24
private let hourHeight: CGFloat = 56
private let timelineWidth: CGFloat = 44

/// Элемент с временным окном для расчёта наложений.
private struct TimedItem {
    let item: (habit: HabitModel, isCompleted: Bool, completionCount: Int, weeklyCompletionCount: Int, canEdit: Bool, weeklyCompletionDates: [Date])
    let startMin: Int
    let endMin: Int
}

/// Группа наложившихся блоков и назначенные колонки для отрисовки.
private struct OverlapGroup {
    let indices: [Int]           // индексы в timedItems
    let columnForIndex: [Int: Int] // индекс -> колонка (0, 1, 2...)
}

/// Один день в виде таймлайна: сетка по часам и блоки привычек/задач по времени.
struct DayTimelineView: View {
    let date: Date
    let dayLabel: String
    let items: [(habit: HabitModel, isCompleted: Bool, completionCount: Int, weeklyCompletionCount: Int, canEdit: Bool, weeklyCompletionDates: [Date])]
    let themeName: (UUID?) -> String?
    let themeColor: (UUID?) -> Color?
    let onToggle: (UUID, Date) -> Void
    var onEditHabit: (HabitModel) -> Void = { _ in }
    var onDeleteHabit: (UUID, String) -> Void = { _, _ in }

    private let calendar = Calendar.current
    private var isToday: Bool { calendar.isDateInToday(date) }
    
    private var currentTimeMinutes: Int? {
        guard isToday else { return nil }
        let now = Date()
        return calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
    }
    
    private var totalTimelineHeight: CGFloat {
        CGFloat((endHour - startHour) * 60) / 60.0 * hourHeight
    }
    
    /// Только элементы с временным окном.
    private var timedItems: [TimedItem] {
        items.compactMap { item in
            guard item.habit.hasAllowedTimeWindow,
                  let sh = item.habit.allowedStartHour, let sm = item.habit.allowedStartMinute,
                  let eh = item.habit.allowedEndHour, let em = item.habit.allowedEndMinute else { return nil }
            return TimedItem(
                item: item,
                startMin: sh * 60 + sm,
                endMin: eh * 60 + em
            )
        }
    }
    
    /// Группы наложений: два элемента в одной группе, если их интервалы пересекаются (транзитивно).
    private var overlapGroups: [OverlapGroup] {
        let timed = timedItems
        guard !timed.isEmpty else { return [] }
        func overlaps(_ a: TimedItem, _ b: TimedItem) -> Bool {
            a.startMin < b.endMin && b.startMin < a.endMin
        }
        var parent: [Int] = (0..<timed.count).map { $0 }
        func find(_ i: Int) -> Int {
            if parent[i] != i { parent[i] = find(parent[i]) }
            return parent[i]
        }
        func union(_ i: Int, _ j: Int) {
            let pi = find(i), pj = find(j)
            if pi != pj { parent[pi] = pj }
        }
        for i in 0..<timed.count {
            for j in (i+1)..<timed.count where overlaps(timed[i], timed[j]) {
                union(i, j)
            }
        }
        var groups: [Int: [Int]] = [:]
        for i in 0..<timed.count {
            let p = find(i)
            groups[p, default: []].append(i)
        }
        return groups.values.map { indices in
            let sorted = indices.sorted { timed[$0].startMin < timed[$1].startMin }
            var columnForIndex: [Int: Int] = [:]
            var columnLastEnd: [Int: Int] = [:]
            for idx in sorted {
                let start = timed[idx].startMin, end = timed[idx].endMin
                var col = 0
                while columnLastEnd[col, default: 0] > start { col += 1 }
                columnForIndex[idx] = col
                columnLastEnd[col] = end
            }
            return OverlapGroup(indices: sorted, columnForIndex: columnForIndex)
        }
    }
    
    /// Для каждого индекса в timedItems — к какой группе относится и какая колонка (и всего колонок в группе).
    private func columnInfo(for timedIndex: Int) -> (column: Int, total: Int)? {
        for group in overlapGroups {
            if let col = group.columnForIndex[timedIndex] {
                return (col, group.indices.count)
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(dayLabel)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        HStack(alignment: .top, spacing: 0) {
                            VStack(spacing: 0) {
                                ForEach(startHour..<endHour, id: \.self) { hour in
                                    Text(String(format: "%d:00", hour))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .frame(width: timelineWidth - 8, height: hourHeight, alignment: .topTrailing)
                                        .id(hour)
                                }
                            }
                            .frame(width: timelineWidth, alignment: .trailing)
                            
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 1)
                                .frame(height: totalTimelineHeight)
                            
                            GeometryReader { blockGeo in
                                let blockAreaWidth = max(1, blockGeo.size.width - 8)
                                ZStack(alignment: .topLeading) {
                                    ForEach(Array(timedItems.enumerated()), id: \.element.item.habit.id) { idx, timed in
                                        let y = minutesToY(timed.startMin)
                                        let h = max(28, minutesToY(timed.endMin) - y)
                                        let colInfo = columnInfo(for: idx)
                                        let (col, total) = colInfo ?? (0, 1)
                                        let totalCols = max(1, total)
                                        let colWidth = blockAreaWidth / CGFloat(totalCols)
                                        
                                        HabitTimelineBlock(
                                            habit: timed.item.habit,
                                            isCompleted: timed.item.isCompleted,
                                            themeName: themeName(timed.item.habit.themeId),
                                            themeColor: themeColor(timed.item.habit.themeId),
                                            isTask: timed.item.habit.isTask,
                                            onTap: { onToggle(timed.item.habit.id, date) },
                                            onEdit: { onEditHabit(timed.item.habit) },
                                            onDelete: { onDeleteHabit(timed.item.habit.id, timed.item.habit.name) }
                                        )
                                        .frame(width: colWidth - 4, height: h)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .offset(x: 8 + CGFloat(col) * colWidth + 2, y: y)
                                    }
                                    
                                    if let nowMin = currentTimeMinutes, nowMin >= startHour * 60, nowMin < endHour * 60 {
                                        let y = minutesToY(nowMin)
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 10, height: 10)
                                            Rectangle()
                                                .fill(Color.red.opacity(0.8))
                                                .frame(height: 2)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .offset(y: y - 5)
                                    }
                                }
                            }
                            .frame(height: totalTimelineHeight)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        }
                        .frame(height: totalTimelineHeight)
                    }
                    .padding(.bottom, 40)
                }
                .onAppear {
                    if isToday, let nowMin = currentTimeMinutes {
                        let hour = nowMin / 60
                        if hour >= startHour && hour < endHour {
                            proxy.scrollTo(hour, anchor: .center)
                        }
                    }
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private func minutesToY(_ minutesFromMidnight: Int) -> CGFloat {
        let startMin = startHour * 60
        let minutes = minutesFromMidnight - startMin
        return CGFloat(max(0, minutes)) / 60.0 * hourHeight
    }
}

/// Один блок на таймлайне (привычка/задача).
struct HabitTimelineBlock: View {
    let habit: HabitModel
    let isCompleted: Bool
    let themeName: String?
    let themeColor: Color?
    let isTask: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var blockBackground: Color {
        if let color = themeColor {
            return color.opacity(0.35)
        }
        return isTask ? Color(red: 0.0, green: 0.35, blue: 0.2).opacity(0.35) : Color.blue.opacity(0.15)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundColor(isCompleted ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    if let theme = themeName, !theme.isEmpty {
                        Text(theme)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if !isTask {
                        Text("XP: \(habit.xpValue)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(blockBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCompleted ? Color.green.opacity(0.6) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Редактировать", systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
}
