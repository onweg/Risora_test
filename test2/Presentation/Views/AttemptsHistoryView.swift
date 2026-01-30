//
//  AttemptsHistoryView.swift
//  test2
//
//  Created by Arkadiy on 19.01.2026.
//

import SwiftUI
import Charts

struct AttemptsHistoryView: View {
    @StateObject private var viewModel: AttemptsHistoryViewModel
    @State private var selectedAttempt: GameAttemptModel?
    
    init(viewModel: AttemptsHistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.attempts) { attempt in
                    Button(action: {
                        selectedAttempt = attempt
                        viewModel.loadLifePoints(for: attempt)
                    }) {
                        AttemptRow(attempt: attempt, viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("История попыток")
            .onAppear {
                viewModel.loadAttempts()
            }
            .sheet(item: $selectedAttempt) { attempt in
                AttemptDetailView(attempt: attempt, viewModel: viewModel)
            }
        }
    }
}

struct AttemptRow: View {
    let attempt: GameAttemptModel
    let viewModel: AttemptsHistoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.attemptStatusText(attempt))
                    .font(.headline)
                    .foregroundColor(colorForStatus())
                
                Spacer()
                
                Text(viewModel.attemptDuration(attempt))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Начало: \(viewModel.formatDate(attempt.startDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let endDate = attempt.endDate {
                        Text("Конец: \(viewModel.formatDate(endDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForStatus() -> Color {
        let colorName = viewModel.attemptStatusColor(attempt)
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        default: return .primary
        }
    }
}

struct AttemptDetailView: View {
    let attempt: GameAttemptModel
    @ObservedObject var viewModel: AttemptsHistoryViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Информация о попытке
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Статус")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(viewModel.attemptStatusText(attempt))
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("Длительность")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(viewModel.attemptDuration(attempt))
                                    .font(.headline)
                            }
                        }
                        
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // График жизней
                    if !viewModel.selectedAttemptChartData.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("График жизней")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart {
                                ForEach(viewModel.selectedAttemptChartData) { point in
                                    LineMark(
                                        x: .value("Неделя", point.weekIndex),
                                        y: .value("Жизни", point.lives)
                                    )
                                    .foregroundStyle(lineColor())
                                    .interpolationMethod(.catmullRom)
                                    
                                    PointMark(
                                        x: .value("Неделя", point.weekIndex),
                                        y: .value("Жизни", point.lives)
                                    )
                                    .foregroundStyle(lineColor())
                                }
                            }
                            .frame(height: 300)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisValueLabel()
                                }
                            }
                            .padding()
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("Нет данных о жизнях")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                    
                    // Даты
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Начало попытки")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(viewModel.formatDate(attempt.startDate))
                                .font(.caption)
                        }
                        
                        if let endDate = attempt.endDate {
                            Divider()
                            HStack {
                                Text("Конец попытки")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(viewModel.formatDate(endDate))
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Анализ за прошлую неделю
                    if let report = viewModel.lastWeekReport {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Анализ за последнюю неделю")
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
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Детали попытки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    
    private func lineColor() -> Color {
        if attempt.isActive {
            return .blue
        } else {
            // Для завершенных попыток - красный цвет графика
            return .red
        }
    }
}
