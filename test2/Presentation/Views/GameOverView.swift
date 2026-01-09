//
//  GameOverView.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI
import Charts

struct GameOverView: View {
    @StateObject private var chartViewModel: LifePointsChartViewModel
    let onReset: () -> Void
    
    init(chartViewModel: LifePointsChartViewModel, onReset: @escaping () -> Void) {
        _chartViewModel = StateObject(wrappedValue: chartViewModel)
        self.onReset = onReset
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Заголовок
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Игра окончена")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("Вы потратили все жизни")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // График падения
                    VStack(alignment: .leading, spacing: 16) {
                        Text("График вашего прогресса")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if chartViewModel.lifePoints.isEmpty {
                            Text("Нет данных для отображения")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            Chart {
                                ForEach(Array(chartViewModel.lifePoints.enumerated()), id: \.element.id) { index, point in
                                    LineMark(
                                        x: .value("Неделя", index),
                                        y: .value("Жизни", point.value)
                                    )
                                    .foregroundStyle(.red)
                                    .interpolationMethod(.catmullRom)
                                    
                                    PointMark(
                                        x: .value("Неделя", index),
                                        y: .value("Жизни", point.value)
                                    )
                                    .foregroundStyle(.red)
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
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Кнопка начать заново
                    Button(action: {
                        onReset()
                    }) {
                        Text("Начать заново")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Анализ")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                chartViewModel.loadData()
            }
        }
    }
}

