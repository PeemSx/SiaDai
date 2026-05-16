import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var nameText: String = ""
    @State private var valueText: String = ""
    @State private var amountText: String = ""
    @State private var selectedUnit: String = "g"
    @State private var selectedExpiryDays: Int = 5
    @State private var isCustomExpiry: Bool = false
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var classificationResult: IngredientClassification?
    @State private var classificationMessage: String?
    @State private var isClassifyingPhoto = false
    @State private var saveFeedbackMessage: String?
    @State private var showsSuccessFeedback = false

    private let unitOptions = ["g", "kg", "ml", "L", "pcs", "pack"]
    private let expiryOptions = [3, 5, 7, 0]

    private var canSave: Bool {
        Double(valueText.replacingOccurrences(of: ",", with: ".")) != nil &&
        Double(amountText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    // MARK: - Main UI Layout
    var body: some View {
        ZStack {
            // สีกราวด์พื้นหลังแอปเต็มจอ
            Color.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // แถบบาร์โลโก้ด้านบนสุด
                TopBrandBar()

                // ส่วนฟอร์มหลักแบบเลื่อนขึ้นลงได้
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        heroSection // ส่วนโชว์รูปและปุ่มกล้องด้านบน
                        formSection // ส่วนกรอกข้อมูลวัตถุดิบด้านล่าง
                    }
                    // ดันระยะขอบรอบๆ (ขอบล่างเผื่อระยะหลบ Tab Bar)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 180)
                }
            }
        }
        .task(id: selectedPhotoItem) {
            await loadSelectedPhoto()
        }
    }

    // MARK: - Hero Header Section (รูปพรีวิว + ปุ่มเลือกรูป)
    private var heroSection: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                // ดึงรูปที่เลือกมาโชว์ (ถ้าไม่มีจะโชว์กราเดียนต์ใบไม้แทน)
                heroImage(size: proxy.size)

                // เลเยอร์เงาดำจางๆ บังขอบบน-ล่างให้เห็นปุ่มชัดขึ้น
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

                // ปุ่ม PhotosPicker กดเปิดอัลบั้มภาพเครื่องลอยอยู่มุมขวาบน
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

    // MARK: - Form Inputs Section (กล่องกรอกข้อมูลทั้งหมด)
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // ส่วนหัวฟอร์ม + ช่องกรอกชื่อวัตถุดิบ
            VStack(alignment: .leading, spacing: 8) {
                Text("SiaDai")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.brandGreen)

                Text("Add New Item")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)

                nameField // ช่องพิมพ์ชื่อวัตถุดิบหลัก

                // ดักเช็คสถานะโหลดรูปหรือวิเคราะห์รูปจาก AI -> โชว์ชิปแจ้งสถานะ/ตัวเลือกแนะนำ
                if isClassifyingPhoto || classificationResult != nil || classificationMessage != nil {
                    classificationStatusView
                }
            }

            // ช่องกรอกราคาสินค้า (บาท)
            VStack(alignment: .leading, spacing: 12) {
                fieldLabel("VALUE (฿)")
                moneyField
            }

            // ช่องกรอกปริมาณ + เมนูกดเลือกหน่วยวัด (g, kg, ชิ้น ฯลฯ)
            VStack(alignment: .leading, spacing: 12) {
                fieldLabel("AMOUNT")
                amountRow
            }

            // โซนเลือกวันหมดอายุ (ปุ่มลัด 3 วัน, 5 วัน, 1 สัปดาห์, Custom)
            VStack(alignment: .leading, spacing: 14) {
                fieldLabel("EXPIRES IN:")
                expiryRow
                
                // ถ้าผู้ใช้กดเลือกแบบกำหนดเอง (Custom) -> คลี่ตัวเลือกปฏิทินกราฟิกออกมา
                if isCustomExpiry {
                    DatePicker(
                        "Custom Expiry Date",
                        selection: $expiryDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.brandGreen)
                    .padding(16)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }

            // ตัวหนังสือแจ้งเตือนเอเรอร์เวลากรอกข้อมูลไม่ครบ (Validation)
            if let saveFeedbackMessage {
                Text(saveFeedbackMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(showsSuccessFeedback ? Color.brandGreen : Color.statusCrimson)
            }

            // ปุ่มกดเซฟลงคลัง (ห้ามกดถ้า Validation ดักแล้วไม่ผ่าน)
            Button {
                saveItem()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.badge.plus")
                        .font(.system(size: 24, weight: .semibold))

                    Text("Save to Watchlist")
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
        .padding(.bottom, 28)
    }

    // MARK: - Input Field Subviews (ดีไซน์ย่อยของแต่ละช่องกรอก)

    // ช่องกรอกชื่อสินค้าชิ้นใหญ่
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

    // ช่องกรอกราคา มีสัญลักษณ์สัญลักษณ์เงิน ฿ นำหน้า
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

    // แถวป้อนตัวเลขปริมาณคู่กับเมนูกดเลือกหน่วย (Menu Dropdown)
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

    // แถวเรียงปุ่มลัดวันหมดอายุ (3 ตัวเลือกพิล + 1 ปุ่มปฏิทินเอง)
    private var expiryRow: some View {
        HStack(spacing: 12) {
            ForEach(expiryOptions, id: \.self) { days in
                expiryOption(days: days)
            }
        }
    }

    // ดีไซน์การ์ดตัวเลือกวันหมดอายุย่อยๆ (สลับสีกราวด์/เส้นขอบตามกลุ่มความเร่งด่วน)
    private func expiryOption(days: Int) -> some View {
        let isSelected = selectedExpiryDays == days
        let palette = expiryPalette(for: days)

        return Button {
            selectedExpiryDays = days
            if days == 0 {
                isCustomExpiry = true
                expiryDate = .now
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

    // ส่วนประมวลผลสลับรูปพื้นหลังด้านบนสุด (แสดงรูปจริง / โชว์ใบไม้ใบใหญ่ตอนไม่มีภาพ)
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

                    Text("Add a photo to preview the ingredient here")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.84))
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }

    // MARK: - AI Image Classification UI (พาร์ทแสดงสถานะสแกนวัตถุดิบจากรูป)
    @ViewBuilder
    private var classificationStatusView: some View {
        if isClassifyingPhoto {
            // สเตตัส 1: กำลังสแกนวิเคราะห์รูปภาพ
            classificationChip(
                icon: "sparkles.rectangle.stack.fill",
                message: "Analyzing the ingredient photo...",
                tint: Color.secondary
            )
        } else if let classificationResult {
            // สเตตัส 2: สแกนเสร็จแล้ว -> ลิสต์รายชื่อวัตถุดิบที่ AI แนะนำออกมาเป็นชุดปุ่มกด
            VStack(alignment: .leading, spacing: 12) {
                classificationChip(
                    icon: "sparkles.rectangle.stack.fill",
                    message: "Pick the correct ingredient from the top matches below.",
                    tint: Color.brandGreen
                )

                VStack(spacing: 10) {
                    ForEach(classificationResult.predictions) { prediction in
                        predictionButton(for: prediction)
                    }
                }
            }
        } else if let classificationMessage {
            // สเตตัส 3: เกิดข้อผิดพลาด/สแกนไม่สำเร็จ -> โชว์กล่องเตือนสีส้ม
            classificationChip(
                icon: "exclamationmark.triangle.fill",
                message: classificationMessage,
                tint: Color.statusAmber
            )
        }
    }

    // ดีไซน์กล่องชิปข้อความแจ้งเตือนสถานะสแกนภาพย่อยๆ
    private func classificationChip(icon: String, message: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))

            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(tint.opacity(0.10), in: Capsule())
    }

    // แถวปุ่มรายชื่อวัตถุดิบที่ได้จาก AI (ไฮไลต์สีกรีนเข้มเมื่อชื่อตรงกับที่เลือก)
    private func predictionButton(for prediction: IngredientPrediction) -> some View {
        let isSelected =
            nameText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(prediction.displayName) == .orderedSame

        return Button {
            nameText = prediction.displayName
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.displayName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? .white : .black)

                    Text("\(predictionConfidenceText(for: prediction)) match")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? .white.opacity(0.84) : Color.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Color.brandGreen)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Color.brandGreen : Color(red: 0.95, green: 0.95, blue: 0.95),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    // ดีไซน์ตัวหนังสือป้ายกำกับฟิลด์ (หัวข้อจิ๋วๆ สีเทาจางๆ ตัวหนา)
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

        let didSave = viewModel.saveItem(
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
            showsSuccessFeedback = false
            saveFeedbackMessage = "Please enter valid value and amount."
        }
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhotoItem else { return }

        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self) {
                guard let resizedData = resizedImageData(from: data) else {
                    await MainActor.run {
                        isClassifyingPhoto = false
                        classificationResult = nil
                        classificationMessage = nil
                        showsSuccessFeedback = false
                        saveFeedbackMessage = "Photo could not be loaded."
                    }
                    return
                }

                await MainActor.run {
                    selectedImageData = resizedData
                    classificationResult = nil
                    classificationMessage = nil
                    isClassifyingPhoto = true
                    showsSuccessFeedback = false
                    saveFeedbackMessage = nil
                }

                do {
                    let classification = try await Task.detached(priority: .userInitiated) {
                        try IngredientImageClassifier.classify(imageData: resizedData)
                    }.value

                    await MainActor.run {
                        applyClassification(classification)
                    }
                } catch {
                    await MainActor.run {
                        isClassifyingPhoto = false
                        classificationResult = nil
                        classificationMessage = "Couldn't identify the ingredient from this photo."
                    }
                }
            }
        } catch {
            await MainActor.run {
                isClassifyingPhoto = false
                classificationResult = nil
                classificationMessage = nil
                showsSuccessFeedback = false
                saveFeedbackMessage = "Photo could not be loaded."
            }
        }
    }

    private func applyClassification(_ classification: IngredientClassification) {
        classificationResult = classification
        classificationMessage = nil
        isClassifyingPhoto = false
    }

    private func predictionConfidenceText(for prediction: IngredientPrediction) -> String {
        let percentage = Int((prediction.confidence * 100).rounded())
        let clampedPercentage = min(100, max(0, percentage))
        return "\(clampedPercentage)%"
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
    AddItemView()
        .modelContainer(PreviewHelper.previewContainer)
}
