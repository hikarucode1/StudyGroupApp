//
//  ContentView.swift
//  StudyGroupApp
//
//  Created by 渡邊光 on 2025/08/11.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        TabView {
            // 部屋一覧タブ
            RoomListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("部屋")
                }
            
            // 統計タブ
            StatsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("統計")
                }
            
            // 通知タブ
            NotificationView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("通知")
                }
            
            // 設定タブ
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
}
