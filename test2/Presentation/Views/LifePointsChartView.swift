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
            .navigationTitle("График жизней")
            .navigationBarTitleDisplayMode(.large)
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
                ForEach(viewModel.chartData) { point in
                    LineMark(
                        x: .value("Неделя", point.weekIndex),
                        y: .value("Жизни", point.lives)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Неделя", point.weekIndex),
                        y: .value("Жизни", point.lives)
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
