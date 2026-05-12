import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class WatchlistViewModel {
    // The view model owns the context reference so it can fetch and update items.
    private let modelContext: ModelContext

    // The UI reads from this array to render only currently tracked food.
    var activeItems: [FoodItem] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchActiveItems()
    }

    // Loads all items that are still being tracked, sorted by earliest expiry first.
    func fetchActiveItems() {
        // Capturing the value first avoids the macro expanding `.tracking` as a key path.
        let trackingStatus = FoodItemStatus.tracking

        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> { item in
                item.status == trackingStatus
            },
            sortBy: [SortDescriptor(\.expiryDate)]
        )

        do {
            activeItems = try modelContext.fetch(descriptor)
        } catch {
            activeItems = []
            assertionFailure("Failed to fetch active food items: \(error)")
        }
    }

    // Maps expiry timing to the UI color system used by the watchlist cards.
    func getUrgencyColor(for item: FoodItem) -> Color {
        let daysRemaining = Date().daysUntil(item.expiryDate)

        switch daysRemaining {
        case ...0:
            return .statusCrimson
        case 1...3:
            return .statusAmber
        default:
            return .statusEmerald
        }
    }

    func markAsEaten(item: FoodItem) {
        item.status = .eaten
        item.wasteRecordedAt = nil
        saveChangesAndRefresh()
    }

    func markAsTrashed(item: FoodItem) {
        item.status = .trashed
        item.wasteRecordedAt = .now
        saveChangesAndRefresh()
    }

    // Centralizes persistence so status updates stay consistent across actions.
    private func saveChangesAndRefresh() {
        do {
            try modelContext.save()
            fetchActiveItems()
        } catch {
            modelContext.rollback()
            assertionFailure("Failed to save watchlist changes: \(error)")
        }
    }
}
