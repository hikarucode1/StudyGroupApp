import Foundation
import SwiftUI
import UserNotifications

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var rooms: [Room] = []
    @Published var effortRecords: [EffortRecord] = []
    @Published var notifications: [Notification] = []
    @Published var chatMessages: [ChatMessage] = []
    @Published var currentRoom: Room?
    @Published var roomStartTime: Date?
    
    private var timer: Timer?
    
    // UserDefaultsのキー
    private enum Keys {
        static let rooms = "savedRooms"
        static let effortRecords = "savedEffortRecords"
        static let notifications = "savedNotifications"
        static let chatMessages = "savedChatMessages"
        static let currentUser = "savedCurrentUser"
    }
    
    init() {
        setupNotifications()
        loadData()
    }
    
    // MARK: - 部屋管理
    func createRoom(name: String, tags: [String]) {
        let newRoom = Room(name: name, tags: tags)
        rooms.append(newRoom)
        saveData()
    }
    
    func joinRoom(_ room: Room) {
        guard let user = currentUser else { return }
        
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
        
        if let userData = UserDefaults.standard.data(forKey: Keys.currentUser),
           let savedUser = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = savedUser
            print("保存されたユーザーデータを読み込みました")
        } else {
            currentUser = User(name: "ユーザー")
        }
    }
    
    private func loadSampleRooms() {
        // サンプル部屋を作成
        rooms = [
            Room(name: "朝活勉強", tags: ["勉強", "朝活"]),
            Room(name: "夜の筋トレ", tags: ["筋トレ", "健康"]),
            Room(name: "資格勉強", tags: ["勉強", "資格"])
        ]
        print("サンプル部屋データを作成しました")
    }
    
    // MARK: - データ管理
    // App Store向けのため、データ操作機能は削除
    // データは自動的に保存・読み込みされる
} 