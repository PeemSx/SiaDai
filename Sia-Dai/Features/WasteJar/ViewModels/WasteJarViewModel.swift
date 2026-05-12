import Foundation
import Observation
import SwiftUI

struct WasteData: Identifiable {
    let id: String
    let week: String
    let amount: Double
}

@MainActor
@Observable
final class WasteJarViewModel {
    var selectedMonthStart: Date

    init(referenceDate: Date = .now, calendar: Calendar = .current) {
        selectedMonthStart = Self.makeMonthStart(from: referenceDate, calendar: calendar)
    }

    var selectedMonthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonthStart)
    }

    var summaryTitle: String {
        "TOTAL LOST IN \(selectedMonthTitle.uppercased())"
    }

    func wastedItems(
        from foodItems: [FoodItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [FoodItem] {
        foodItems.filter { item in
            if item.status == .trashed {
                return true
            }

            guard item.status == .tracking else {
                return false
            }

            return hasExpiryDayPassed(for: item, referenceDate: referenceDate, calendar: calendar)
        }
    }

    func trashedItems(
        from foodItems: [FoodItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [FoodItem] {
        wastedItems(from: foodItems, referenceDate: referenceDate, calendar: calendar)
            .sorted { lhs, rhs in
                let lhsEventDate = wasteEventDate(for: lhs)
                let rhsEventDate = wasteEventDate(for: rhs)

                if lhsEventDate != rhsEventDate {
                    return lhsEventDate > rhsEventDate
                }

                return lhs.dateAdded > rhs.dateAdded
            }
    }

    func selectedMonthWasteItems(
        from foodItems: [FoodItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [FoodItem] {
        wastedItems(from: foodItems, referenceDate: referenceDate, calendar: calendar)
            .filter { item in
                calendar.isDate(
                    wasteEventDate(for: item),
                    equalTo: selectedMonthStart,
                    toGranularity: .month
                )
            }
    }

    func totalLostThisMonth(
        from foodItems: [FoodItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Double {
        selectedMonthWasteItems(from: foodItems, referenceDate: referenceDate, calendar: calendar)
            .reduce(0) { $0 + $1.purchaseValue }
    }

    func totalWeightLostThisMonth(
        from foodItems: [FoodItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Double {
        selectedMonthWasteItems(from: foodItems, referenceDate: referenceDate, calendar: calendar)
            .reduce(0) { $0 + ($1.amount * 0.5) }
    }

    func chartData(
        from foodItems: [FoodItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [WasteData] {
        weeklyWasteData(
            for: selectedMonthStart,
            from: foodItems,
            referenceDate: referenceDate,
            calendar: calendar
        )
    }

    func canGoForwardMonth(
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        selectedMonthStart < Self.makeMonthStart(from: referenceDate, calendar: calendar)
    }

    func trendMessage(
        from foodItems: [FoodItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let totalLostThisMonth = totalLostThisMonth(
            from: foodItems,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let previousMonthLoss = previousMonthLoss(
            from: foodItems,
            referenceDate: referenceDate,
            calendar: calendar
        )

        if totalLostThisMonth == 0 && previousMonthLoss == 0 {
            return "No waste logged in this month"
        }

        if previousMonthLoss == 0 {
            return "Started logging waste this month"
        }

        let percentChange = abs((totalLostThisMonth - previousMonthLoss) / previousMonthLoss * 100)
        let roundedChange = Int(percentChange.rounded())

        if totalLostThisMonth > previousMonthLoss {
            return "\(roundedChange)% higher than previous month"
        }

        if totalLostThisMonth < previousMonthLoss {
            return "\(roundedChange)% lower than previous month"
        }

        return "Same as previous month"
    }

    func trendColor(
        from foodItems: [FoodItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Color {
        let totalLostThisMonth = totalLostThisMonth(
            from: foodItems,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let previousMonthLoss = previousMonthLoss(
            from: foodItems,
            referenceDate: referenceDate,
            calendar: calendar
        )

        if totalLostThisMonth == 0 && previousMonthLoss == 0 {
            return .secondary
        }

        if previousMonthLoss == 0 {
            return .brandGreen
        }

        if totalLostThisMonth > previousMonthLoss {
            return .statusCrimson
        }

        if totalLostThisMonth < previousMonthLoss {
            return .brandGreen
        }

        return .secondary
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
        if value.rounded() == value {
            return String(format: "$%.0f", value)
        }

        return String(format: "$%.2f", value)
    }

    func showPreviousMonth(calendar: Calendar = .current) {
        selectedMonthStart = calendar.date(byAdding: .month, value: -1, to: selectedMonthStart) ?? selectedMonthStart
    }

    func showNextMonth(
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) {
        guard canGoForwardMonth(referenceDate: referenceDate, calendar: calendar) else { return }
        selectedMonthStart = calendar.date(byAdding: .month, value: 1, to: selectedMonthStart) ?? selectedMonthStart
    }

    private func previousMonthLoss(
        from foodItems: [FoodItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Double {
        let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: selectedMonthStart) ?? selectedMonthStart

        return wastedItems(from: foodItems, referenceDate: referenceDate, calendar: calendar)
            .filter { item in
                calendar.isDate(
                    wasteEventDate(for: item),
                    equalTo: previousMonthStart,
                    toGranularity: .month
                )
            }
            .reduce(0) { $0 + $1.purchaseValue }
    }

    private func wasteEventDate(for item: FoodItem) -> Date {
        if item.status == .trashed {
            return item.wasteRecordedAt ?? item.expiryDate
        }

        return item.expiryDate
    }

    private func hasExpiryDayPassed(
        for item: FoodItem,
        referenceDate: Date,
        calendar: Calendar
    ) -> Bool {
        let startOfExpiryDay = calendar.startOfDay(for: item.expiryDate)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfExpiryDay) ?? startOfExpiryDay
        return referenceDate >= startOfNextDay
    }

    private func weeklyWasteData(
        for monthStart: Date,
        from foodItems: [FoodItem],
        referenceDate: Date,
        calendar: Calendar
    ) -> [WasteData] {
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 28
        let bucketCount = Int(ceil(Double(daysInMonth) / 7.0))
        var totals = Array(repeating: 0.0, count: bucketCount)

        for item in selectedMonthWasteItems(
            from: foodItems,
            referenceDate: referenceDate,
            calendar: calendar
        ) {
            let dayOfMonth = calendar.component(.day, from: wasteEventDate(for: item))
            let bucketIndex = min(bucketCount - 1, max(0, (dayOfMonth - 1) / 7))
            totals[bucketIndex] += item.purchaseValue
        }

        return totals.enumerated().map { index, total in
            let weekNumber = index + 1
            return WasteData(
                id: "wk-\(weekNumber)",
                week: String(format: "WK %02d", weekNumber),
                amount: total
            )
        }
    }

    private static func makeMonthStart(
        from date: Date,
        calendar: Calendar
    ) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}
