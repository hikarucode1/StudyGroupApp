import SwiftUI

// MARK: - 制限アラートビュー
struct LimitAlertView: View {
    let feature: String
    let currentLimit: Int
    let limitType: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // アイコン
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            // タイトル
            Text("機能制限に達しました")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // 説明
            VStack(spacing: 8) {
                Text("\(feature)の\(limitType)制限（\(currentLimit)）に達しました。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                Text("プレミアム版にアップグレードすると、この機能を無制限に使用できます。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // プレミアム版の特典
            VStack(alignment: .leading, spacing: 8) {
                Text("プレミアム版の特典:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    FeatureRow(icon: "infinity", text: "部屋作成無制限")
                    FeatureRow(icon: "person.3", text: "友達数無制限")
                    FeatureRow(icon: "chart.bar.fill", text: "高度な統計・分析")
                    FeatureRow(icon: "photo", text: "画像・ファイル送信")
                    FeatureRow(icon: "paintbrush", text: "カスタマイズ機能")
                    FeatureRow(icon: "gift", text: "1ヶ月無料トライアル")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // ボタン
            VStack(spacing: 12) {
                Button("プレミアム版にアップグレード") {
                    // プレミアム購入画面を表示
                    onDismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .cornerRadius(12)
                
                Button("後で") {
                    onDismiss()
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// MARK: - 機能行
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

#Preview {
    LimitAlertView(
        feature: "部屋作成",
        currentLimit: 3,
        limitType: "月間",
        onDismiss: {}
    )
} 