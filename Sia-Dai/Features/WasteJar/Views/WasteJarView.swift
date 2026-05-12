import SwiftUI
import SwiftData

struct WasteJarView: View {
    @Query private var allFoodItems: [FoodItem]
    @State private var viewModel = WasteJarViewModel()

    private var trashedItems: [FoodItem] {
        viewModel.trashedItems(from: allFoodItems)
    }

    private var totalLostThisMonth: Double {
        viewModel.totalLostThisMonth(from: allFoodItems)
    }

    private var chartData: [WasteData] {
        viewModel.chartData(from: allFoodItems)
    }

    private var selectedMonthTitle: String {
        viewModel.selectedMonthTitle
    }

    private var canGoForwardMonth: Bool {
        viewModel.canGoForwardMonth()
    }

    private var trendMessage: String {
        viewModel.trendMessage(from: allFoodItems)
    }

    private var trendColor: Color {
        viewModel.trendColor(from: allFoodItems)
    }

    private var summaryTitle: String {
        viewModel.summaryTitle
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

                        WasteChartView(
                            data: chartData,
                            monthTitle: selectedMonthTitle,
                            canGoForward: canGoForwardMonth,
                            onPreviousMonth: { viewModel.showPreviousMonth() },
                            onNextMonth: { viewModel.showNextMonth() }
                        )

                        earthImpactCard

                        trashedItemsSection

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
            Text(summaryTitle)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary.opacity(0.6))
                .tracking(1.2)

            Text(String(format: "$%.2f", totalLostThisMonth))
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(.black)

            HStack(spacing: 6) {
                Circle()
                    .fill(trendColor)
                    .frame(width: 8, height: 8)
                
                Text(trendMessage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(trendColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(trendColor.opacity(0.12), in: Capsule())
        }
    }

    private var trashedItemsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Trashed Items")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
            }

            VStack(spacing: 16) {
                if trashedItems.isEmpty {
                    Text("No waste items logged yet.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(trashedItems, id: \.id) { item in
                        trashedRow(for: item)
                    }
                }
            }
        }
    }

    private func trashedRow(for item: FoodItem) -> some View {
        return HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.03))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "leaf.fill") 
                    .font(.title2)
                    .foregroundStyle(.black.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)

                Text("\(viewModel.amountLabel(for: item)) • \(viewModel.currencyString(for: item.purchaseValue))")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .cardShadow, radius: 12, x: 0, y: 8)
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
}

#Preview {
    WasteJarView()
        .modelContainer(PreviewHelper.previewContainer)
}
