import SwiftUI
import Charts

struct WasteChartView: View {
    let data: [WasteData]
    let monthTitle: String
    let canGoForward: Bool
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("MONEY LOST")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary.opacity(0.8))
                        .tracking(1.0)

                    Text(monthTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                }

                Spacer()

                HStack(spacing: 10) {
                    monthButton(systemName: "chevron.left", action: onPreviousMonth)
                    monthButton(systemName: "chevron.right", action: onNextMonth, isDisabled: !canGoForward)
                }
            }

            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Week", item.week),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(Color(red: 0.35, green: 0.80, blue: 0.52))
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text(String(format: "฿%.2f", item.amount))
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
                            Text("฿\(Int(doubleValue))")
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

    private func monthButton(
        systemName: String,
        action: @escaping () -> Void,
        isDisabled: Bool = false
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isDisabled ? Color.secondary.opacity(0.45) : Color.black)
                .frame(width: 34, height: 34)
                .background(Color.black.opacity(0.04), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

#Preview {
    WasteChartView(
        data: [
            WasteData(id: "wk-01", week: "WK 01", amount: 12.50),
            WasteData(id: "wk-02", week: "WK 02", amount: 8.75),
            WasteData(id: "wk-03", week: "WK 03", amount: 15.50),
            WasteData(id: "wk-04", week: "WK 04", amount: 8.25)
        ],
        monthTitle: "May 2026",
        canGoForward: false,
        onPreviousMonth: {},
        onNextMonth: {}
    )
    .padding()
    .background(Color.screenBackground)
}
