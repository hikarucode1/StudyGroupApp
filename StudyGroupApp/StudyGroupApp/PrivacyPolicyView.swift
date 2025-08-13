import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("プライバシーポリシー")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("最終更新日: 2025年8月")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("StudyGroupApp（以下「本アプリ」）は、ユーザーの個人情報の保護を最重要事項と考えています。本プライバシーポリシーは、本アプリにおける個人情報の収集、使用、管理について説明します。")
                        
                        Text("1. 収集する情報")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("本アプリでは、以下の情報を収集する場合があります：")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• ユーザー名")
                            Text("• プロフィール画像")
                            Text("• 部屋の参加・作成履歴")
                            Text("• 努力時間の記録")
                            Text("• 友達関係の情報")
                        }
                        .padding(.leading)
                        
                        Text("2. 情報の使用目的")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("収集した情報は、以下の目的でのみ使用されます：")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• アプリの基本機能の提供")
                            Text("• ユーザー間のコミュニケーション支援")
                            Text("• 努力時間の記録・統計表示")
                            Text("• アプリの改善・開発")
                        }
                        .padding(.leading)
                        
                        Text("3. 情報の共有")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("本アプリは、以下の場合を除き、ユーザーの個人情報を第三者に提供することはありません：")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• ユーザーの明示的な同意がある場合")
                            Text("• 法令に基づく要求がある場合")
                            Text("• ユーザーの安全や権利を保護する必要がある場合")
                        }
                        .padding(.leading)
                        
                        Text("4. データの保存")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("ユーザーのデータは、デバイス内のローカルストレージに保存されます。本アプリは、ユーザーのデータを外部サーバーに送信することはありません。")
                        
                        Text("5. お問い合わせ")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("プライバシーポリシーに関するご質問やご意見がございましたら、設定画面の「お問い合わせ」からお気軽にお問い合わせください。")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("プライバシーポリシー")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("閉じる") {
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    PrivacyPolicyView()
} 