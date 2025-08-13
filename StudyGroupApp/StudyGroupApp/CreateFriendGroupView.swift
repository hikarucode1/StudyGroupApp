import SwiftUI

struct CreateFriendGroupView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var selectedFriends: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            Form {
                Section("グループの基本情報") {
                    TextField("グループ名", text: $groupName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("説明（任意）", text: $groupDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
                
                Section("友達を選択") {
                    if viewModel.getFriendsList().isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            
                            Text("まだ友達がいません")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("友達を追加してからグループを作成できます")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.getFriendsList()) { friend in
                            HStack {
                                UserAvatar(profileImage: friend.profileImage, customProfileImageData: friend.customProfileImageData, size: 32)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(friend.name)
                                        .font(.body)
                                    
                                    if friend.isOnline {
                                        HStack {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 6, height: 6)
                                            Text("オンライン")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedFriends.contains(friend.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                        .font(.title2)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedFriends.contains(friend.id) {
                                    selectedFriends.remove(friend.id)
                                } else {
                                    selectedFriends.insert(friend.id)
                                }
                            }
                        }
                    }
                }
                
                if !selectedFriends.isEmpty {
                    Section("選択された友達") {
                        Text("\(selectedFriends.count)人の友達が選択されています")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("友達グループを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty || selectedFriends.isEmpty)
                }
            }
        }
    }
    
    private func createGroup() {
        let success = viewModel.createFriendGroup(
            name: groupName,
            description: groupDescription.isEmpty ? nil : groupDescription,
            memberIds: Array(selectedFriends)
        )
        
        if success {
            dismiss()
        }
    }
}

#Preview {
    CreateFriendGroupView(viewModel: AppViewModel())
} 