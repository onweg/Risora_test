//
//  HabitAnalysisRow.swift
//  test2
//

import SwiftUI

struct HabitAnalysisRow: View {
    let analysis: HabitWeeklyAnalysisModel
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(analysis.habitName)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        Text(analysis.habitType.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(analysis.habitType == .good ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .foregroundColor(analysis.habitType == .good ? .green : .red)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Text("\(analysis.totalImpact > 0 ? "+" : "")\(analysis.totalImpact)")
                        .font(.subheadline.bold())
                        .foregroundColor(analysis.totalImpact >= 0 ? .green : .red)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    // Недельная цель если есть
                    if let weeklyImpact = analysis.weeklyTargetImpact {
                        HStack {
                            Text(weeklyImpact < 0 ? "⚠️ Штраф за неделю" : "✅ Недельная цель")
                                .font(.caption)
                                .foregroundColor(weeklyImpact < 0 ? .red : .secondary)
                            Spacer()
                            Text("\(weeklyImpact > 0 ? "+" : "")\(weeklyImpact)")
                                .font(.caption.bold())
                                .foregroundColor(weeklyImpact >= 0 ? .green : .red)
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                        .background(weeklyImpact < 0 ? Color.red.opacity(0.1) : Color.primary.opacity(0.05))
                        .cornerRadius(4)
                    }
                    
                    // Детали по дням
                    let relevantDays = analysis.details.filter { $0.impact != 0 || $0.completions > 0 }
                    ForEach(relevantDays) { day in
                        HStack {
                            Text(day.date.formatted(.dateTime.day().month()))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .leading)
                            
                            Text("Выполнено: \(day.completions)\(day.target > 0 ? "/\(day.target)" : "")")
                                .font(.caption2)
                            
                            Spacer()
                            
                            if day.impact != 0 {
                                HStack(spacing: 4) {
                                    if day.impact < 0 {
                                        Text("Штраф")
                                            .font(.system(size: 8, weight: .bold))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.red.opacity(0.8))
                                            .foregroundColor(.white)
                                            .cornerRadius(3)
                                    }
                                    
                                    Text("\(day.impact > 0 ? "+" : "")\(day.impact)")
                                        .font(.caption2.bold())
                                        .foregroundColor(day.impact > 0 ? .green : .red)
                                }
                            }
                        }
                    }
                }
                .padding(.leading, 8)
                .padding(.top, 4)
            }
        }
    }
}
