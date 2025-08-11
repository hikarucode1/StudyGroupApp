import SwiftUI

struct CreateRoomView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var roomName = ""
    @State private var newTag = ""
    @State private var tags: [String] = []
    
    // プライベート設定
    @State private var isPrivate = false
    @State private var isInviteOnly = false
    @State private var password = ""
    @State private var maxParticipants = 10
    
    var body: some View {
        NavigationView {
            Form {
                Section("部屋の基本情報") {
                    TextField("部屋名", text: $roomName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("タグ") {
                    HStack {
                        TextField("新しいタグ", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("追加") {
                            addTag()
                        }
                        .disabled(newTag.isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack {
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                    
                                    Button(action: {
                                        removeTag(tag)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("プライベート設定") {
                    Toggle("非公開部屋", isOn: $isPrivate)
                        .onChange(of: isPrivate) { newValue in
                            if !newValue {
                                password = ""
                            }
                        }
                    
                    if isPrivate {
                        SecureField("パスワード", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("パスワードを知っている人のみが参加できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("招待制", isOn: $isInviteOnly)
                        .onChange(of: isInviteOnly) { newValue in
                            if newValue {
                                isPrivate = true
                            }
                        }
                    
                    if isInviteOnly {
                        Text("部屋作成者のみが参加者を追加できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("最大参加者数")
                        Spacer()
                        Picker("最大参加者数", selection: $maxParticipants) {
                            ForEach([5, 10, 15, 20, 30, 50], id: \.self) { number in
                                Text("\(number)人").tag(number)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("推奨タグ") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(suggestedTags, id: \.self) { tag in
                            Button(action: {
                                if !tags.contains(tag) {
                                    tags.append(tag)
                                }
                            }) {
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.gray)
                                    .cornerRadius(12)
                            }
                            .disabled(tags.contains(tag))
                        }
                    }
                }
            }
            .navigationTitle("新しい部屋を作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        createRoom()
                    }
                    .disabled(roomName.isEmpty || tags.isEmpty)
                }
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func createRoom() {
        let finalPassword = isPrivate && !password.isEmpty ? password : nil
        viewModel.createRoom(
            name: roomName,
            tags: tags,
            isPrivate: isPrivate,
            isInviteOnly: isInviteOnly,
            password: finalPassword,
            maxParticipants: maxParticipants
        )
        dismiss()
    }
    
    private var suggestedTags: [String] {
        [
            "勉強", "筋トレ", "仕事", "アルバイト", "朝活", "夜活",
            "資格", "語学", "健康", "ダイエット", "読書", "プログラミング",
            "音楽", "アート", "料理", "掃除", "整理整頓"
        ]
    }
}

#Preview {
    CreateRoomView(viewModel: AppViewModel())
} 