import SwiftUI

struct AddFriendView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedUser: User?
    @State private var message = ""
    @State private var showingUserProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("ユーザーIDまたは名前で検索", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // 検索結果または説明
                if searchText.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        
                        Text("友達を追加")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("ユーザーIDまたは名前で友達を検索して、友達リクエストを送信できます。")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("友達追加の手順:")
                                .font(.headline)
                            
                            Text("1. 検索バーにユーザーIDまたは名前を入力")
                            Text("2. 検索結果から友達にしたい人を選択")
                            Text("3. メッセージを添えて友達リクエストを送信")
                            Text("4. 相手が承認すると友達になります")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top, 40)
                } else {
                    // 検索結果（仮想的な実装）
                    List {
                        ForEach(getSearchResults(), id: \.id) { user in
                            Button(action: {
                                selectedUser = user
                                showingUserProfile = true
                            }) {
                                HStack {
                                    UserAvatar(profileImage: user.profileImage, customProfileImageData: user.customProfileImageData, size: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("ユーザーID: \(user.id.uuidString.prefix(8))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("友達を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingUserProfile) {
                if let user = selectedUser {
                    UserProfileView(user: user, viewModel: viewModel, onSendRequest: {
                        sendFriendRequest(to: user)
                    })
                }
            }
        }
    }
    
    private func getSearchResults() -> [User] {
        // 仮想的な検索結果
        // 実際のアプリでは、サーバーから検索結果を取得
        if searchText.isEmpty { return [] }
        
        return [
            User(name: "\(searchText)さん1"),
            User(name: "\(searchText)さん2"),
            User(name: "\(searchText)さん3")
        ]
    }
    
    private func sendFriendRequest(to user: User) {
        let success = viewModel.sendFriendRequest(to: user.id, message: message)
        if success {
            dismiss()
        }
    }
}

// MARK: - ユーザープロフィールビュー
struct UserProfileView: View {
    let user: User
    @ObservedObject var viewModel: AppViewModel
    let onSendRequest: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var message = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // プロフィール画像
                UserAvatar(profileImage: user.profileImage, customProfileImageData: user.customProfileImageData, size: 80)
                
                // ユーザー情報
                VStack(spacing: 8) {
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("ユーザーID: \(user.id.uuidString.prefix(8))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 友達リクエストメッセージ
                VStack(alignment: .leading, spacing: 8) {
                    Text("友達リクエストメッセージ")
                        .font(.headline)
                    
                    TextField("メッセージを入力（任意）", text: $message, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...5)
                }
                .padding(.horizontal)
                
                // 友達リクエスト送信ボタン
                Button(action: onSendRequest) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("友達リクエストを送信")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddFriendView(viewModel: AppViewModel())
} 