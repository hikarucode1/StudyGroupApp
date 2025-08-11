import SwiftUI

struct CreateRoomView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var roomName = ""
    @State private var newTag = ""
    @State private var tags: [String] = []
    
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
        viewModel.createRoom(name: roomName, tags: tags)
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