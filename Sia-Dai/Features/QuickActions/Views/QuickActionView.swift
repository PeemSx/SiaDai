import SwiftUI
import UIKit

struct QuickActionView: View {
    let item: FoodItem
    let viewModel: QuickActionsViewModel
    let onMarkEaten: () -> Void
    let onMarkTrashed: () -> Void

    private var urgency: QuickActionUrgency {
        viewModel.urgency(for: item)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            featuredCard

            HStack(spacing: 14) {
                actionButton(
                    title: "I Ate It",
                    subtitle: "SAVE \(viewModel.currencyString(for: item.purchaseValue))",
                    icon: "checkmark.circle.fill",
                    tint: Color(red: 0.32, green: 0.80, blue: 0.47),
                    foreground: .white,
                    action: onMarkEaten
                )

                actionButton(
                    title: "Trash It",
                    subtitle: "LOSE \(viewModel.currencyString(for: item.purchaseValue))",
                    icon: "trash",
                    tint: Color(red: 0.90, green: 0.91, blue: 0.92),
                    foreground: Color.black.opacity(0.75),
                    action: onMarkTrashed
                )
            }

            impactCard
        }
    }

    private var featuredCard: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                coverImage(size: proxy.size)

                LinearGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(0.10),
                        Color.black.opacity(0.60)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 14) {
                    Text(urgency.badgeTitle)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(urgency == .fresh ? Color.brandGreen : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(urgency.badgeBackground, in: Capsule())

                    Spacer()

                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.expiryHeadline(for: item))
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)

                        Text("\(item.name) • \(viewModel.amountLabel(for: item))")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }
                .padding(26)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        }
        .frame(height: 348)
        .shadow(color: Color.black.opacity(0.16), radius: 22, x: 0, y: 14)
    }

    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))

                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))

                    Text(subtitle)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(0.8)
                }
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 138)
            .background(tint, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var impactCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("IMPACT SCORE")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("+\(viewModel.impactPoints(for: item)) XP")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.black)

                    Text("Earned if consumed")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.brandGreen)
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.08), lineWidth: 7)

                Circle()
                    .trim(from: 0, to: max(0.08, viewModel.freshnessProgress(for: item)))
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.statusCrimson,
                                Color.statusAmber,
                                Color.brandGreen
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text(viewModel.remainingTimeText(for: item))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.74))
            }
            .frame(width: 56, height: 56)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.90))
        )
        .shadow(color: .cardShadow, radius: 14, x: 0, y: 10)
    }

    @ViewBuilder
    private func coverImage(size: CGSize) -> some View {
        if let imageData = item.imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            ZStack {
                LinearGradient(
                    colors: fallbackPalette,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 220, height: 220)
                    .blur(radius: 20)
                    .offset(x: -80, y: -60)

                Circle()
                    .fill(urgency.accentColor.opacity(0.26))
                    .frame(width: 210, height: 210)
                    .blur(radius: 18)
                    .offset(x: 90, y: 80)

                Image(systemName: fallbackSymbolName)
                    .font(.system(size: 110, weight: .regular))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private var fallbackPalette: [Color] {
        let lowercasedName = item.name.lowercased()

        if lowercasedName.contains("spinach") || lowercasedName.contains("leaf") {
            return [
                Color(red: 0.26, green: 0.68, blue: 0.57),
                Color(red: 0.05, green: 0.31, blue: 0.24)
            ]
        }

        if lowercasedName.contains("apple") {
            return [
                Color(red: 0.28, green: 0.64, blue: 0.34),
                Color(red: 0.07, green: 0.24, blue: 0.14)
            ]
        }

        if lowercasedName.contains("salmon") || lowercasedName.contains("fish") {
            return [
                Color(red: 0.21, green: 0.27, blue: 0.31),
                Color(red: 0.07, green: 0.12, blue: 0.14)
            ]
        }

        return [
            Color(red: 0.24, green: 0.52, blue: 0.44),
            Color(red: 0.07, green: 0.21, blue: 0.18)
        ]
    }

    private var fallbackSymbolName: String {
        let lowercasedName = item.name.lowercased()

        if lowercasedName.contains("salmon") || lowercasedName.contains("fish") {
            return "fish.fill"
        }

        if lowercasedName.contains("milk") {
            return "drop.fill"
        }

        if lowercasedName.contains("spinach") || lowercasedName.contains("leaf") {
            return "leaf.fill"
        }

        if lowercasedName.contains("apple") {
            return "basket.fill"
        }

        return "carrot.fill"
    }
}

#Preview {
    ZStack {
        Color.screenBackground
            .ignoresSafeArea()

        QuickActionView(
            item: PreviewHelper.sampleFoodItems[0],
            viewModel: QuickActionsViewModel(),
            onMarkEaten: {},
            onMarkTrashed: {}
        )
        .padding(24)
    }
}
