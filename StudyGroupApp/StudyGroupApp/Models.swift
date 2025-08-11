import Foundation
import SwiftUI

// MARK: - 部屋モデル
struct Room: Identifiable, Codable {
    let id = UUID()
    var name: String
    var tags: [String]
    var createdAt: Date
    var participants: [User]
    var isActive: Bool
    
    // プライベート設定
    var isPrivate: Bool
    var isInviteOnly: Bool
    var password: String?
    var maxParticipants: Int
    var createdBy: UUID // 部屋作成者のID
    
    // 部屋の状態管理
    var isClosed: Bool // 部屋が閉鎖されているか
    var closedAt: Date? // 閉鎖された日時
    var closedBy: UUID? // 閉鎖したユーザーのID
    
    init(name: String, tags: [String], createdBy: UUID, isPrivate: Bool = false, isInviteOnly: Bool = false, password: String? = nil, maxParticipants: Int = 10) {
        self.name = name
        self.tags = tags
        self.createdAt = Date()
        self.participants = []
        self.isActive = true
        self.isPrivate = isPrivate
        self.isInviteOnly = isInviteOnly
        self.password = password
        self.maxParticipants = maxParticipants
        self.createdBy = createdBy
        self.isClosed = false
        self.closedAt = nil
        self.closedBy = nil
    }
    
    // 部屋の参加可否をチェック
    func canJoin(userId: UUID, password: String? = nil) -> Bool {
        // 部屋が閉鎖されている場合は参加不可
        if isClosed {
            return false
        }
        
        // 非公開部屋でパスワードが設定されている場合
        if isPrivate && self.password != nil {
            return self.password == password
        }
        
        // 招待制の場合、作成者または既存参加者のみ
        if isInviteOnly {
            return createdBy == userId || participants.contains { $0.id == userId }
        }
        
        // 参加者数制限チェック
        if participants.count >= maxParticipants {
            return false
        }
        
        return true
    }
    
    // 部屋作成者かどうかチェック
    func isCreator(userId: UUID) -> Bool {
        return createdBy == userId
    }
}

// MARK: - ユーザーモデル
struct User: Identifiable, Codable {
    let id = UUID()
    var name: String
    var profileImage: String? // システムアイコン名
    var currentRoom: Room?
    var joinTime: Date?
    
    // 友達機能用のプロパティ
    var friends: [UUID] // 友達のIDリスト
    var friendRequests: [UUID] // 友達リクエストのIDリスト
    var isOnline: Bool // オンライン状態
    var lastSeen: Date // 最後のアクティビティ時間
    
    init(name: String) {
        self.name = name
        self.profileImage = "person.circle.fill"
        self.friends = []
        self.friendRequests = []
        self.isOnline = false
        self.lastSeen = Date()
    }
}

// MARK: - 友達リクエストモデル
struct FriendRequest: Identifiable, Codable {
    let id = UUID()
    var fromUserId: UUID
    var toUserId: UUID
    var status: RequestStatus
    var timestamp: Date
    var message: String?
    
    enum RequestStatus: String, Codable, CaseIterable {
        case pending = "pending"    // 待機中
        case accepted = "accepted"  // 承認済み
        case rejected = "rejected"  // 拒否済み
        
        var displayName: String {
            switch self {
            case .pending: return "待機中"
            case .accepted: return "承認済み"
            case .rejected: return "拒否済み"
            }
        }
    }
    
    init(fromUserId: UUID, toUserId: UUID, message: String? = nil) {
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.status = .pending
        self.timestamp = Date()
        self.message = message
    }
}

// MARK: - 友達グループモデル
struct FriendGroup: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String?
    var members: [UUID] // メンバーのIDリスト
    var createdBy: UUID
    var createdAt: Date
    var isActive: Bool
    
    init(name: String, description: String? = nil, createdBy: UUID) {
        self.name = name
        self.description = description
        self.members = [createdBy] // 作成者を最初のメンバーとして追加
        self.createdBy = createdBy
        self.createdAt = Date()
        self.isActive = true
    }
}

// MARK: - 努力記録モデル
struct EffortRecord: Identifiable, Codable {
    let id = UUID()
    var userId: UUID
    var roomId: UUID
    var tags: [String]
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval {
        endTime?.timeIntervalSince(startTime) ?? Date().timeIntervalSince(startTime)
    }
    
    init(userId: UUID, roomId: UUID, tags: [String]) {
        self.userId = userId
        self.roomId = roomId
        self.tags = tags
        self.startTime = Date()
    }
}

// MARK: - 通知モデル
struct Notification: Identifiable, Codable {
    let id = UUID()
    var userId: UUID
    var message: String
    var timestamp: Date
    var isRead: Bool
    
    init(userId: UUID, message: String) {
        self.userId = userId
        self.message = message
        self.timestamp = Date()
        self.isRead = false
    }
}

// MARK: - チャットメッセージモデル
struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    var userId: UUID
    var roomId: UUID
    var userName: String
    var userProfileImage: String?
    var message: String
    var timestamp: Date
    var messageType: MessageType
    
    enum MessageType: String, Codable, CaseIterable {
        case text = "text"
        case system = "system"      // システムメッセージ（入室・退室など）
        case reaction = "reaction"  // リアクション
        
        var displayName: String {
            switch self {
            case .text: return "テキスト"
            case .system: return "システム"
            case .reaction: return "リアクション"
            }
        }
    }
    
    init(userId: UUID, roomId: UUID, userName: String, userProfileImage: String? = nil, message: String, messageType: MessageType = .text) {
        self.userId = userId
        self.roomId = roomId
        self.userName = userName
        self.userProfileImage = userProfileImage
        self.message = message
        self.timestamp = Date()
        self.messageType = messageType
    }
}

// MARK: - 統計データ構造
struct EffortStats {
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let sessionCount: Int
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) % 3600 / 60
        return "\(hours)時間\(minutes)分"
    }
    
    var formattedAverageDuration: String {
        let minutes = Int(averageDuration) / 60
        return "\(minutes)分"
    }
}

// MARK: - 時間期間
enum TimePeriod {
    case today
    case week
    case month
    
    func isDateInPeriod(_ date: Date, now: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        
        switch self {
        case .today:
            return calendar.isDate(date, inSameDayAs: now)
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? startOfDay
            return date >= startOfWeek
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? startOfDay
            return date >= startOfMonth
        }
    }
}

// MARK: - タグ統計データ
struct TagStat {
    let tag: String
    let totalDuration: TimeInterval
    let sessionCount: Int
} 