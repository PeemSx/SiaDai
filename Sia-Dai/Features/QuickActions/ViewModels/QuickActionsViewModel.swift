import Foundation
import SwiftData
import SwiftUI

enum QuickActionUrgency: Equatable {
    case critical
    case soon
    case fresh

    var badgeTitle: String {
        switch self {
        case .critical:
            return "HIGH URGENCY"
        case .soon:
            return "USE SOON"
        case .fresh:
            return "FRESH WINDOW"
        }
    }

    var accentColor: Color {
        switch self {
        case .critical:
            return .statusCrimson
        case .soon:
            return .statusAmber
        case .fresh:
            return .brandGreen
        }
    }

    var badgeBackground: Color {
        switch self {
        case .critical:
            return Color(red: 0.99, green: 0.60, blue: 0.66)
        case .soon:
            return Color(red: 0.98, green: 0.85, blue: 0.47)
        case .fresh:
            return Color.brandGreen.opacity(0.18)
        }
    }

    var pointsBonus: Int {
        switch self {
        case .critical:
            return 4
        case .soon:
            return 2
        case .fresh:
            return 1
        }
    }
}

@MainActor
final class QuickActionsViewModel {
    func priorityItem(
        from foodItems: [FoodItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> FoodItem? {
        trackingItems(from: foodItems)
            .sorted {
                let lhsDays = referenceDate.daysUntil($0.expiryDate, calendar: calendar)
                let rhsDays = referenceDate.daysUntil($1.expiryDate, calendar: calendar)

                if lhsDays != rhsDays {
                    return lhsDays < rhsDays
                }

                if $0.purchaseValue != $1.purchaseValue {
                    return $0.purchaseValue > $1.purchaseValue
                }

                return $0.dateAdded < $1.dateAdded
            }
            .first
    }

    func preventableLoss(
        from foodItems: [FoodItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Double {
        let activeItems = trackingItems(from: foodItems)
        let atRiskItems = activeItems.filter {
            referenceDate.daysUntil($0.expiryDate, calendar: calendar) <= 3
        }

        let source = atRiskItems.isEmpty ? activeItems : atRiskItems
        return source.reduce(0) { $0 + $1.purchaseValue }
    }

    func urgency(
        for item: FoodItem,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> QuickActionUrgency {
        let daysRemaining = referenceDate.daysUntil(item.expiryDate, calendar: calendar)

        switch daysRemaining {
        case ...0:
            return .critical
        case 1...2:
            return .soon
        default:
            return .fresh
        }
    }

    func expiryHeadline(
        for item: FoodItem,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let daysRemaining = referenceDate.daysUntil(item.expiryDate, calendar: calendar)

        switch daysRemaining {
        case ...0:
            return "Expires TODAY!"
        case 1:
            return "Expires TOMORROW"
        default:
            return "Use in \(daysRemaining) days"
        }
    }

    func impactPoints(for item: FoodItem) -> Int {
        let valueScore = min(16, max(6, Int((item.purchaseValue * 1.6).rounded())))
        return valueScore + urgency(for: item).pointsBonus
    }

    func remainingTimeText(
        for item: FoodItem,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let endOfExpiryDay = calendar.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: item.expiryDate
        ) ?? item.expiryDate

        let remainingSeconds = max(0, endOfExpiryDay.timeIntervalSince(referenceDate))
        let remainingHours = Int(ceil(remainingSeconds / 3600))

        if remainingHours < 24 {
            return "\(max(0, remainingHours))h"
        }

        let remainingDays = Int(ceil(Double(remainingHours) / 24))
        return "\(remainingDays)d"
    }

    func freshnessProgress(
        for item: FoodItem,
        referenceDate: Date = .now
    ) -> Double {
        let totalDuration = item.expiryDate.timeIntervalSince(item.dateAdded)
        let remainingDuration = item.expiryDate.timeIntervalSince(referenceDate)

        guard totalDuration > 0 else {
            return remainingDuration > 0 ? 1 : 0
        }

        return min(max(remainingDuration / totalDuration, 0), 1)
    }

    func amountLabel(for item: FoodItem) -> String {
        let formattedAmount: String

        if item.amount.rounded() == item.amount {
            formattedAmount = "\(Int(item.amount))"
        } else {
            formattedAmount = String(format: "%.1f", item.amount)
        }

        let compactUnits = ["g", "kg", "ml", "L"]
        if compactUnits.contains(item.unit) {
            return "\(formattedAmount)\(item.unit)"
        }

        return "\(formattedAmount) \(item.unit)"
    }

    func currencyString(for value: Double) -> String {
        return String(format: "฿%.2f", value)
    }

    @discardableResult
    func updateStatus(
        _ status: FoodItemStatus,
        for item: FoodItem,
        in modelContext: ModelContext
    ) -> Bool {
        let originalStatus = item.status
        let originalWasteRecordedAt = item.wasteRecordedAt
        item.status = status
        item.wasteRecordedAt = status == .trashed ? .now : nil

        do {
            try modelContext.save()
            return true
        } catch {
            item.status = originalStatus
            item.wasteRecordedAt = originalWasteRecordedAt
            modelContext.rollback()
            print("Quick action save failed: \(error)")
            return false
        }
    }

    private func trackingItems(from foodItems: [FoodItem]) -> [FoodItem] {
        foodItems.filter { $0.status == .tracking }
    }
}
