import SwiftUI

struct RescueRecipeDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let recipe: RescueRecipe
    let sourceItems: [FoodItem]
    let onMarkRecipeAsMade: (RescueRecipe) -> RecipeInventoryApplicationResult

    @State private var isApplyingRecipe = false
    @State private var alertMessage = ""
    @State private var showsAlert = false

    private let ingredientColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Color.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        heroSection
                        summarySection
                        trackedIngredientsSection
                        otherIngredientsSection
                        instructionsSection
                        markAsMadeSection
                    }
                    .padding(.bottom, 140)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Couldn't Update Inventory", isPresented: $showsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var headerBar: some View {
        HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(.plain)

            Text("Recipe Details")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.black)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 18)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.04))
                .frame(height: 1)
        }
    }

    private var heroSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                RecipeArtworkView(recipe: recipe, sourceItems: sourceItems)
                    .frame(height: 318)

                LinearGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(0.14),
                        Color.black.opacity(0.62)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(recipe.ingredientSummary)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .frame(height: 318)

            statsPill
                .padding(.horizontal, 20)
                .offset(y: -24)
                .padding(.bottom, -24)
        }
    }

    private var statsPill: some View {
        HStack(spacing: 0) {
            statBlock(title: "PREP", value: "\(recipe.prepMinutes)m")
            statDivider
            statBlock(title: "COOK", value: "\(recipe.cookMinutes)m")
            statDivider
            statBlock(title: "DIFFICULTY", value: recipe.difficulty, highlight: true)
            statDivider
            statBlock(title: "SERVINGS", value: "\(recipe.servings)")
        }
        .padding(.vertical, 18)
        .background(Color.white, in: Capsule())
        .shadow(color: .cardShadow, radius: 16, x: 0, y: 12)
    }

    private func statBlock(title: String, value: String, highlight: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.secondary.opacity(0.7))

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(highlight ? Color.brandGreen : .black)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.07))
            .frame(width: 1, height: 42)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(recipe.summary)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.76))
                .lineSpacing(5)

            VStack(alignment: .leading, spacing: 12) {
                Text("STORAGE TIP")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(.secondary.opacity(0.72))

                Text(recipe.storageTip)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
            .padding(22)
            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .padding(.horizontal, 24)
    }

    private var trackedIngredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TRACKED INGREDIENTS USED")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(1.7)
                    .foregroundStyle(.secondary.opacity(0.72))

                Spacer()

                Text("Inventory Match")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(Color.brandGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.brandGreen.opacity(0.10), in: Capsule())
            }

            LazyVGrid(columns: ingredientColumns, spacing: 16) {
                ForEach(recipe.matchedIngredients) { usage in
                    trackedIngredientCard(for: usage)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func trackedIngredientCard(for usage: RecipeIngredientUsage) -> some View {
        let item = sourceItems.first(where: { $0.id == usage.foodItemID })
        let urgencyColor = urgencyColor(for: item)
        let systemSymbol = symbolName(for: usage.itemName)

        return VStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(urgencyColor.opacity(0.12))
                    .frame(width: 54, height: 54)

                Image(systemName: systemSymbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(urgencyColor)
            }

            VStack(spacing: 6) {
                Text(usage.itemName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("Use \(FoodQuantityFormatter.string(amount: usage.amount, unit: usage.unit))")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.72))

                if let item {
                    Text("From \(FoodQuantityFormatter.string(amount: item.amount, unit: item.unit)) tracked")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let item {
                Text(item.expiryDate.watchlistStatusHeadline())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(urgencyColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(urgencyColor.opacity(0.10), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 18)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(urgencyColor)
                .frame(width: 5)
                .padding(.vertical, 16)
        }
        .shadow(color: .cardShadow, radius: 12, x: 0, y: 8)
    }

    private var otherIngredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OTHER INGREDIENTS")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(1.7)
                .foregroundStyle(.secondary.opacity(0.72))

            VStack(alignment: .leading, spacing: 14) {
                ForEach(recipe.otherIngredients, id: \.self) { ingredient in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.brandGreen.opacity(0.72))
                            .frame(width: 6, height: 6)

                        Text(ingredient)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.black.opacity(0.80))
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .padding(.horizontal, 24)
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("STEP-BY-STEP INSTRUCTIONS")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(1.7)
                .foregroundStyle(.secondary.opacity(0.72))

            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 18) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.12))
                            .frame(width: 32, alignment: .leading)

                        Text(step)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.black.opacity(0.82))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var markAsMadeSection: some View {
        VStack(spacing: 12) {
            Button {
                applyRecipe()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.brandGreen)

                    if isApplyingRecipe {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("MARK RECIPE AS MADE")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 72)
            }
            .buttonStyle(.plain)
            .disabled(isApplyingRecipe)

            Text("Watchlist amounts update automatically after the recipe is marked as made.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private func applyRecipe() {
        guard isApplyingRecipe == false else { return }

        isApplyingRecipe = true
        let result = onMarkRecipeAsMade(recipe)
        isApplyingRecipe = false

        if result.didApply {
            dismiss()
        } else {
            alertMessage = result.message
            showsAlert = true
        }
    }

    private func urgencyColor(for item: FoodItem?) -> Color {
        guard let item else { return .brandGreen }

        switch Date().daysUntil(item.expiryDate) {
        case ...0:
            return .statusCrimson
        case 1...3:
            return .statusAmber
        default:
            return .statusEmerald
        }
    }

    private func symbolName(for ingredientName: String) -> String {
        let lowercasedName = ingredientName.lowercased()

        if lowercasedName.contains("salmon") || lowercasedName.contains("fish") {
            return "fish.fill"
        }

        if lowercasedName.contains("milk") || lowercasedName.contains("yogurt") {
            return "drop.fill"
        }

        if lowercasedName.contains("spinach") || lowercasedName.contains("leaf") {
            return "leaf.fill"
        }

        if lowercasedName.contains("apple") {
            return "basket.fill"
        }

        return "fork.knife"
    }
}
