import SwiftUI
import SwiftData

struct WasteJarView: View {
    @Query private var allFoodItems: [FoodItem]

    private var wastedItems: [FoodItem] {
        allFoodItems.filter { $0.status == .trashed || ($0.status == .tracking && $0.expiryDate < .now) }
    }

    private var totalLostThisMonth: Double {
        wastedItems.reduce(0) { $0 + $1.purchaseValue }
    }

    private var totalWeightLost: Double {
        wastedItems.reduce(0) { $0 + ($1.amount * 0.5) }
    }

    private var mostTrashedItems: [(name: String, count: Int, totalValue: Double, unit: String)] {
        let grouped = Dictionary(grouping: wastedItems, by: { $0.name })
        return grouped.map { (name, items) in
            (name: name, count: items.count, totalValue: items.reduce(0) { $0 + $1.purchaseValue }, unit: items.first?.unit ?? "pcs")
        }
        .sorted(by: { $0.count > $1.count })
        .prefix(3)
        .map { $0 }
    }

    var body: some View {
        ZStack {
            Color.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Color.white
                    .frame(height: 0)
                    .ignoresSafeArea(edges: .top)

                TopBrandBar()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        summaryHeader
                        
                        WasteChartView(data: mockChartData)
                        
                        earthImpactCard
                                                
                        mostTrashedSection
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 160)
                }
            }
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 8) {
            Text("TOTAL LOST THIS MONTH")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary.opacity(0.6))
                .tracking(1.2)

            Text(String(format: "$%.2f", totalLostThisMonth))
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(.black)

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.statusCrimson)
                    .frame(width: 8, height: 8)
                
                Text("12% higher than last month")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.statusCrimson)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(red: 0.98, green: 0.92, blue: 0.92), in: Capsule())
        }
    }

    private var mostTrashedSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Most Trashed Items")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                
                Spacer()
                
                Button("View History") { }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.brandGreen)
            }

            VStack(spacing: 16) {
                if mostTrashedItems.isEmpty {
                    Text("No waste items logged yet.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(mostTrashedItems, id: \.name) { item in
                        trashedRow(name: item.name, count: item.count, value: item.totalValue, unit: item.unit)
                    }
                }
            }
        }
    }

    private func trashedRow(name: String, count: Int, value: Double, unit: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.03))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "leaf.fill") 
                    .font(.title2)
                    .foregroundStyle(.black.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                
                Text("\(count) \(unit) • \(String(format: "$%.2f", value))")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if value > 20 || count >= 3 {
                statusBadge(text: "CRITICAL", color: Color.statusCrimson)
            } else {
                statusBadge(text: "FREQUENT", color: Color.statusAmber)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .cardShadow, radius: 12, x: 0, y: 8)
    }

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
            .foregroundStyle(color)
    }

    private var earthImpactCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EARTH IMPACT")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.brandGreen)
                .tracking(1.2)

            VStack(alignment: .leading, spacing: 8) {
                Text("Your waste this month generated enough CO2 to fill ")
                    .foregroundStyle(.black.opacity(0.6)) +
                Text("42 weather balloons.")
                    .foregroundStyle(.black)
                    .fontWeight(.bold) +
                Text(" Think before you buy next time.")
                    .foregroundStyle(.black.opacity(0.6))
            }
            .font(.system(size: 18, design: .rounded))
            .lineSpacing(4)
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .bottomTrailing) {
                Color.white
                
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                    .foregroundStyle(Color.brandGreen.opacity(0.06))
                    .rotationEffect(.degrees(-15))
                    .offset(x: 20, y: 20)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .cardShadow, radius: 20, x: 0, y: 12)
    }

    private var mockChartData: [WasteData] {
        [
            WasteData(week: "WK 01", amount: 12.50),
            WasteData(week: "WK 02", amount: 8.75),
            WasteData(week: "WK 03", amount: 15.50),
            WasteData(week: "WK 04", amount: 8.25)
        ]
    }
}

#Preview {
    WasteJarView()
        .modelContainer(PreviewHelper.previewContainer)
}
