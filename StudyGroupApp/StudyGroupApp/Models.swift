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
    
    init(name: String, tags: [String]) {
        self.name = name
        self.tags = tags
        self.createdAt = Date()
        self.participants = []
        self.isActive = true
    }
}

// MARK: - ユーザーモデル
struct User: Identifiable, Codable {
    let id = UUID()
    var name: String
    var profileImage: String? // システムアイコン名
    var currentRoom: Room?
    var joinTime: Date?
    
    init(name: String) {
        self.name = name
        self.profileImage = "person.circle.fill"
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