import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Query(sort: \FoodItem.expiryDate) private var foodItems: [FoodItem]
    @State private var activeSheet: WatchlistSheet?

    // ตั้งค่าตารางกริดเป็นแบบ 2 คอลัมน์ซ้ายขวา ระยะห่าง 16px
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private var activeItems: [FoodItem] {
        foodItems.filter { $0.status == .tracking }
    }
    
    // MARK: - Main UI Layout
    var body: some View {
        ZStack {
            // สีกราวด์พื้นหลังแอปเต็มจอ
            Color.screenBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // แถบบาร์โลโก้แบรนด์ด้านบนสุด
                TopBrandBar()

                // หน้าจอลิสต์ของกินแบบเลื่อนขึ้นลงได้ (ซ่อนแถบสกรอล)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        inventoryHeader // ส่วนหัวเรื่อง Watchlist + ปุ่มบวกเพิ่มของ
                        
                        // เช็คสลับร่างหน้าจอตามปริมาณของที่มี
                        if activeItems.isEmpty {
                            // เคสไม่มีของเลย: โชว์การ์ดตู้เย็นว่างเปล่า (Empty State)
                            emptyState
                        } else {
                            // เคสมีของในคลัง: กางตารางกริดคู่สาดพ่นการ์ดอาหารออกมาเรียงกัน
                            LazyVGrid(columns: columns, spacing: 28) {
                                ForEach(activeItems, id: \.id) { item in
                                    Button {
                                        // กดแล้วจะไปสั่งเปลี่ยนสถานะเพื่อสั่งกางแผ่นชีตแก้ไขข้อมูล
                                        activeSheet = .edit(item)
                                    } label: {
                                        FoodCardView(item: item) // ตัวการ์ดอาหารเดี่ยวๆ
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 6)
                        }
                    }
                    // ดันระยะรอบๆ (ขอบล่างเว้นเยอะหน่อยหลบแท็บสวิตช์หน้าจอ)
                    .padding(.horizontal, 24)
                    .padding(.top, 26)
                    .padding(.bottom, 180)
                }
            }
        }
        // พาร์ทดักเปิดป๊อปอัปแผ่นชีตสไลด์ขึ้นมาจากข้างล่าง (หน้าเพิ่มของใหม่ / หน้าแก้ของเก่า)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                AddItemView()
                    .presentationDragIndicator(.visible) // โชว์ขีดแถบเทาด้านบนเอาไว้ให้ลากปัดนิ้วลงเพื่อปิดได้
            case let .edit(item):
                EditItemView(item: item)
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Header UI (หัวข้อและปุ่มกลมบวกเพิ่มของ)
    private var inventoryHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR INVENTORY")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(Color.brandGreen)

            HStack(alignment: .center, spacing: 12) {
                Text("Watchlist")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 10)

                // ปุ่มวงกลมเครื่องหมายบวกสีขาว ลอยอยู่มุมขวาบน
                Button {
                    activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 52, height: 52)
                        .background(Color.white, in: Circle())
                        .shadow(color: .cardShadow, radius: 12, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Item")
            }
        }
    }

    // MARK: - Empty State UI (ดีไซน์การ์ดแจ้งเตือนตอนคลังว่างเปล่า)
    private var emptyState: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .overlay {
                // จัด UI วางไอคอนตระกร้า, ชื่อเรื่อง, และคำโปรยสีเทาจางๆ สไตล์มินิมอล
                VStack(spacing: 10) {
                    Image(systemName: "basket")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(Color.brandGreen)

                    Text("No active food items")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.black)

                    Text("Add something to start tracking what needs to be used first.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
            }
    }
}

private enum WatchlistSheet: Identifiable {
    case add
    case edit(FoodItem)

    var id: String {
        switch self {
        case .add:
            return "add"
        case let .edit(item):
            return "edit-\(item.id.uuidString)"
        }
    }
}

#Preview {
    WatchlistView()
        .modelContainer(PreviewHelper.previewContainer)
}
