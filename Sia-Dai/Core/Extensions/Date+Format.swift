import Foundation

extension Date {
    func daysUntil(
        _ futureDate: Date,
        calendar: Calendar = .current
    ) -> Int {
        let start = calendar.startOfDay(for: self)
        let end = calendar.startOfDay(for: futureDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    func watchlistExpiryText(calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(self) {
            return "Expires today"
        }

        if calendar.isDateInTomorrow(self) {
            return "Expires tomorrow"
        }

        return "Expires \(formatted(.dateTime.month(.abbreviated).day()))"
    }

    func watchlistStatusHeadline(relativeTo referenceDate: Date = .now, calendar: Calendar = .current) -> String {
        let daysRemaining = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: referenceDate),
            to: calendar.startOfDay(for: self)
        ).day ?? 0

        if daysRemaining <= 0 {
            return "EXPIRING TODAY"
        }

        if daysRemaining == 1 {
            return "1 DAY LEFT"
        }

        return "\(daysRemaining) DAYS LEFT"
    }

    func watchlistDateLabel(calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(self) {
            return "TODAY"
        }

        return formatted(.dateTime.month(.abbreviated).day()).uppercased()
    }
}
