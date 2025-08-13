import Foundation

// MARK: - 機能制限
struct FeatureLimits {
    static let freeRoomCreationLimit = 5
    static let freeFriendLimit = 10
    static let freeTagLimit = 5
}

// MARK: - 制限管理
class FeatureLimiter: ObservableObject {
    @Published var monthlyRoomCount: Int = 0
    @Published var currentFriendCount: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let monthlyRoomCountKey = "monthlyRoomCount"
    private let currentFriendCountKey = "currentFriendCount"
    private let lastResetDateKey = "lastResetDate"
    
    init() {
        loadCounts()
        checkMonthlyReset()
    }
    
    // MARK: - 部屋作成制限チェック
    func canCreateRoom() -> Bool {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let lastResetMonth = userDefaults.integer(forKey: lastResetDateKey)
        
        // 月が変わったらリセット
        if currentMonth != lastResetMonth {
            resetMonthlyCounts()
        }
        
        return monthlyRoomCount < FeatureLimits.freeRoomCreationLimit
    }
    
    // MARK: - 友達追加制限チェック
    func canAddFriend() -> Bool {
        return currentFriendCount < FeatureLimits.freeFriendLimit
    }
    
    // MARK: - カウント管理
    func incrementRoomCount() {
        monthlyRoomCount += 1
        saveMonthlyCounts()
    }
    
    func incrementFriendCount() {
        currentFriendCount += 1
        saveFriendCount()
    }
    
    func decrementFriendCount() {
        currentFriendCount = max(0, currentFriendCount - 1)
        saveFriendCount()
    }
    
    // MARK: - 月次リセット
    private func checkMonthlyReset() {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let lastResetMonth = userDefaults.integer(forKey: lastResetDateKey)
        
        if currentMonth != lastResetMonth {
            resetMonthlyCounts()
        }
    }
    
    private func resetMonthlyCounts() {
        monthlyRoomCount = 0
        let currentMonth = Calendar.current.component(.month, from: Date())
        userDefaults.set(currentMonth, forKey: lastResetDateKey)
        saveMonthlyCounts()
    }
    
    // MARK: - データ永続化
    private func loadCounts() {
        monthlyRoomCount = userDefaults.integer(forKey: monthlyRoomCountKey)
        currentFriendCount = userDefaults.integer(forKey: currentFriendCountKey)
    }
    
    private func saveMonthlyCounts() {
        userDefaults.set(monthlyRoomCount, forKey: monthlyRoomCountKey)
    }
    
    private func saveFriendCount() {
        userDefaults.set(currentFriendCount, forKey: currentFriendCountKey)
    }
} 