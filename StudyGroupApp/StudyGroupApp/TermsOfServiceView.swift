import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("利用規約")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("最終更新日: 2025年8月")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("StudyGroupApp（以下「本アプリ」）をご利用いただく際は、以下の利用規約（以下「本規約」）に従っていただく必要があります。本アプリの利用により、本規約に同意したものとみなされます。")
                        
                        Text("1. 利用登録")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("本アプリの利用にあたり、ユーザーは以下の事項を遵守するものとします：")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 真実かつ正確な情報を提供すること")
                            Text("• 他人の権利を侵害しないこと")
                            Text("• 法令や公序良俗に反する行為を行わないこと")
                        }
                        .padding(.leading)
                        
                        Text("2. 禁止事項")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("ユーザーは、本アプリの利用にあたり、以下の行為を行ってはなりません：")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 他のユーザーに対する誹謗中傷")
                            Text("• 不適切なコンテンツの投稿")
                            Text("• スパムや迷惑行為")
                            Text("• アプリの正常な動作を妨害する行為")
                            Text("• 他のユーザーの個人情報を無断で収集・公開する行為")
                        }
                        .padding(.leading)
                        
                        Text("3. コンテンツの責任")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("ユーザーが投稿・共有するコンテンツ（部屋名、メッセージ、プロフィール情報等）について、その責任は投稿者に帰属します。本アプリは、ユーザーが投稿したコンテンツの内容について責任を負いません。")
                        
                        Text("4. サービスの変更・停止")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("本アプリは、事前の通知なく、サービスの内容を変更し、または提供を停止することができるものとします。本アプリは、これによってユーザーまたは第三者に生じた損害について、一切の責任を負いません。")
                        
                        Text("5. 免責事項")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("本アプリは、ユーザー間のコミュニケーションや努力時間の記録を支援することを目的としていますが、その効果や結果について保証するものではありません。")
                        
                        Text("6. 規約の変更")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("本規約は、必要に応じて変更される場合があります。変更後の規約は、本アプリ内で公表された時点から効力を生じるものとします。")
                        
                        Text("7. 準拠法・管轄裁判所")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("本規約の解釈にあたっては、日本法を準拠法とします。また、本規約に関して紛争が生じた場合の第一審の専属管轄裁判所は、東京地方裁判所とします。")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("利用規約")
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
    TermsOfServiceView()
} 