import Foundation
import SwiftData

@MainActor
enum PreviewHelper {
    static let previewContainer: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(
                for: FoodItem.self,
                configurations: configuration
            )

            sampleFoodItems.forEach { container.mainContext.insert($0) }
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()

    static var sampleFoodItems: [FoodItem] {
        let calendar = Calendar.current
        let now = Date()

        return [
            FoodItem(
                name: "Salmon",
                purchaseValue: 12.99,
                amount: 2,
                unit: "fillets",
                dateAdded: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                expiryDate: now,
                status: .tracking
            ),
            FoodItem(
                name: "Whole Milk",
                purchaseValue: 3.49,
                amount: 1,
                unit: "L",
                dateAdded: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                expiryDate: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                status: .tracking
            ),
            FoodItem(
                name: "Spinach",
                purchaseValue: 5.00,
                amount: 250,
                unit: "g",
                dateAdded: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                expiryDate: calendar.date(byAdding: .day, value: 5, to: now) ?? now,
                status: .tracking
            ),
            FoodItem(
                name: "Apples",
                purchaseValue: 6.25,
                amount: 4,
                unit: "pcs",
                dateAdded: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                expiryDate: calendar.date(byAdding: .day, value: 8, to: now) ?? now,
                status: .tracking
            ),
            FoodItem(
                name: "Greek Yogurt",
                purchaseValue: 4.50,
                amount: 1,
                unit: "cup",
                dateAdded: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                expiryDate: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
                status: .eaten
            ),
            FoodItem(
                name: "Beef Steak",
                purchaseValue: 15.00,
                amount: 1,
                unit: "pack",
                dateAdded: calendar.date(byAdding: .day, value: -6, to: now) ?? now,
                expiryDate: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                status: .trashed
            )
        ]
    }
}
