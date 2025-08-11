import SwiftUI

struct NotificationView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.notifications.isEmpty {
                    EmptyNotificationView()
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRowView(notification: notification)
                        }
                        .onDelete(perform: deleteNotifications)
                    }
                }
            }
            .navigationTitle("通知")
        }
    }
    
    private func deleteNotifications(offsets: IndexSet) {
        viewModel.notifications.remove(atOffsets: offsets)
    }
}

// MARK: - 空の通知ビュー
struct EmptyNotificationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("通知はありません")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("友達が同じ時間に活動を始めると\n通知が届きます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 通知行ビュー
struct NotificationRowView: View {
    let notification: Notification
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 通知アイコン
            Image(systemName: "bell.fill")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.body)
                    .lineLimit(3)
                
                Text(notification.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 既読/未読インジケーター
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            markAsRead()
        }
    }
    
    private func markAsRead() {
        // 既読にする処理
        // 実際のアプリではViewModelを通じて処理
    }
}

#Preview {
    NotificationView(viewModel: AppViewModel())
} 