import SwiftUI
import MessageUI

struct ContactView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingMailComposer = false
    @State private var showingAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // ヘッダー
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("お問い合わせ")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("ご質問、ご意見、バグの報告など、お気軽にお問い合わせください。")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // お問い合わせ方法
                    VStack(spacing: 20) {
                        Text("お問い合わせ方法")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // メールでのお問い合わせ
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                Text("メールでのお問い合わせ")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            Text("アプリに関するご質問やご意見をメールでお送りください。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                if MFMailComposeViewController.canSendMail() {
                                    showingMailComposer = true
                                } else {
                                    showingAlert = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "envelope")
                                    Text("メールを送信")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // よくある質問
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("よくある質問")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            Text("よくある質問と回答をご確認ください。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Q: 部屋の作成数に制限はありますか？")
                                Text("A: 無料版では月5部屋まで作成できます。")
                                
                                Text("Q: データはどこに保存されますか？")
                                Text("A: すべてのデータはデバイス内に保存されます。")
                                
                                Text("Q: 友達機能はどのように使いますか？")
                                Text("A: 設定画面から友達リクエストを送信できます。")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // アプリ情報
                    VStack(spacing: 12) {
                        Text("アプリ情報")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("アプリ名")
                                Spacer()
                                Text("StudyGroupApp")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("バージョン")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("最終更新")
                                Spacer()
                                Text("2025年8月")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("お問い合わせ")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("閉じる") {
                    dismiss()
                }
            )
            .sheet(isPresented: $showingMailComposer) {
                MailComposeView(
                    subject: "StudyGroupApp お問い合わせ",
                    body: """
                    お問い合わせ内容：
                    
                    
                    
                    --------------------
                    アプリ名: StudyGroupApp
                    バージョン: 1.0.0
                    デバイス: \(UIDevice.current.model)
                    OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
                    """
                )
            }
            .alert("メールが利用できません", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text("このデバイスではメールが利用できません。メールアプリをご確認ください。")
            }
        }
    }
}

// メール作成画面
struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        composer.setToRecipients(["tk230238@tks.iput.ac.jp"])
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContactView()
} 