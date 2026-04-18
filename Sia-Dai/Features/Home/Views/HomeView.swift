import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodItem.expiryDate) private var foodItems: [FoodItem]

    @State private var quickActionMessage: String?

    private let viewModel = QuickActionsViewModel()

    private var priorityItem: FoodItem? {
        viewModel.priorityItem(from: foodItems)
    }

    private var preventableLoss: Double {
        viewModel.preventableLoss(from: foodItems)
    }

    var body: some View {
        ZStack {
            Color.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopBrandBar()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        headerSection

                        if let quickActionMessage {
                            feedbackChip(message: quickActionMessage)
                        }

                        if let priorityItem {
                            QuickActionView(
                                item: priorityItem,
                                viewModel: viewModel,
                                onMarkEaten: {
                                    performQuickAction(.eaten, for: priorityItem)
                                },
                                onMarkTrashed: {
                                    performQuickAction(.trashed, for: priorityItem)
                                }
                            )
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 180)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRIORITIES")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(Color.brandGreen)

            Text("Quick Actions")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.black)

            Text("Prevent \(viewModel.currencyString(for: preventableLoss)) from being wasted.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private func feedbackChip(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .bold))

            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(Color.brandGreen)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.brandGreen.opacity(0.10), in: Capsule())
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your quick actions are clear.")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.black)

            Text("Add more ingredients to the watchlist to surface items that need attention first.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.brandGreen)

                Text("The Home tab will highlight the most urgent tracked item once inventory is available.")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.72))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.94, green: 0.97, blue: 0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: .cardShadow, radius: 16, x: 0, y: 10)
    }

    private func performQuickAction(_ status: FoodItemStatus, for item: FoodItem) {
        let didSave = viewModel.updateStatus(status, for: item, in: modelContext)

        guard didSave else {
            quickActionMessage = "Couldn’t update this item right now."
            return
        }

        let actionText = status == .eaten ? "saved" : "logged"
        let valueText = viewModel.currencyString(for: item.purchaseValue)

        withAnimation(.snappy(duration: 0.28, extraBounce: 0)) {
            quickActionMessage = "\(item.name) \(actionText) for \(valueText)."
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewHelper.previewContainer)
}
