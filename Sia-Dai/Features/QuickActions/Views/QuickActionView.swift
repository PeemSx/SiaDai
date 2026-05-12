import SwiftUI
import UIKit

struct QuickActionView: View {
    let item: FoodItem
    let viewModel: QuickActionsViewModel
    let onMarkEaten: () -> Void
    let onMarkTrashed: () -> Void

    private var daysRemaining: Int {
        Date().daysUntil(item.expiryDate)
    }

    private var urgency: QuickActionUrgency {
        viewModel.urgency(for: item)
    }

    private var fallbackAccentColor: Color {
        switch daysRemaining {
        case ...0:
            return .statusCrimson
        case 1...3:
            return .statusAmber
        default:
            return .statusEmerald
        }
    }

    private var fallbackPalette: [Color] {
        let lowercasedName = item.name.lowercased()

        if lowercasedName.contains("salmon") {
            return [Color(red: 0.10, green: 0.13, blue: 0.15), Color(red: 0.28, green: 0.17, blue: 0.14)]
        }

        if lowercasedName.contains("milk") {
            return [Color(red: 0.31, green: 0.24, blue: 0.16), Color(red: 0.08, green: 0.09, blue: 0.12)]
        }

        if lowercasedName.contains("spinach") {
            return [Color(red: 0.12, green: 0.18, blue: 0.16), Color(red: 0.24, green: 0.32, blue: 0.28)]
        }

        if lowercasedName.contains("apple") {
            return [Color(red: 0.25, green: 0.25, blue: 0.28), Color(red: 0.17, green: 0.18, blue: 0.20)]
        }

        return [Color(red: 0.14, green: 0.22, blue: 0.20), Color(red: 0.10, green: 0.16, blue: 0.15)]
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
                    .fill(fallbackAccentColor.opacity(0.24))
                    .frame(width: 140, height: 140)
                    .blur(radius: 12)
                    .offset(x: 44, y: 34)

                Image(systemName: fallbackSymbolName)
                    .font(.system(size: 66, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1.5)
                    .padding(18)
            }
            .frame(width: size.width, height: size.height)
        }
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
