import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    // 通知設定
    @State private var pushNotifications = true
    @State private var friendActivity = true
    @State private var roomInvites = true
    @State private var achievements = true
    @State private var quietHours = false
    @State private var quietStartTime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @State private var quietEndTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    
    @State private var showingPremiumPurchase = false
    
    var body: some View {
        NavigationView {
            Form {
                // プレミアム版セクション
                premiumSection
                
                // アカウント設定セクション
                accountSection
                
                // 通知設定セクション
                notificationSection
                
                // データ管理セクション
                dataSection
                
                // アプリ情報セクション
                appInfoSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPremiumPurchase) {
                PremiumPurchaseView(premiumManager: viewModel.premiumManager)
            }
        }
    }
    
    // MARK: - プレミアム版セクション
    private var premiumSection: some View {
        Section {
            HStack {
                Image(systemName: viewModel.premiumManager.isPremium ? "crown.fill" : "crown")
                    .foregroundColor(viewModel.premiumManager.isPremium ? .yellow : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.premiumManager.isPremium ? "プレミアム版" : "無料版")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(viewModel.premiumManager.isPremium ? "すべての機能を制限なく利用中" : "プレミアム版にアップグレード")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !viewModel.premiumManager.isPremium {
                    Button("アップグレード") {
                        showingPremiumPurchase = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.vertical, 4)
            
            if !viewModel.premiumManager.isPremium {
                NavigationLink(destination: UsageStatusView(
                    featureLimiter: viewModel.featureLimiter,
                    premiumManager: viewModel.premiumManager
                )) {
                    Label("使用状況を確認", systemImage: "chart.bar")
                }
            }
        } header: {
            Text("プレミアム版")
        } footer: {
            if !viewModel.premiumManager.isPremium {
                Text("プレミアム版にアップグレードすると、部屋作成数（月間5部屋）や友達数の制限が解除されます。")
            }
        }
    }
    
    private var accountSection: some View {
        Section("ユーザー情報") {
            if let user = viewModel.currentUser {
                HStack {
                    Image(systemName: user.profileImage ?? "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.headline)
                        Text("ユーザーID: \(user.id.uuidString.prefix(8))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var notificationSection: some View {
        Section("通知設定") {
            Toggle("プッシュ通知", isOn: $pushNotifications)
            Toggle("友達の活動", isOn: $friendActivity)
            Toggle("部屋への招待", isOn: $roomInvites)
            Toggle("達成通知", isOn: $achievements)
            
            Toggle("静寂時間を設定", isOn: $quietHours)
            
            if quietHours {
                HStack {
                    Text("開始時間")
                    Spacer()
                    DatePicker("", selection: $quietStartTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                HStack {
                    Text("終了時間")
                    Spacer()
                    DatePicker("", selection: $quietEndTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
    }
    
    private var dataSection: some View {
        Section("統計サマリー") {
            HStack {
                Image(systemName: "house.fill")
                    .foregroundColor(.blue)
                Text("作成した部屋")
                Spacer()
                Text("\(viewModel.rooms.count)件")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.green)
                Text("総努力時間")
                Spacer()
                Text(getTotalEffortTime())
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(.orange)
                Text("努力セッション")
                Spacer()
                Text("\(viewModel.effortRecords.count)回")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var appInfoSection: some View {
        Group {
            Section("アプリ情報") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("ビルド")
                    Spacer()
                    Text("1")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("開発者情報") {
                HStack {
                    Text("開発者")
                    Spacer()
                    Text("渡邊光")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("作成日")
                    Spacer()
                    Text("2025年8月")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("サポート") {
                Button(action: {
                    // プライバシーポリシーを表示
                }) {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(.blue)
                        Text("プライバシーポリシー")
                    }
                }
                
                Button(action: {
                    // 利用規約を表示
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text("利用規約")
                    }
                }
                
                Button(action: {
                    // お問い合わせ
                }) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                        Text("お問い合わせ")
                    }
                }
            }
        }
    }
    
    private func getTotalEffortTime() -> String {
        let total = viewModel.effortRecords.reduce(0) { $0 + $1.duration }
        let hours = Int(total) / 3600
        let minutes = Int(total) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

#Preview {
    SettingsView(viewModel: AppViewModel())
} 