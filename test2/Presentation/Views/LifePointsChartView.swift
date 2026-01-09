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
                    // Текущие жизни
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
                    
                    // График
                    if viewModel.lifePoints.isEmpty {
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
                    } else {
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
                                AxisMarks { value in
                                    AxisValueLabel()
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
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
}



