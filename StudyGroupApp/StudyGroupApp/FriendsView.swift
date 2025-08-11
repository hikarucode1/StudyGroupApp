import SwiftUI

struct FriendsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedTab = 0
    @State private var showingAddFriend = false
    @State private var showingCreateGroup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // タブ選択
                Picker("", selection: $selectedTab) {
                    Text("友達").tag(0)
                    Text("リクエスト").tag(1)
                    Text("グループ").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // タブコンテンツ
                TabView(selection: $selectedTab) {
                    FriendsListView(viewModel: viewModel)
                        .tag(0)
                    
                    FriendRequestsView(viewModel: viewModel)
                        .tag(1)
                    
                    FriendGroupsView(viewModel: viewModel)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("友達")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateGroup = true
                    }) {
                        Image(systemName: "person.3")
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateFriendGroupView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - 友達一覧ビュー
struct FriendsListView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        List {
            if viewModel.getFriendsList().isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("まだ友達がいません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("友達を追加して、一緒に頑張りましょう！")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.getFriendsList()) { friend in
                    FriendRowView(friend: friend, viewModel: viewModel)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - 友達行ビュー
struct FriendRowView: View {
    let friend: User
    @ObservedObject var viewModel: AppViewModel
    @State private var showingActionSheet = false
    
    var body: some View {
        HStack {
            UserAvatar(profileImage: friend.profileImage, size: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                
                HStack {
                    if friend.isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("オンライン")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("最終アクセス: \(friend.lastSeen, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                showingActionSheet = true
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text(friend.name),
                buttons: [
                    .default(Text("チャット")) {
                        // チャット機能を実装
                    },
                    .default(Text("部屋に招待")) {
                        // 部屋招待機能を実装
                    },
                    .destructive(Text("友達を削除")) {
                        viewModel.removeFriend(friend.id)
                    },
                    .cancel()
                ]
            )
        }
    }
}

// MARK: - 友達リクエストビュー
struct FriendRequestsView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        List {
            if viewModel.getPendingFriendRequests().isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("友達リクエストはありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.getPendingFriendRequests()) { request in
                    FriendRequestRowView(request: request, viewModel: viewModel)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - 友達リクエスト行ビュー
struct FriendRequestRowView: View {
    let request: FriendRequest
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        HStack {
            UserAvatar(profileImage: "person.circle.fill", size: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("友達リクエスト")
                    .font(.headline)
                
                if let message = request.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(request.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("承認") {
                    viewModel.acceptFriendRequest(request.id)
                }
                .buttonStyle(.borderedProminent)
                
                Button("拒否") {
                    viewModel.rejectFriendRequest(request.id)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 友達グループビュー
struct FriendGroupsView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        List {
            if viewModel.friendGroups.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("友達グループはありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("友達と一緒にグループを作成しましょう！")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.friendGroups) { group in
                    FriendGroupRowView(group: group)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - 友達グループ行ビュー
struct FriendGroupRowView: View {
    let group: FriendGroup
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "person.3")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                
                if let description = group.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(group.members.count)人のメンバー")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(group.createdAt, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FriendsView(viewModel: AppViewModel())
} 