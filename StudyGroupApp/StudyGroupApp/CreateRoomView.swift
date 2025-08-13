import SwiftUI

struct CreateRoomView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var roomName = ""
    @State private var newTag = ""
    @State private var tags: [String] = []
    @State private var showingTagSuggestions = false
    @State private var filteredTags: [String] = []
    
    // プライベート設定
    @State private var isPrivate = false
    @State private var isInviteOnly = false
    @State private var password = ""
    @State private var maxParticipants = 10
    
    // 制限アラート管理
    @State private var showingLimitAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("部屋の基本情報") {
                    TextField("部屋名", text: $roomName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("タグ設定") {
                    VStack(alignment: .leading, spacing: 12) {
                        // タグの説明
                        Text("部屋の目的や内容を表すタグを設定してください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                        
                        // タグ入力欄
                        HStack {
                            TextField("例: 勉強, 朝活, 資格", text: $newTag)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: newTag) { newValue in
                                    filterTags(for: newValue)
                                    showingTagSuggestions = !newValue.isEmpty
                                }
                            
                            Button("追加") {
                                addTag()
                            }
                            .disabled(newTag.isEmpty)
                            .buttonStyle(.borderedProminent)
                        }
                        
                        // タグ入力のヒント
                        Text("💡 ヒント: 「勉強」「朝活」「資格」など、部屋の目的を表す言葉を入力してください")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    // タグ候補の表示
                    if showingTagSuggestions && !filteredTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("タグ候補:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                                ForEach(filteredTags, id: \.self) { tag in
                                    Button(action: {
                                        if !tags.contains(tag) {
                                            tags.append(tag)
                                            newTag = ""
                                            showingTagSuggestions = false
                                        }
                                    }) {
                                        Text("#\(tag)")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .cornerRadius(8)
                                    }
                                    .disabled(tags.contains(tag))
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 設定されたタグの表示
                    if !tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("設定されたタグ (\(tags.count)個)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button("全て削除") {
                                    tags.removeAll()
                                }
                                .font(.caption2)
                                .foregroundColor(.red)
                            }
                            
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
                    } else {
                        // タグが設定されていない場合の案内
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.secondary)
                            Text("タグが設定されていません")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
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
        .alert("部屋作成制限に達しました", isPresented: $showingLimitAlert) {
            Button("OK", role: .cancel) {
                // ユーザーがOKを押したときの処理
            }
        } message: {
            Text("月間の部屋作成制限（5部屋）に達しました。プレミアム版にアップグレードすると、無制限に部屋を作成できます。")
        }
        .sheet(isPresented: $showingLimitAlert) {
            LimitAlertView(
                feature: "部屋作成",
                currentLimit: FeatureLimits.freeRoomCreationLimit,
                limitType: "月間",
                onDismiss: {
                    showingLimitAlert = false
                }
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
            showingTagSuggestions = false
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func filterTags(for input: String) {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedInput.isEmpty {
            filteredTags = []
        } else {
            // 入力文字列を含むタグを検索（部分一致）
            filteredTags = commonTags.filter { tag in
                tag.localizedCaseInsensitiveContains(trimmedInput)
            }
        }
    }
    
    private func createRoom() {
        // 部屋作成制限をチェック
        if !viewModel.featureLimiter.canCreateRoom() {
            showingLimitAlert = true
            return
        }
        
        let finalPassword = isPrivate && !password.isEmpty ? password : nil
        let success = viewModel.createRoom(
            name: roomName,
            tags: tags,
            isPrivate: isPrivate,
            isInviteOnly: isInviteOnly,
            password: finalPassword,
            maxParticipants: maxParticipants
        )
        
        if success {
            dismiss()
        }
    }
    
    // よく使われるタグの候補（予測変換用）
    private var commonTags: [String] {
        [
            // 学習・勉強系
            "勉強", "資格", "語学", "プログラミング", "読書", "論文", "研究", "試験", "テスト", "レポート",
            
            // 運動・健康系
            "筋トレ", "運動", "ランニング", "ウォーキング", "ヨガ", "ストレッチ", "ダイエット", "健康", "睡眠", "食事",
            
            // 仕事・活動系
            "仕事", "アルバイト", "副業", "起業", "営業", "企画", "デザイン", "マーケティング", "会計", "法務",
            
            // 時間帯・習慣系
            "朝活", "夜活", "早起き", "夜更かし", "習慣", "継続", "計画", "目標", "振り返り", "記録",
            
            // 趣味・生活系
            "音楽", "アート", "料理", "掃除", "整理整頓", "DIY", "ガーデニング", "写真", "動画", "ゲーム",
            
            // メンタル・精神系
            "瞑想", "日記", "感謝", "ポジティブ", "ストレス解消", "リラックス", "集中", "モチベーション", "自己啓発", "マインドフルネス"
        ]
    }
}

#Preview {
    CreateRoomView(viewModel: AppViewModel())
} 