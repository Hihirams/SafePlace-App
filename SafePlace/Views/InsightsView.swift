import SwiftUI
import Charts

/// Gentle, observational insights — patterns, never pressure.
struct InsightsView: View {
    @ObservedObject var store: Store
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v
    @Environment(\.appTheme) private var theme

    private var last14Days: [NoteStats.DayCount] { NoteStats.last14Days(store.entries) }

    private var moodCounts: [NoteStats.MoodCount] { NoteStats.moodCounts(store.entries) }

    private var categoryCounts: [NoteStats.CategoryCount] {
        Array(NoteStats.categoryCounts(store.entries, categories: store.categories).prefix(6))
    }

    private var topKeywords: [String] { NoteStats.topKeywords(store.entries) }

    private var personalBest: Int { NoteStats.personalBest(store.entries) }

    var body: some View {
        VStack(alignment: .leading, spacing: SafeDesign.l) {
            if store.entries.isEmpty {
                emptyState
            } else {
                summaryRow
                Hairline()
                activityChart
                if !moodCounts.isEmpty {
                    Hairline()
                    moodSection
                }
                if !categoryCounts.isEmpty {
                    Hairline()
                    categorySection
                }
                if !topKeywords.isEmpty {
                    Hairline()
                    keywordsSection
                }
            }
        }
    }

    /// Una línea, no una tira de tarjetas de métricas (la skill lo prohíbe).
    private var summaryRow: some View {
        Text(String(localized: "\(store.entries.count) notes · \(store.categories.count) categories · best run \(personalBest)"))
            .font(SafeDesign.caption)
            .foregroundStyle(SafeDesign.inkSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var activityChart: some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            Text("Last 14 days")
                .font(SafeDesign.headline)
                .foregroundStyle(SafeDesign.ink)
            Chart(last14Days) { item in
                BarMark(
                    x: .value(String(localized: "Day"), item.date, unit: .day),
                    y: .value(String(localized: "notes"), item.count)
                )
                .foregroundStyle(theme.tintStrong.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(SafeDesign.hairline)
                    AxisValueLabel().foregroundStyle(SafeDesign.muted)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisValueLabel(format: .dateTime.day()).foregroundStyle(SafeDesign.muted)
                }
            }
            .frame(height: 150)
            .accessibilityLabel("Notes per day over the last 14 days")
        }
        .padding(.vertical, SafeDesign.l)
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            Text("How you've been feeling")
                .font(SafeDesign.headline)
                .foregroundStyle(SafeDesign.ink)
            Chart {
                ForEach(moodCounts) { item in
                    BarMark(
                        x: .value(String(localized: "Count"), item.count),
                        y: .value(String(localized: "Mood"), item.mood.label)
                    )
                    .foregroundStyle(item.mood.color)
                    .cornerRadius(6)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(SafeDesign.scaled(11, weight: .semibold))
                            .foregroundStyle(SafeDesign.muted)
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(SafeDesign.inkSecondary)
                }
            }
            .frame(height: CGFloat(max(moodCounts.count, 1)) * 34)
            .accessibilityLabel("Notes by mood")
        }
        .padding(.vertical, SafeDesign.l)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            Text("Where your notes live")
                .font(SafeDesign.headline)
                .foregroundStyle(SafeDesign.ink)
            ForEach(categoryCounts) { item in
                HStack(spacing: SafeDesign.xs) {
                    Text(item.name)
                        .font(SafeDesign.scaled(12, weight: .medium))
                        .foregroundStyle(SafeDesign.inkSecondary)
                        .frame(width: 90, alignment: .leading)
                        .lineLimit(1)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(SafeDesign.surfaceStrong)
                            Capsule().fill(theme.tintStrong)
                                .frame(width: geo.size.width * fraction(item.count))
                        }
                    }
                    .frame(height: 8)
                    Text("\(item.count)")
                        .font(SafeDesign.scaled(12, weight: .medium))
                        .foregroundStyle(SafeDesign.muted)
                        .frame(width: 22, alignment: .trailing)
                }
            }
        }
        .padding(.vertical, SafeDesign.l)
    }

    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            Text("Words that show up often")
                .font(SafeDesign.headline)
                .foregroundStyle(SafeDesign.ink)
            FlowLayout(spacing: SafeDesign.xs) {
                ForEach(topKeywords, id: \.self) { word in
                    Text(word)
                        .font(SafeDesign.caption)
                        .foregroundStyle(SafeDesign.ink)
                        .padding(.horizontal, SafeDesign.s)
                        .padding(.vertical, 6)
                        .background(SafeDesign.surfaceStrong, in: Capsule())
                }
            }
        }
        .padding(.vertical, SafeDesign.l)
    }

    private func fraction(_ count: Int) -> CGFloat {
        let maxCount = categoryCounts.map(\.count).max() ?? 1
        return CGFloat(count) / CGFloat(max(maxCount, 1))
    }

    private var emptyState: some View {
        VStack(spacing: SafeDesign.s) {
            Image(systemName: "chart.bar.xaxis")
                .font(SafeDesign.scaled(34, weight: .light))
                .foregroundStyle(SafeDesign.muted)
            Text("Insights appear as you save.")
                .font(SafeDesign.headline)
                .foregroundStyle(SafeDesign.ink)
            Text("Add a few notes and this space will quietly show your patterns.")
                .font(SafeDesign.caption)
                .foregroundStyle(SafeDesign.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SafeDesign.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SafeDesign.xxl)
    }
}

/// Simple wrapping layout for tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [CGFloat] = [0]
        var current: CGFloat = 0
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if current + size.width > maxWidth, current > 0 {
                height += rowHeight + spacing
                rows.append(0)
                current = 0
                rowHeight = 0
            }
            current += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: maxWidth == .infinity ? current : maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    ScrollView { InsightsView(store: Store()).padding() }
}
