import Foundation
import SwiftData

enum FoodItemStatus: String, Codable, CaseIterable, Identifiable {
    case tracking = "Tracking"
    case eaten = "Eaten"
    case trashed = "Trashed"

    var id: String { rawValue }
}

@Model
final class FoodItem {
    var id: UUID
    var name: String
    @Attribute(.externalStorage) var imageData: Data?
    var purchaseValue: Double
    var amount: Double
    var unit: String
    var dateAdded: Date
    var expiryDate: Date
    var status: FoodItemStatus

    init(
        id: UUID = UUID(),
        name: String,
        imageData: Data? = nil,
        purchaseValue: Double,
        amount: Double,
        unit: String,
        dateAdded: Date = .now,
        expiryDate: Date,
        status: FoodItemStatus = .tracking
    ) {
        self.id = id
        self.name = name
        self.imageData = imageData
        self.purchaseValue = purchaseValue
        self.amount = amount
        self.unit = unit
        self.dateAdded = dateAdded
        self.expiryDate = expiryDate
        self.status = status
    }
}
