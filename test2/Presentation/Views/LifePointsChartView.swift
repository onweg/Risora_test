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
                    currentValueSection
                    
                    if viewModel.chartData.isEmpty && viewModel.lastWeekReport == nil {
                        emptyStateSection
                    } else {
                        if !viewModel.chartData.isEmpty {
                            chartSection
                        }
                        weeklyAnalysisSection
                    }
                }
                .padding()
            }
            .navigationTitle("График")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var currentValueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Текущее значение")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("\(viewModel.currentValue)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.primary)
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
            Text("Рост по дням")
                .font(.headline)
            Text("Горизонтально — даты, вертикально — накопленные очки")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(viewModel.chartData) { point in
                    LineMark(
                        x: .value("День", point.date),
                        y: .value("Очки", point.points)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("День", point.date),
                        y: .value("Очки", point.points)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 280)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 6))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.day().month(.abbreviated))
                                .font(.caption2)
                        }
                    }
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
