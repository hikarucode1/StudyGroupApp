import SwiftUI

// MARK: - 使用状況表示ビュー
struct UsageStatusView: View {
    @ObservedObject var featureLimiter: FeatureLimiter
    @ObservedObject var premiumManager: PremiumManager
    
    var body: some View {
        VStack(spacing: 16) {
            // プレミアム状態表示
            premiumStatusSection
            
            // タイトル
            Text("使用状況")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 部屋作成数
            UsageProgressRow(
                title: "部屋作成",
                current: featureLimiter.monthlyRoomCount,
                limit: FeatureLimits.freeRoomCreationLimit,
                icon: "house.fill",
                color: .blue,
                isPremium: premiumManager.isPremium
            )
            
            // 友達数
            UsageProgressRow(
                title: "友達数",
                current: featureLimiter.currentFriendCount,
                limit: FeatureLimits.freeFriendLimit,
                icon: "person.2.fill",
                color: .green,
                isPremium: premiumManager.isPremium
            )
            
            // プレミアム版の特典
            if !premiumManager.isPremium {
                premiumBenefitsSection
            }
        }
        .padding()
    }
    
    // MARK: - プレミアム状態セクション
    private var premiumStatusSection: some View {
        HStack {
            Image(systemName: premiumManager.isPremium ? "crown.fill" : "crown")
                .font(.title2)
                .foregroundColor(premiumManager.isPremium ? .yellow : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(premiumManager.isPremium ? "プレミアム版" : "無料版")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(premiumManager.isPremium ? "すべての機能を制限なく利用中" : "一部機能に制限があります")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(premiumManager.isPremium ? Color.yellow.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - プレミアム特典セクション
    private var premiumBenefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プレミアム版の特典")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                PremiumFeatureRow(icon: "infinity", text: "部屋作成無制限")
                PremiumFeatureRow(icon: "person.3", text: "友達数無制限")
                PremiumFeatureRow(icon: "chart.bar.fill", text: "高度な統計・分析")
                PremiumFeatureRow(icon: "photo", text: "画像・ファイル送信")
                PremiumFeatureRow(icon: "paintbrush", text: "カスタマイズ機能")
                PremiumFeatureRow(icon: "gift", text: "1ヶ月無料トライアル")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 使用状況進行バー行
struct UsageProgressRow: View {
    let title: String
    let current: Int
    let limit: Int
    let icon: String
    let color: Color
    let isPremium: Bool
    
    private var progress: Double {
        if isPremium {
            return 0.0 // プレミアム版は制限なし
        }
        return Double(current) / Double(limit)
    }
    
    private var isNearLimit: Bool {
        !isPremium && progress >= 0.8
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.body)
                    
                    if isPremium {
                        Image(systemName: "infinity")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                if isPremium {
                    Text("制限なし")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .fontWeight(.medium)
                } else {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: isNearLimit ? .orange : color))
                        .frame(height: 4)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if isPremium {
                    Text("無制限")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.yellow)
                } else {
                    Text("\(current)/\(limit)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if isNearLimit {
                        Text("制限に近い")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - プレミアム機能行
struct PremiumFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.yellow)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

#Preview {
    UsageStatusView(featureLimiter: FeatureLimiter(), premiumManager: PremiumManager())
} 