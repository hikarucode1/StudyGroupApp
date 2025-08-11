# 努力の部屋 (Study Group App)

## 📱 アプリ概要

「努力の部屋」は、同じ時間に同じ努力をしている人たちとつながり、モチベーションを高め合うための iOS アプリです。

### 🎯 主な機能

- **部屋管理**: カスタム名とタグで部屋を作成・参加
- **リアルタイム時間計測**: 部屋に入ってからの時間を自動計測
- **統計表示**: タグ別の日次・週間・月間の努力記録
- **通知設定**: プッシュ通知と静寂時間の設定
- **データ永続化**: 自動保存・読み込み機能

### 🏷️ 対応タグ例

- 勉強、筋トレ、仕事、アルバイト
- 朝活、夜活、資格勉強
- 健康、ダイエット、読書

## 🛠️ 技術仕様

- **言語**: Swift 5
- **フレームワーク**: SwiftUI
- **ターゲット**: iOS 18.5+
- **アーキテクチャ**: MVVM (Model-View-ViewModel)
- **データ永続化**: UserDefaults
- **通知**: UNUserNotificationCenter

## 📁 プロジェクト構造

```
StudyGroupApp/
├── StudyGroupApp/
│   ├── Models.swift              # データモデル
│   ├── AppViewModel.swift        # ビジネスロジック
│   ├── ContentView.swift         # メインビュー
│   ├── RoomListView.swift        # 部屋一覧
│   ├── CreateRoomView.swift      # 部屋作成
│   ├── StatsView.swift           # 統計表示
│   ├── NotificationView.swift    # 通知一覧
│   ├── SettingsView.swift        # 設定画面
│   └── Assets.xcassets/         # アセット
├── StudyGroupAppTests/           # ユニットテスト
└── StudyGroupAppUITests/         # UIテスト
```

## 🚀 セットアップ手順

### 前提条件

- Xcode 16.0+
- iOS 18.5+ SDK
- macOS 15.0+

### インストール手順

1. リポジトリをクローン

```bash
git clone https://github.com/yourusername/study-group-app.git
cd study-group-app
```

2. Xcode でプロジェクトを開く

```bash
open StudyGroupApp/StudyGroupApp.xcodeproj
```

3. シミュレーターまたは実機でビルド・実行

## 📊 主要機能の詳細

### 部屋管理

- カスタム名とタグで部屋を作成
- 既存の部屋に参加・退出
- リアルタイムでの参加者表示

### 統計機能

- タグ別の努力時間集計
- 日次・週間・月間の記録表示
- 円グラフ・棒グラフでの可視化

### 通知機能

- プッシュ通知の設定
- 静寂時間の設定
- 友達の活動通知

## 🔒 プライバシー・セキュリティ

- ユーザーデータはローカルに保存
- 外部へのデータ送信なし
- 通知の許可はユーザーが制御

## 📱 App Store 対応

- データ操作機能は制限（安全性重視）
- プライバシーポリシー対応
- 利用規約対応
- ユーザー体験の最適化

## 🤝 開発者情報

- **開発者**: 渡邊光
- **作成日**: 2025 年 8 月
- **バージョン**: 1.0.0

## 📄 ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。

## 🐛 問題報告・機能要望

GitHub の Issues で問題報告や機能要望を受け付けています。

## 🔄 更新履歴

### v1.0.0 (2025-08-11)

- 初回リリース
- 基本的な部屋管理機能
- 統計表示機能
- 通知設定機能
- App Store 向けの最適化

---

**努力の部屋**で、一緒に目標達成を目指しましょう！ 🎯✨
