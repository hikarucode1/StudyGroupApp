import SwiftUI
import StoreKit

// MARK: - プレミアム購入画面
struct PremiumPurchaseView: View {
    @ObservedObject var premiumManager: PremiumManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    headerSection
                    
                    // プレミアム版の特典
                    benefitsSection
                    
                    // 商品選択
                    productsSection
                    
                    // 購入ボタン
                    purchaseSection
                    
                    // 注意事項
                    disclaimerSection
                }
                .padding()
            }
            .navigationTitle("プレミアム版")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: .constant(premiumManager.errorMessage != nil)) {
                Button("OK") {
                    premiumManager.errorMessage = nil
                }
            } message: {
                if let errorMessage = premiumManager.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - ヘッダーセクション
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("プレミアム版にアップグレード")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("制限なく、すべての機能を楽しもう！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - 特典セクション
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("プレミアム版の特典")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                BenefitRow(icon: "infinity", title: "部屋作成無制限", description: "月間制限なしで部屋を作成")
                BenefitRow(icon: "person.3", title: "友達数無制限", description: "制限なく友達を追加")
                BenefitRow(icon: "chart.bar.fill", title: "高度な統計・分析", description: "詳細な努力記録と分析")
                BenefitRow(icon: "photo", title: "画像・ファイル送信", description: "チャットで画像やファイルを共有")
                BenefitRow(icon: "paintbrush", title: "カスタマイズ機能", description: "テーマや通知音をカスタマイズ")
                BenefitRow(icon: "gift", title: "1ヶ月無料トライアル", description: "最初の1ヶ月は無料でお試し")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - 商品セクション
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("プランを選択")
                .font(.headline)
                .fontWeight(.semibold)
            
            if premiumManager.isLoading {
                ProgressView("商品を読み込み中...")
                    .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(premiumManager.products) { product in
                        ProductCard(product: product, premiumManager: premiumManager)
                    }
                }
            }
        }
    }
    
    // MARK: - 購入セクション
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            Button("購入を復元") {
                Task {
                    await premiumManager.restorePurchases()
                }
            }
            .font(.body)
            .foregroundColor(.blue)
            
            Text("購入を復元すると、以前に購入したプレミアム版を復元できます。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - 注意事項セクション
    private var disclaimerSection: some View {
        VStack(spacing: 8) {
            Text("注意事項")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("• サブスクリプションは自動更新されます\n• 更新の24時間前までにキャンセルしない限り、期間終了時に自動更新されます\n• 購入後、App Storeのアカウント設定でサブスクリプションを管理できます")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 特典行
struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 商品カード
struct ProductCard: View {
    let product: PremiumProduct
    @ObservedObject var premiumManager: PremiumManager
    
    var body: some View {
        Button {
            Task {
                await premiumManager.purchase(product)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if product.isPopular {
                            Text("人気")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.formattedPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text(product.subscriptionPeriod)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(premiumManager.isLoading)
    }
}

#Preview {
    PremiumPurchaseView(premiumManager: PremiumManager())
} 