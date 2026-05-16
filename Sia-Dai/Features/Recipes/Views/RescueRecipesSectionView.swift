import SwiftUI

struct RescueRecipesSectionView: View {
    let recipes: [RescueRecipe]
    let sourceItems: [FoodItem]
    let isLoading: Bool
    let statusState: RescueRecipesStatusState
    let statusTitle: String
    let statusMessage: String
    let recommendation: String?
    let showsHeaderAction: Bool
    let headerActionTitle: String
    let showsStatusAction: Bool
    let statusActionTitle: String
    let onGenerateRecipes: () -> Void
    let onMarkRecipeAsMade: (RescueRecipe) -> RecipeInventoryApplicationResult

    // MARK: - Main Section Layout
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // หัวข้อเซกชันใหญ่ดักอยู่ข้างบนสุด
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rescue Recipes")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)

                    Text("Cook from your watchlist before ingredients turn into waste.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                // ถ้าเงื่อนไขผ่าน -> โชว์ปุ่มกลมๆ ขวาบนสำหรับกดสั่งสุ่มคิดเมนูใหม่
                if showsHeaderAction {
                    Button(action: onGenerateRecipes) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12, weight: .bold))

                            Text(headerActionTitle)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(isLoading ? Color.secondary : Color.brandGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading) // ล็อกปุ่มไว้ห้ามกดซ้ำตอนโหลด
                }
            }

            // พาร์ทสลับสถานะหน้าบ้านตามการดึงข้อมูลหลังบ้าน
            if isLoading {
                // ร่างที่ 1: กำลังประมวลผล -> โชว์การ์ดกล่องหมุนๆ รอแป๊บหนึ่ง
                loadingCard
            } else if recipes.isEmpty {
                // ร่างที่ 2: ไม่มีรายการเมนู -> ดึงการ์ดแจ้งสถานะว่างเปล่าขึ้นมาแทน
                statusCard
            } else {
                // ร่างที่ 3: มีสูตรอาหารพร้อม -> สาดแถบ Scroll แนวนอนโชว์ลิสต์การ์ดอาหารกู้ชีพทั้งหมด
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(recipes) { recipe in
                            NavigationLink {
                                // กดแล้วลิ้งก์วาร์ปเปิดเข้าไปที่หน้าดูดีเทลวิธีทำข้างใน
                                RescueRecipeDetailView(
                                    recipe: recipe,
                                    sourceItems: sourceItems,
                                    onMarkRecipeAsMade: onMarkRecipeAsMade
                                )
                            } label: {
                                // โครงหน้าตาตัวการ์ดสี่เหลี่ยมมนแนวนอนแต่ละใบ
                                RecipeCardView(
                                    recipe: recipe,
                                    sourceItems: sourceItems
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .contentMargins(.horizontal, 0, for: .scrollContent)
            }
        }
    }

    // MARK: - Loading View (การ์ดตอนกำลังหมุนเจนสูตรอาหาร)
    private var loadingCard: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 196)
            .overlay {
                VStack(spacing: 14) {
                    ProgressView() // ตัวโหลดหมุนๆ วงกลมมาตรฐาน
                        .tint(Color.brandGreen)

                    Text("Generating recipes from your tracked ingredients...")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .shadow(color: .cardShadow, radius: 14, x: 0, y: 10)
    }

    // MARK: - Status / Empty Card View (การ์ดกรณีพิเศษ เช่น ไม่มีสูตร หรือระบบเอเรอร์)
    private var statusCard: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 236)
            .overlay {
                // จัด UI แสดงไอคอน, หัวข้อ, คำอธิบาย แตกต่างกันไปตาม Enum สเตตัสเบื้องหลัง
                VStack(spacing: 12) {
                    Image(systemName: statusIconName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(statusIconColor)

                    Text(statusTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)

                    Text(statusMessage)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // กล่องข้อความทิปแนะนำเพิ่มเติม (แสดงเฉพาะบางเคสที่มีคำโปรยส่งมา)
                    if let recommendation {
                        Text(recommendation)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.70))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // ปุ่มสั่งกดเริ่มใหม่อีกรอบใต้การ์ดแจ้งเตือน
                    if showsStatusAction {
                        Button(action: onGenerateRecipes) {
                            Text(statusActionTitle)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(Color.brandGreen, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 28)
            }
            .shadow(color: .cardShadow, radius: 14, x: 0, y: 10)
    }

    private var statusIconName: String {
        switch statusState {
        case .needsIngredients: return "basket.fill"
        case .idle: return "fork.knife.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }

    private var statusIconColor: Color {
        switch statusState {
        case .needsIngredients, .idle: return Color.brandGreen
        case .failure: return Color.statusAmber
        }
    }
}

// MARK: - Recipe Individual Card View (โครงสร้างหน้าตาการ์ดเมนูย่อยแต่ละใบ)
private struct RecipeCardView: View {
    let recipe: RescueRecipe
    let sourceItems: [FoodItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                RecipeArtworkView(recipe: recipe, sourceItems: sourceItems) // ดึงภาพพรีวิวจากโมดูลสีคู่ตรงข้ามของเพื่อนมาแปะ

                // แท็กแคปซูลสีขาวโปร่งแสง แปะบอกเวลาทำอาหาร ลอยเด่นอยู่มุมซ้ายบนของตัวรูปภาพ
                Text(recipe.timeBadgeTitle)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(.black.opacity(0.76))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.92), in: Capsule())
                    .padding(14)
            }
            .frame(width: 272, height: 306)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            // พาร์ทชื่อเมนูอาหารคู่กับคำโปรยวัตถุดิบข้างใต้การ์ด
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(2) // ล็อกความสูงฟอนต์ไว้ไม่ให้เกินสองบรรทัด ป้องกันเลย์เอาต์การ์ดเบี้ยว

                Text(recipe.ingredientSummary)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // แท็กป้ายไฟสีเขียวจิ๋ว การันตีว่าดึงของที่มีอยู่ในคลังตู้เย็นไปใช้จริง
            Text("Inventory Match")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.brandGreen)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(Color.brandGreen.opacity(0.10), in: Capsule())
        }
        .frame(width: 272, alignment: .leading)
        .padding(18)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: .cardShadow, radius: 16, x: 0, y: 12)
    }
}
