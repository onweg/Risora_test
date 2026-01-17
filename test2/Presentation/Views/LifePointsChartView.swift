//
//  LifePointsChartView.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI
import Charts

struct LifePointsChartView: View {
    @StateObject private var viewModel: LifePointsChartViewModel
    
    init(viewModel: LifePointsChartViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    currentLivesSection
                    
                    if viewModel.lifePoints.isEmpty {
                        emptyStateSection
                    } else {
                        chartSection
                        weeklyAnalysisSection
                    }
                }
                .padding()
            }
            .navigationTitle("График жизней")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Кнопки отладки скрыты. Чтобы вернуть, раскомментируйте блок ниже.
                        /*
                        Button(action: {
                            viewModel.deleteAllTrashHabits()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            viewModel.recalculateLastWeek()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            viewModel.debugPrintWeeklyAnalysis()
                        }) {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .foregroundColor(.blue)
                        }
                        */
                    }
                }
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var currentLivesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Текущие жизни")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("\(viewModel.currentLives)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(viewModel.currentLives > 0 ? .primary : .red)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Нет данных")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Данные появятся после завершения первой недели")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("График прогресса")
                .font(.headline)
            
            Chart {
                ForEach(Array(viewModel.lifePoints.enumerated()), id: \.element.id) { index, point in
                    LineMark(
                        x: .value("Неделя", index),
                        y: .value("Жизни", point.value)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Неделя", index),
                        y: .value("Жизни", point.value)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 300)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var weeklyAnalysisSection: some View {
        Group {
            if let report = viewModel.lastWeekReport {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Анализ за прошлую неделю")
                        .font(.headline)
                    
                    HStack {
                        Text("Итого за неделю:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(report.totalXPChange > 0 ? "+" : "")\(report.totalXPChange)")
                            .font(.title3.bold())
                            .foregroundColor(report.totalXPChange >= 0 ? .green : .red)
                    }
                    .padding(.bottom, 8)
                    
                    ForEach(report.analyses) { analysis in
                        HabitAnalysisRow(analysis: analysis)
                        Divider()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

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
