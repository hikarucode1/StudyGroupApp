//
//  StudyGroupAppApp.swift
//  StudyGroupApp
//
//  Created by 渡邊光 on 2025/08/11.
//

import SwiftUI
import UserNotifications

@main
struct StudyGroupAppApp: App {
    init() {
        // 通知の許可をリクエスト
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("通知が許可されました")
            } else {
                print("通知が拒否されました")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
