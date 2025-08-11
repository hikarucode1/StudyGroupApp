import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedPeriod: TimePeriod = .today
    @State private var selectedTags: Set<String> = []
    
    var allTags: [String] {
        Array(Set(viewModel.effortRecords.flatMap { $0.tags })).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 期間選択
                Picker("期間", selection: $selectedPeriod) {
                    Text("今日").tag(TimePeriod.today)
                    Text("今週").tag(TimePeriod.week)
                    Text("今月").tag(TimePeriod.month)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // タグ選択
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allTags, id: \.self) { tag in
                            TagToggleButton(
                                tag: tag,
                                isSelected: selectedTags.contains(tag),
                                onTap: {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                if selectedTags.isEmpty {
                    // 全タグの統計
                    OverallStatsView(viewModel: viewModel, period: selectedPeriod)
                } else {
                    // 選択されたタグの統計
                    SelectedTagsStatsView(
                        viewModel: viewModel,
                        period: selectedPeriod,
                        tags: Array(selectedTags)
                    )
                }
                
                Spacer()
            }
            .navigationTitle("努力記録")
        }
    }
}

// MARK: - 全タグ統計ビュー
struct OverallStatsView: View {
    let viewModel: AppViewModel
    let period: TimePeriod
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // サマリーカード
                SummaryCard(
                    title: "総努力時間",
                    value: getTotalEffortTime(),
                    icon: "clock.fill",
                    color: .blue
                )
                
                // タグ別統計
                VStack(alignment: .leading, spacing: 12) {
                    Text("タグ別統計")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(getTagStats(), id: \.tag) { stat in
                        TagStatRow(stat: stat)
                    }
                }
                
                // チャート
                if !getTagStats().isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("タグ別時間分布")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(getTagStats(), id: \.tag) { stat in
                            SectorMark(
                                angle: .value("時間", stat.totalDuration),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(by: .value("タグ", stat.tag))
                        }
                        .frame(height: 200)
                        .padding()
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private func getTotalEffortTime() -> String {
        let total = viewModel.effortRecords
            .filter { period.isDateInPeriod($0.startTime, now: Date()) }
            .reduce(0) { $0 + $1.duration }
        
        let hours = Int(total) / 3600
        let minutes = Int(total) % 3600 / 60
        return "\(hours)時間\(minutes)分"
    }
    
    private func getTagStats() -> [TagStat] {
        let allTags = Set(viewModel.effortRecords.flatMap { $0.tags })
        return allTags.map { tag in
            let stats = viewModel.getEffortStats(for: [tag], period: period)
            return TagStat(tag: tag, totalDuration: stats.totalDuration, sessionCount: stats.sessionCount)
        }
        .sorted { $0.totalDuration > $1.totalDuration }
    }
}

// MARK: - 選択タグ統計ビュー
struct SelectedTagsStatsView: View {
    let viewModel: AppViewModel
    let period: TimePeriod
    let tags: [String]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 選択されたタグの統計
                ForEach(tags, id: \.self) { tag in
                    let stats = viewModel.getEffortStats(for: [tag], period: period)
                    TagDetailCard(tag: tag, stats: stats)
                }
                
                // 比較チャート
                if tags.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("タグ比較")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(tags, id: \.self) { tag in
                            let stats = viewModel.getEffortStats(for: [tag], period: period)
                            BarMark(
                                x: .value("タグ", tag),
                                y: .value("時間", stats.totalDuration / 3600)
                            )
                            .foregroundStyle(by: .value("タグ", tag))
                        }
                        .frame(height: 200)
                        .padding()
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - サマリーカード
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - タグ統計行
struct TagStatRow: View {
    let stat: TagStat
    
    var body: some View {
        HStack {
            Text("#\(stat.tag)")
                .font(.headline)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(formatDuration(stat.totalDuration))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(stat.sessionCount)回")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

// MARK: - タグ詳細カード
struct TagDetailCard: View {
    let tag: String
    let stats: EffortStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("#\(tag)")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                StatItem(
                    title: "総時間",
                    value: stats.formattedTotalDuration,
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatItem(
                    title: "平均時間",
                    value: stats.formattedAverageDuration,
                    icon: "timer",
                    color: .green
                )
                
                StatItem(
                    title: "セッション数",
                    value: "\(stats.sessionCount)回",
                    icon: "number.circle.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - 統計項目
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - タグトグルボタン
struct TagToggleButton: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("#\(tag)")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(16)
        }
    }
}

#Preview {
    StatsView(viewModel: AppViewModel())
} 