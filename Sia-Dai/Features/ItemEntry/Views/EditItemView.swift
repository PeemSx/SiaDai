import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let item: FoodItem

    @State private var nameText: String
    @State private var valueText: String
    @State private var amountText: String
    @State private var selectedUnit: String
    @State private var selectedExpiryDays: Int
    @State private var isCustomExpiry: Bool
    @State private var expiryDate: Date
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var saveFeedbackMessage: String?
    @State private var showsDeleteConfirmation = false

    private let unitOptions = ItemEntryViewModel.supportedUnits
    private let expiryOptions = [3, 5, 7, 0]

    init(item: FoodItem) {
        let calendar = Calendar.current
        let daysUntilExpiry = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: .now),
            to: calendar.startOfDay(for: item.expiryDate)
        ).day ?? 0
        let usesCustomExpiry = ![3, 5, 7].contains(daysUntilExpiry)

        self.item = item
        _nameText = State(initialValue: item.name)
        _valueText = State(initialValue: Self.decimalText(for: item.purchaseValue))
        _amountText = State(initialValue: Self.decimalText(for: item.amount))
        _selectedUnit = State(initialValue: Self.initialUnit(from: item.unit))
        _selectedExpiryDays = State(initialValue: usesCustomExpiry ? 0 : daysUntilExpiry)
        _isCustomExpiry = State(initialValue: usesCustomExpiry)
        _expiryDate = State(initialValue: item.expiryDate)
        _selectedImageData = State(initialValue: item.imageData)
    }

    private var canSave: Bool {
        Double(valueText.replacingOccurrences(of: ",", with: ".")) != nil &&
        Double(amountText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.screenBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        heroSection
                        formSection
                        deleteSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Delete Ingredient?", isPresented: $showsDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteItem()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove \(item.name) from your inventory.")
        }
        .task(id: selectedPhotoItem) {
            await loadSelectedPhoto()
        }
    }

    private var heroSection: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                heroImage(size: proxy.size)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        Color.clear,
                        Color.black.opacity(0.42)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: proxy.size.width, height: proxy.size.height)

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Text(selectedImageData == nil ? "Add Photo" : "Change Photo")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(Color.black.opacity(0.34), in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
                .padding(.trailing, 20)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
        .frame(height: 310)
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SiaDai")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.brandGreen)

                Text("Edit Ingredient")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)

                nameField
            }

            VStack(alignment: .leading, spacing: 12) {
                fieldLabel("VALUE (฿)")
                moneyField
            }

            VStack(alignment: .leading, spacing: 12) {
                fieldLabel("AMOUNT")
                amountRow
            }

            VStack(alignment: .leading, spacing: 14) {
                fieldLabel("EXPIRES IN:")
                expiryRow

                if isCustomExpiry {
                    DatePicker(
                        "Custom Expiry Date",
                        selection: $expiryDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.brandGreen)
                    .padding(16)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }

            if let saveFeedbackMessage {
                Text(saveFeedbackMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.statusCrimson)
            }

            Button {
                saveItem()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 24, weight: .semibold))

                    Text("Save Changes")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 86)
                .background(
                    canSave ? Color.brandGreen : Color.brandGreen.opacity(0.38),
                    in: Capsule()
                )
                .shadow(color: Color.brandGreen.opacity(canSave ? 0.20 : 0), radius: 16, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
    }

    private var deleteSection: some View {
        VStack(spacing: 16) {
            Divider()

            Button(role: .destructive) {
                showsDeleteConfirmation = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .bold))

                    Text("Delete Ingredient")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.statusCrimson)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.statusCrimson.opacity(0.18), lineWidth: 1.2)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var nameField: some View {
        HStack(spacing: 10) {
            TextField("Item Name", text: $nameText)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 108)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var moneyField: some View {
        HStack(spacing: 10) {
            Text("฿")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.secondary.opacity(0.38))

            TextField("0.00", text: $valueText)
                .keyboardType(.decimalPad)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 108)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var amountRow: some View {
        HStack(spacing: 14) {
            TextField("250", text: $amountText)
                .keyboardType(.decimalPad)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 76)
                .background(Color(red: 0.95, green: 0.95, blue: 0.95), in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            Menu {
                ForEach(unitOptions, id: \.self) { unit in
                    Button(unit) {
                        selectedUnit = unit
                    }
                }
            } label: {
                HStack {
                    Text(selectedUnit)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .background(Color(red: 0.95, green: 0.95, blue: 0.95), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var expiryRow: some View {
        HStack(spacing: 12) {
            ForEach(expiryOptions, id: \.self) { days in
                expiryOption(days: days)
            }
        }
    }

    private func expiryOption(days: Int) -> some View {
        let isSelected = selectedExpiryDays == days
        let palette = expiryPalette(for: days)

        return Button {
            selectedExpiryDays = days
            if days == 0 {
                isCustomExpiry = true
            } else {
                isCustomExpiry = false
                expiryDate = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
            }
        } label: {
            VStack(spacing: 12) {
                Text(expiryTitle(for: days))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.foreground)

                Circle()
                    .fill(palette.foreground)
                    .frame(width: 8, height: 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(palette.background)
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(isSelected ? palette.stroke : .clear, lineWidth: 2.2)
                    }
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func heroImage(size: CGSize) -> some View {
        if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.14, blue: 0.15),
                        Color(red: 0.17, green: 0.33, blue: 0.31),
                        Color(red: 0.34, green: 0.62, blue: 0.71)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.brandGreen.opacity(0.25))
                    .frame(width: 180, height: 180)
                    .blur(radius: 18)
                    .offset(x: 80, y: 50)

                Circle()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 220, height: 220)
                    .blur(radius: 18)
                    .offset(y: 80)

                VStack(spacing: 18) {
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 84, weight: .regular))
                        .foregroundStyle(.white.opacity(0.88))

                    Text("No ingredient photo saved yet")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.84))
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .tracking(1.6)
            .foregroundStyle(Color.secondary.opacity(0.72))
    }

    private func expiryTitle(for days: Int) -> String {
        switch days {
        case 3:
            return "3 Days"
        case 5:
            return "5 Days"
        case 7:
            return "1 Week"
        default:
            return "Custom"
        }
    }

    private func expiryPalette(for days: Int) -> (background: Color, foreground: Color, stroke: Color) {
        switch days {
        case 3:
            return (
                Color.statusCrimson.opacity(0.08),
                Color.statusCrimson,
                Color.statusCrimson.opacity(0.55)
            )
        case 5:
            return (
                Color.statusAmber.opacity(0.16),
                Color(red: 0.56, green: 0.42, blue: 0.04),
                Color(red: 0.98, green: 0.73, blue: 0.06)
            )
        case 7:
            return (
                Color.statusEmerald.opacity(0.10),
                Color.statusEmerald,
                Color.statusEmerald.opacity(0.55)
            )
        default:
            return (
                Color.secondary.opacity(0.12),
                Color.secondary,
                Color.secondary.opacity(0.35)
            )
        }
    }

    private func saveItem() {
        let viewModel = ItemEntryViewModel(modelContext: modelContext)

        let didSave = viewModel.updateItem(
            item,
            name: nameText,
            valueText: valueText,
            amountText: amountText,
            unit: selectedUnit,
            expiryDate: expiryDate,
            imageData: selectedImageData
        )

        if didSave {
            dismiss()
        } else {
            saveFeedbackMessage = "Please enter valid value and amount."
        }
    }

    private func deleteItem() {
        let viewModel = ItemEntryViewModel(modelContext: modelContext)
        let didDelete = viewModel.deleteItem(item)

        if didDelete {
            dismiss()
        } else {
            saveFeedbackMessage = "Couldn't delete this ingredient right now."
        }
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhotoItem else { return }

        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self) {
                guard let resizedData = resizedImageData(from: data) else {
                    await MainActor.run {
                        saveFeedbackMessage = "Photo could not be loaded."
                    }
                    return
                }

                await MainActor.run {
                    selectedImageData = resizedData
                    saveFeedbackMessage = nil
                }
            }
        } catch {
            await MainActor.run {
                saveFeedbackMessage = "Photo could not be loaded."
            }
        }
    }

    private static func decimalText(for value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        return formatter.string(from: value as NSNumber) ?? "\(value)"
    }

    private static func initialUnit(from unit: String) -> String {
        ItemEntryViewModel.supportedUnits.contains(unit) ? unit : "pcs"
    }

    private func resizedImageData(from data: Data, maxDimension: CGFloat = 1400) -> Data? {
        guard let image = UIImage(data: data) else {
            return nil
        }

        let originalSize = image.size
        let longestSide = max(originalSize.width, originalSize.height)
        let scale = min(1, maxDimension / longestSide)
        let targetSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let renderedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return renderedImage.jpegData(compressionQuality: 0.85)
    }
}

#Preview {
    EditItemView(item: PreviewHelper.sampleFoodItems[2])
        .modelContainer(PreviewHelper.previewContainer)
}
