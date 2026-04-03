import SwiftUI
import SwiftData

struct WasteJarView: View {
    @Query private var foodItems: [FoodItem]

    private var trashedItems: [FoodItem] {
        foodItems.filter { $0.status == .trashed }
    }

    private var totalWaste: Double {
        trashedItems.reduce(0) { partialResult, item in
            partialResult + item.purchaseValue
        }
    }

    var body: some View {
        ZStack {
            Color.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    VStack(spacing: 16) {
                        insightCard

                        if trashedItems.isEmpty {
                            emptyState
                        } else {
                            ForEach(trashedItems, id: \.id) { item in
                                trashedItemRow(item: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 132)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("WASTE IMPACT")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)

                Text("Waste Jar")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
            }

            Spacer(minLength: 12)

            Text(totalWaste.formatted(.currency(code: "USD")))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.wasteJarPink, in: Capsule())
        }
    }

    private var insightCard: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Loss")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(totalWaste.formatted(.currency(code: "USD")))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)

                    Text("\(trashedItems.count) item\(trashedItems.count == 1 ? "" : "s") marked as wasted.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .shadow(color: .cardShadow, radius: 16, x: 0, y: 10)
    }

    private var emptyState: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "leaf.circle")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color.brandGreen)

                    Text("No waste logged")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.black)

                    Text("When items are marked as trashed, the summary will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
            }
    }

    private func trashedItemRow(item: FoodItem) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.wasteJarPink.opacity(0.16))
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(Color.wasteJarPink)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black)

                Text(item.expiryDate.watchlistExpiryText())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.purchaseValue.formatted(.currency(code: "USD")))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.statusCrimson)
        }
        .padding(18)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .cardShadow, radius: 12, x: 0, y: 8)
    }
}

#Preview {
    WasteJarView()
        .modelContainer(PreviewHelper.previewContainer)
}
