import SwiftUI
import PhotosUI
import UIKit

// MARK: - ユーザープロフィール編集画面
struct UserProfileEditView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var goal: String = ""
    @State private var showingImagePicker = false
    @State private var customImage: UIImage?
    
    // デバッグ用：状態変数の確認
    private func debugState() {
        print("=== 状態変数の確認 ===")
        print("showingImagePicker: \(showingImagePicker)")
        print("customImage: \(customImage != nil ? "設定済み" : "未設定")")
        print("=====================")
    }
    

    
    var body: some View {
        NavigationStack {
            Form {
                // プロフィール画像
                Section {
                    VStack(spacing: 16) {
                        // プロフィール画像表示
                        if let customImage = customImage {
                            Image(uiImage: customImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                )
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                        .frame(width: 80, height: 80)
                                )
                        }
                        
                        // 画像選択ボタン
                        VStack(spacing: 12) {
                            Button(action: {
                                print("写真選択ボタンがタップされました")
                                showingImagePicker = true
                                debugState()
                            }) {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("写真を選択")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            
                            if customImage != nil {
                                Button("画像を削除") {
                                    customImage = nil
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical)
                } header: {
                    Text("プロフィール画像")
                }
                
                // 基本情報
                Section {
                    TextField("名前", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("自己紹介", text: $bio, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                } header: {
                    Text("基本情報")
                }
                
                // 目標設定
                Section {
                    TextField("目標（例：毎日1時間勉強する）", text: $goal, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                } header: {
                    Text("目標設定")
                } footer: {
                    Text("目標を設定することで、モチベーションを保ちやすくなります。")
                }
                
                // プレビュー
                Section {
                    HStack {
                        if let customImage = customImage {
                            Image(uiImage: customImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "名前" : name)
                                .font(.headline)
                            
                            if !bio.isEmpty {
                                Text(bio)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            if !goal.isEmpty {
                                Text("🎯 \(goal)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("プレビュー")
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveProfile()
                }
                .disabled(name.isEmpty)
            )

            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $customImage)
            }
            .onAppear {
                loadCurrentProfile()
                debugState()
            }
        }
    }
    
    // MARK: - 現在のプロフィールを読み込み
    private func loadCurrentProfile() {
        if let user = viewModel.currentUser {
            name = user.name
            bio = user.bio ?? ""
            goal = user.goal ?? ""
            
            if let imageData = user.customProfileImageData {
                customImage = UIImage(data: imageData)
            }
        }
    }
    
    // MARK: - プロフィールを保存
    private func saveProfile() {
        var imageData: Data?
        if let customImage = customImage {
            imageData = customImage.jpegData(compressionQuality: 0.8)
        }
        
        viewModel.updateUserProfile(
            name: name,
            bio: bio,
            goal: goal,
            profileImage: nil,
            customProfileImageData: imageData
        )
        dismiss()
    }
}



#Preview {
    UserProfileEditView(viewModel: AppViewModel())
}

// MARK: - 画像選択画面
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
} 