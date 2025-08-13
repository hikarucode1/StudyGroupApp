import Foundation
import SwiftUI
import UserNotifications

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var rooms: [Room] = []
    @Published var currentRoom: Room?
    @Published var roomStartTime: Date?
    @Published var effortRecords: [EffortRecord] = []
    @Published var notifications: [Notification] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var friendGroups: [FriendGroup] = []
    @Published var chatMessages: [ChatMessage] = []
    
    // 機能制限管理を追加
    @Published var featureLimiter = FeatureLimiter()
    
    // プレミアム管理を追加
    @Published var premiumManager = PremiumManager()
    
    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    
    // UserDefaultsのキー
    private enum Keys {
        static let rooms = "savedRooms"
        static let effortRecords = "savedEffortRecords"
        static let notifications = "savedNotifications"
        static let chatMessages = "savedChatMessages"
        static let friendRequests = "savedFriendRequests"
        static let friendGroups = "savedFriendGroups"
        static let currentUser = "savedCurrentUser"
    }
    
    init() {
        loadData()
    }
    
    // MARK: - 部屋管理
    func createRoom(name: String, tags: [String], isPrivate: Bool = false, isInviteOnly: Bool = false, password: String? = nil, maxParticipants: Int = 10) -> Bool {
        guard let user = currentUser else { return false }
        
        // プレミアム版でない場合のみ部屋作成制限をチェック
        if !premiumManager.isPremium && !featureLimiter.canCreateRoom() {
            return false
        }
        
        var newRoom = Room(
            name: name,
            tags: tags,
            createdBy: user.id,
            isPrivate: isPrivate,
            isInviteOnly: isInviteOnly,
            password: password,
            maxParticipants: maxParticipants
        )
        
        // 作成者を最初の参加者として追加
        newRoom.participants.append(user)
        
        rooms.append(newRoom)
        
        // プレミアム版でない場合のみ部屋作成カウントを増加
        if !premiumManager.isPremium {
            featureLimiter.incrementRoomCount()
        }
        
        // 作成者を自動的に部屋に参加させる
        currentRoom = newRoom
        roomStartTime = Date()
        
        // 努力記録を作成
        let record = EffortRecord(userId: user.id, roomId: newRoom.id, tags: newRoom.tags)
        effortRecords.append(record)
        
        // システムメッセージを送信
        sendSystemMessage(message: "\(user.name)さんが部屋を作成しました", roomId: newRoom.id)
        
        // タイマー開始
        startTimer()
        
        saveData()
        return true
    }
    
    func joinRoom(_ room: Room, password: String? = nil) -> Bool {
        guard let user = currentUser else { return false }
        
        // 部屋の参加可否をチェック
        if !room.canJoin(userId: user.id, password: password) {
            return false
        }
        
        // 現在の部屋から退出
        leaveCurrentRoom()
        
        // 新しい部屋に参加
        currentRoom = room
        roomStartTime = Date()
        
        // 部屋の参加者リストに追加
        if let roomIndex = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[roomIndex].participants.append(user)
        }
        
        // 努力記録を作成
        let record = EffortRecord(userId: user.id, roomId: room.id, tags: room.tags)
        effortRecords.append(record)
        
        // システムメッセージを送信
        sendSystemMessage(message: "\(user.name)さんが部屋に参加しました", roomId: room.id)
        
        // タイマー開始
        startTimer()
        
        saveData()
        return true
    }
    
    // 部屋の設定を更新
    func updateRoomSettings(roomId: UUID, isPrivate: Bool, isInviteOnly: Bool, password: String?, maxParticipants: Int) -> Bool {
        guard let user = currentUser,
              let roomIndex = rooms.firstIndex(where: { $0.id == roomId }),
              rooms[roomIndex].isCreator(userId: user.id) else { return false }
        
        rooms[roomIndex].isPrivate = isPrivate
        rooms[roomIndex].isInviteOnly = isInviteOnly
        rooms[roomIndex].password = password
        rooms[roomIndex].maxParticipants = maxParticipants
        
        saveData()
        return true
    }
    
    // 部屋からユーザーを削除（作成者のみ）
    func removeUserFromRoom(roomId: UUID, userId: UUID) -> Bool {
        guard let user = currentUser,
              let roomIndex = rooms.firstIndex(where: { $0.id == roomId }),
              rooms[roomIndex].isCreator(userId: user.id) else { return false }
        
        // 自分自身は削除できない
        if userId == user.id {
            return false
        }
        
        if let participantIndex = rooms[roomIndex].participants.firstIndex(where: { $0.id == userId }) {
            let removedUser = rooms[roomIndex].participants[participantIndex]
            rooms[roomIndex].participants.remove(at: participantIndex)
            
            // システムメッセージを送信
            sendSystemMessage(message: "\(removedUser.name)さんが部屋から削除されました", roomId: roomId)
            
            saveData()
            return true
        }
        
        return false
    }
    
    // 部屋を閉鎖（作成者のみ）
    func closeRoom(roomId: UUID) -> Bool {
        guard let user = currentUser,
              let roomIndex = rooms.firstIndex(where: { $0.id == roomId }),
              rooms[roomIndex].isCreator(userId: user.id) else { return false }
        
        // 部屋を閉鎖状態にする
        rooms[roomIndex].isClosed = true
        rooms[roomIndex].closedAt = Date()
        rooms[roomIndex].closedBy = user.id
        
        // 部屋の参加者全員を退出させる
        let participants = rooms[roomIndex].participants
        for participant in participants {
            if participant.id != user.id { // 作成者以外
                leaveRoom(roomId: roomId, userId: participant.id)
            }
        }
        
        // 作成者も部屋から退出
        leaveRoom(roomId: roomId, userId: user.id)
        
        // システムメッセージを送信
        sendSystemMessage(message: "部屋が作成者によって閉鎖されました", roomId: roomId)
        
        saveData()
        return true
    }
    
    // 部屋から特定のユーザーを退出させる（作成者のみ）
    private func leaveRoom(roomId: UUID, userId: UUID) {
        guard let roomIndex = rooms.firstIndex(where: { $0.id == roomId }) else { return }
        
        if let participantIndex = rooms[roomIndex].participants.firstIndex(where: { $0.id == userId }) {
            let user = rooms[roomIndex].participants[participantIndex]
            rooms[roomIndex].participants.remove(at: participantIndex)
            
            // 努力記録を終了
            if let recordIndex = effortRecords.firstIndex(where: { $0.userId == userId && $0.roomId == roomId && $0.endTime == nil }) {
                effortRecords[recordIndex].endTime = Date()
                // durationは計算プロパティなので自動的に更新される
            }
        }
    }
    
    func leaveCurrentRoom() {
        guard let user = currentUser,
              let room = currentRoom,
              let startTime = roomStartTime else { return }
        
        // 努力記録を完了
        if let recordIndex = effortRecords.firstIndex(where: { 
            $0.userId == user.id && $0.roomId == room.id && $0.endTime == nil 
        }) {
            effortRecords[recordIndex].endTime = Date()
        }
        
        // 部屋の参加者リストから削除
        if let roomIndex = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[roomIndex].participants.removeAll { $0.id == user.id }
        }
        
        // システムメッセージを送信
        sendSystemMessage(message: "\(user.name)さんが部屋から退出しました", roomId: room.id)
        
        currentRoom = nil
        roomStartTime = nil
        stopTimer()
        
        saveData()
    }
    
    // MARK: - タイマー管理
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // 1秒ごとに更新
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - 統計データ
    func getEffortStats(for tags: [String], period: TimePeriod) -> EffortStats {
        let now = Date()
        let filteredRecords = effortRecords.filter { record in
            let hasMatchingTags = !Set(record.tags).isDisjoint(with: Set(tags))
            let isInPeriod = period.isDateInPeriod(record.startTime, now: now)
            return hasMatchingTags && isInPeriod
        }
        
        let totalDuration = filteredRecords.reduce(0) { $0 + $1.duration }
        let averageDuration = filteredRecords.isEmpty ? 0 : totalDuration / Double(filteredRecords.count)
        
        return EffortStats(
            totalDuration: totalDuration,
            averageDuration: averageDuration,
            sessionCount: filteredRecords.count
        )
    }
    
    // MARK: - 通知機能
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("通知が許可されました")
            }
        }
    }
    
    func sendNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "努力の部屋"
        content.body = message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - チャット機能
    func sendChatMessage(message: String, roomId: UUID) {
        guard let user = currentUser else { return }
        
        let chatMessage = ChatMessage(
            userId: user.id,
            roomId: roomId,
            userName: user.name,
            userProfileImage: user.profileImage,
            message: message
        )
        
        chatMessages.append(chatMessage)
        saveData()
    }
    
    func sendSystemMessage(message: String, roomId: UUID) {
        let systemMessage = ChatMessage(
            userId: UUID(), // システムメッセージ用の特別なID
            roomId: roomId,
            userName: "システム",
            userProfileImage: "info.circle.fill",
            message: message,
            messageType: .system
        )
        
        chatMessages.append(systemMessage)
        saveData()
    }
    
    func getChatMessages(for roomId: UUID) -> [ChatMessage] {
        return chatMessages
            .filter { $0.roomId == roomId }
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    func clearChatMessages(for roomId: UUID) {
        chatMessages.removeAll { $0.roomId == roomId }
        saveData()
    }
    
    // MARK: - 友達機能
    func sendFriendRequest(to userId: UUID, message: String? = nil) -> Bool {
        guard let currentUser = currentUser else { return false }
        
        // プレミアム版でない場合のみ友達数制限をチェック
        if !premiumManager.isPremium && !featureLimiter.canAddFriend() {
            return false
        }
        
        // 既に友達リクエストが存在するかチェック
        if friendRequests.contains(where: { $0.fromUserId == currentUser.id && $0.toUserId == userId }) {
            return false
        }
        
        let request = FriendRequest(fromUserId: currentUser.id, toUserId: userId, message: message)
        friendRequests.append(request)
        
        // プレミアム版でない場合のみ友達数カウントを増加
        if !premiumManager.isPremium {
            featureLimiter.incrementFriendCount()
        }
        
        saveData()
        return true
    }
    
    func acceptFriendRequest(_ requestId: UUID) -> Bool {
        guard var user = currentUser,
              let requestIndex = friendRequests.firstIndex(where: { $0.id == requestId }),
              friendRequests[requestIndex].toUserId == user.id else { return false }
        
        let request = friendRequests[requestIndex]
        
        // 友達リクエストを承認済みに変更
        friendRequests[requestIndex].status = .accepted
        
        // お互いの友達リストに追加
        if let userIndex = rooms.firstIndex(where: { $0.participants.contains { $0.id == request.fromUserId } }) {
            // 友達リストに追加
            if !user.friends.contains(request.fromUserId) {
                user.friends.append(request.fromUserId)
            }
            
            // 相手の友達リストにも追加（仮想的に）
            // 実際のアプリでは、相手のデータも更新する必要があります
        }
        
        // 現在のユーザーを更新
        currentUser = user
        
        saveData()
        return true
    }
    
    func rejectFriendRequest(_ requestId: UUID) -> Bool {
        guard let user = currentUser,
              let requestIndex = friendRequests.firstIndex(where: { $0.id == requestId }),
              friendRequests[requestIndex].toUserId == user.id else { return false }
        
        friendRequests[requestIndex].status = .rejected
        saveData()
        return true
    }
    
    func removeFriend(_ friendId: UUID) -> Bool {
        guard var user = currentUser else { return false }
        
        user.friends.removeAll { $0 == friendId }
        
        // 現在のユーザーを更新
        currentUser = user
        
        saveData()
        return true
    }
    
    func createFriendGroup(name: String, description: String?, memberIds: [UUID]) -> Bool {
        guard let currentUser = currentUser else { return false }
        
        let group = FriendGroup(name: name, description: description, createdBy: currentUser.id)
        var newGroup = group
        newGroup.members = [currentUser.id] + memberIds.filter { $0 != currentUser.id }
        
        friendGroups.append(newGroup)
        saveData()
        return true
    }
    
    func getFriendsList() -> [User] {
        guard let currentUser = currentUser else { return [] }
        
        // 現在のユーザーの友達IDからユーザーオブジェクトを取得
        // 実際のアプリでは、ユーザーデータベースから取得する必要があります
        return currentUser.friends.compactMap { friendId in
            // 仮想的な実装 - 実際にはユーザーデータベースから取得
            User(name: "友達\(friendId.uuidString.prefix(4))")
        }
    }
    
    func getPendingFriendRequests() -> [FriendRequest] {
        guard let currentUser = currentUser else { return [] }
        
        return friendRequests.filter { 
            $0.toUserId == currentUser.id && $0.status == .pending 
        }
    }
    
    // MARK: - データ永続化
    private func saveData() {
        do {
            // 部屋データの保存
            let roomsData = try JSONEncoder().encode(rooms)
            UserDefaults.standard.set(roomsData, forKey: Keys.rooms)
            
            // 努力記録データの保存
            let recordsData = try JSONEncoder().encode(effortRecords)
            UserDefaults.standard.set(recordsData, forKey: Keys.effortRecords)
            
            // 通知データの保存
            let notificationsData = try JSONEncoder().encode(notifications)
            UserDefaults.standard.set(notificationsData, forKey: Keys.notifications)
            
            // チャットメッセージデータの保存
            let chatMessagesData = try JSONEncoder().encode(chatMessages)
            UserDefaults.standard.set(chatMessagesData, forKey: Keys.chatMessages)
            
            // 友達リクエストデータの保存
            let friendRequestsData = try JSONEncoder().encode(friendRequests)
            UserDefaults.standard.set(friendRequestsData, forKey: Keys.friendRequests)
            
            // 友達グループデータの保存
            let friendGroupsData = try JSONEncoder().encode(friendGroups)
            UserDefaults.standard.set(friendGroupsData, forKey: Keys.friendGroups)
            
            // 現在のユーザーデータの保存
            if let user = currentUser {
                let userData = try JSONEncoder().encode(user)
                UserDefaults.standard.set(userData, forKey: Keys.currentUser)
            }
            
            print("データが正常に保存されました")
        } catch {
            print("データの保存に失敗しました: \(error)")
        }
    }
    
    private func loadData() {
        // 保存されたデータがある場合は読み込み、ない場合はサンプルデータを作成
        if let roomsData = UserDefaults.standard.data(forKey: Keys.rooms),
           let savedRooms = try? JSONDecoder().decode([Room].self, from: roomsData) {
            rooms = savedRooms
            print("保存された部屋データを読み込みました: \(savedRooms.count)件")
        } else {
            loadSampleRooms()
        }
        
        if let recordsData = UserDefaults.standard.data(forKey: Keys.effortRecords),
           let savedRecords = try? JSONDecoder().decode([EffortRecord].self, from: recordsData) {
            effortRecords = savedRecords
            print("保存された努力記録を読み込みました: \(savedRecords.count)件")
        }
        
        if let notificationsData = UserDefaults.standard.data(forKey: Keys.notifications),
           let savedNotifications = try? JSONDecoder().decode([Notification].self, from: notificationsData) {
            notifications = savedNotifications
            print("保存された通知を読み込みました: \(savedNotifications.count)件")
        }
        
        if let chatMessagesData = UserDefaults.standard.data(forKey: Keys.chatMessages),
           let savedChatMessages = try? JSONDecoder().decode([ChatMessage].self, from: chatMessagesData) {
            chatMessages = savedChatMessages
            print("保存されたチャットメッセージを読み込みました: \(savedChatMessages.count)件")
        }
        
        if let friendRequestsData = UserDefaults.standard.data(forKey: Keys.friendRequests),
           let savedFriendRequests = try? JSONDecoder().decode([FriendRequest].self, from: friendRequestsData) {
            friendRequests = savedFriendRequests
            print("保存された友達リクエストを読み込みました: \(savedFriendRequests.count)件")
        }
        
        if let friendGroupsData = UserDefaults.standard.data(forKey: Keys.friendGroups),
           let savedFriendGroups = try? JSONDecoder().decode([FriendGroup].self, from: friendGroupsData) {
            friendGroups = savedFriendGroups
            print("保存された友達グループを読み込みました: \(savedFriendGroups.count)件")
        }
        
        if let userData = UserDefaults.standard.data(forKey: Keys.currentUser),
           let savedUser = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = savedUser
            print("保存されたユーザーデータを読み込みました")
        } else {
            currentUser = User(name: "ユーザー")
        }
    }
    
    private func loadSampleRooms() {
        guard let user = currentUser else { return }
        
        // サンプル部屋を作成
        rooms = [
            Room(name: "朝活勉強", tags: ["勉強", "朝活"], createdBy: user.id, isPrivate: false, isInviteOnly: false),
            Room(name: "夜の筋トレ", tags: ["筋トレ", "健康"], createdBy: user.id, isPrivate: false, isInviteOnly: false),
            Room(name: "資格勉強", tags: ["勉強", "資格"], createdBy: user.id, isPrivate: true, isInviteOnly: true, password: "1234", maxParticipants: 5)
        ]
        print("サンプル部屋データを作成しました")
    }
    
    // MARK: - データ管理
    // App Store向けのため、データ操作機能は削除
    // データは自動的に保存・読み込みされる
} 