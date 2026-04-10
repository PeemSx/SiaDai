import SwiftUI
import Charts

struct WasteData: Identifiable {
    let id = UUID()
    let week: String
    let amount: Double
}

struct WasteChartView: View {
    let data: [WasteData]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MONEY LOST (LAST 4 WEEKS)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary.opacity(0.8))
                .tracking(1.0)

            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Week", item.week),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(Color(red: 0.35, green: 0.80, blue: 0.52))
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text(String(format: "$%.2f", item.amount))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.15, green: 0.55, blue: 0.35))
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(.black.opacity(0.04))
                    AxisValueLabel().font(.system(size: 11, weight: .bold)).foregroundStyle(.black)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(.black.opacity(0.04))
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("$\(Int(doubleValue))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.black)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .cardShadow, radius: 16, x: 0, y: 10)
    }
}

#Preview {
    WasteChartView(data: [
        WasteData(week: "WK 01", amount: 12.50),
        WasteData(week: "WK 02", amount: 8.75),
        WasteData(week: "WK 03", amount: 15.50),
        WasteData(week: "WK 04", amount: 8.25)
    ])
    .padding()
    .background(Color.screenBackground)
}
