import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    // 通知設定
    @State private var pushNotifications = true
    
    // 制限アラート管理
    @State private var showingPremiumPurchase = false
    @State private var showingProfileEdit = false
    
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
            .sheet(isPresented: $showingProfileEdit) {
                UserProfileEditView(viewModel: viewModel)
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
        Section {
            if let user = viewModel.currentUser {
                HStack {
                    if let imageData = user.customProfileImageData,
                       let customImage = UIImage(data: imageData) {
                        Image(uiImage: customImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: user.profileImage ?? "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.headline)
                        
                        if let bio = user.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        if let goal = user.goal, !goal.isEmpty {
                            Text("🎯 \(goal)")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Button("編集") {
                        showingProfileEdit = true
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        } header: {
            Text("ユーザー情報")
        }
    }
    
    private var notificationSection: some View {
        Section {
            Toggle("プッシュ通知", isOn: $pushNotifications)
                .onChange(of: pushNotifications) { newValue in
                    // 通知の許可状態を更新
                    if newValue {
                        requestNotificationPermission()
                    }
                }
        } header: {
            Text("通知設定")
        } footer: {
            Text("プッシュ通知をオンにすると、部屋への招待や友達の活動をお知らせします。")
        }
    }
    
    private var dataSection: some View {
        Section {
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
        } header: {
            Text("統計サマリー")
        }
    }
    
    private var appInfoSection: some View {
        Group {
            Section {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("アプリ情報")
            }
            
            Section {
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
            } header: {
                Text("サポート")
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
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.pushNotifications = true
                } else {
                    self.pushNotifications = false
                }
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: AppViewModel())
} 