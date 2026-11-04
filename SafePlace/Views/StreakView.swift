import SwiftUI

/// El detalle de la racha: una tarjeta centrada sobre el papel atenuado.
///
/// No inventa color ni curvas: la llama usa el loop `flame` del contrato y la
/// entrada/salida, los springs compartidos. Con Reduce Motion la tarjeta
/// aparece sin escala y la llama queda quieta.
struct StreakView: View {
    @ObservedObject var store: Store
    var onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var titleFocused: Bool
    @State private var appeared = false

    private var streak: Int { NoteStats.currentStreak(store.entries) }
    private var goal: NoteStats.StreakGoal { NoteStats.streakGoal(for: streak) }
    private var week: [NoteStats.StreakDay] { NoteStats.weekSnapshot(store.entries) }

    /// La racha conserva su identidad cálida: el pastel del mood "Con energía",
    /// el mismo de la llama de Home, en vez del tinte cambiante del resto.
    private var streakTint: Color { Mood.bright.color }
    private var streakTintStrong: Color { Mood.bright.deepColor }

    var body: some View {
        ZStack {
            scrim
            card
                .padding(.horizontal, SafeDesign.l)
                .padding(.vertical, SafeDesign.l)
                .scaleEffect(appeared || reduceMotion ? 1 : 0.94)
                .opacity(appeared || reduceMotion ? 1 : 0)
        }
        .onAppear {
            guard !reduceMotion else {
                appeared = true
                return
            }
            withAnimation(SafeMotion.bouncy) { appeared = true }
        }
        .task {
            // El foco llega después del movimiento, para no pelearse con él.
            try? await Task.sleep(nanoseconds: 350_000_000)
            titleFocused = true
        }
    }

    // MARK: - Scrim

    private var scrim: some View {
        Color.black.opacity(0.24)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { close() }
            .accessibilityHidden(true)
    }

    // MARK: - Card

    private var card: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                flameHero

                VStack(spacing: SafeDesign.xs) {
                    Text("Your streak")
                        .font(SafeDesign.serifHero)
                        .foregroundStyle(SafeDesign.ink)
                        .multilineTextAlignment(.center)
                        .accessibilityFocused($titleFocused)
                    Text("Consecutive days checking in")
                        .font(SafeDesign.caption)
                        .foregroundStyle(SafeDesign.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, SafeDesign.m)

                streakNumber
                    .padding(.top, SafeDesign.l)

                if dynamicTypeSize.isAccessibilitySize {
                    accessibleWeek
                } else {
                    weekRow
                }

                goalPanel
                    .padding(.top, SafeDesign.xl)
            }
            .padding(.horizontal, SafeDesign.l)
            .padding(.top, SafeDesign.xxl + SafeDesign.s)
            .padding(.bottom, SafeDesign.xl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: 400)
        .frame(maxHeight: 660)
        .background(
            SafeDesign.surfaceCard,
            in: RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous)
                .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
        }
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(SafeDesign.m)
        }
        .shadow(color: .black.opacity(0.16), radius: 28, y: 12)
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape) { close() }
    }

    private var closeButton: some View {
        Button {
            close()
        } label: {
            Image(systemName: "xmark")
                .font(SafeDesign.scaled(14, weight: .semibold, cappedAt: 18))
                .foregroundStyle(SafeDesign.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(SafeDesign.surfaceSoft))
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.92)
        .accessibilityLabel("Close")
        .accessibilityIdentifier("streak-close")
    }

    // MARK: - Hero

    private var flameHero: some View {
        ZStack {
            Circle()
                .fill(streakTint.opacity(0.10))
                .frame(width: 164, height: 164)
            Circle()
                .fill(streakTint.opacity(0.18))
                .frame(width: 122, height: 122)
            Circle()
                .fill(streakTint.opacity(0.30))
                .frame(width: 84, height: 84)
            StreakFlameGlyph(size: 40, active: streak > 0, color: streakTintStrong)
        }
        .frame(height: 168)
        .accessibilityHidden(true)
    }

    // MARK: - Number

    private var streakNumber: some View {
        VStack(spacing: 0) {
            Text("\(streak)")
                .font(SafeDesign.scaled(56, weight: .semibold, design: .serif).monospacedDigit())
                .foregroundStyle(SafeDesign.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("days in a row")
                .font(SafeDesign.caption)
                .foregroundStyle(SafeDesign.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SafeDesign.m)
        .background(
            streakTint.opacity(0.32),
            in: RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(streak) days in a row"))
    }

    // MARK: - Week

    private var weekRow: some View {
        HStack(spacing: SafeDesign.xxs) {
            ForEach(week) { day in
                VStack(spacing: SafeDesign.xs) {
                    Text(shortWeekday(day.date))
                        .font(SafeDesign.scaled(11, weight: .medium))
                        .foregroundStyle(day.isToday ? SafeDesign.ink : SafeDesign.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    dayMark(day, size: 32)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(dayAccessibilityLabel(day))
            }
        }
        .padding(.top, SafeDesign.xl)
    }

    /// A tamaño de accesibilidad siete columnas ya no caben: la semana se lee
    /// como una lista, con el día completo y el estado en palabras.
    private var accessibleWeek: some View {
        VStack(spacing: 0) {
            ForEach(week) { day in
                HStack(spacing: SafeDesign.s) {
                    Text(fullWeekday(day.date))
                        .font(SafeDesign.body)
                        .foregroundStyle(day.isToday ? SafeDesign.ink : SafeDesign.inkSecondary)
                    Spacer(minLength: SafeDesign.xs)
                    Label(dayStatus(day), systemImage: dayStatusIcon(day))
                        .font(SafeDesign.caption)
                        .foregroundStyle(day.state == .done ? streakTintStrong : SafeDesign.muted)
                }
                .frame(minHeight: minTouchTarget)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(dayAccessibilityLabel(day))
                if day.id != week.last?.id { Hairline() }
            }
        }
        .padding(.top, SafeDesign.l)
    }

    private func dayMark(_ day: NoteStats.StreakDay, size: CGFloat) -> some View {
        ZStack {
            switch day.state {
            case .done:
                Circle().fill(streakTint)
                Image(systemName: "checkmark")
                    .font(SafeDesign.scaled(12, weight: .bold, cappedAt: 18))
                    .foregroundStyle(SafeDesign.inkOnFill)
            case .missed:
                Circle().fill(SafeDesign.surfaceSoft)
            case .upcoming:
                Circle().strokeBorder(SafeDesign.hairline, lineWidth: 1)
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if day.isToday {
                Circle()
                    .strokeBorder(SafeDesign.ink.opacity(0.45), lineWidth: 1.5)
                    .padding(-4)
            }
        }
    }

    private func shortWeekday(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated)).capitalized
    }

    private func fullWeekday(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide)).capitalized
    }

    private func dayStatus(_ day: NoteStats.StreakDay) -> String {
        switch day.state {
        case .done: return String(localized: "Checked in")
        case .missed: return String(localized: "No note")
        case .upcoming: return String(localized: "Not yet")
        }
    }

    private func dayStatusIcon(_ day: NoteStats.StreakDay) -> String {
        switch day.state {
        case .done: return "checkmark.circle.fill"
        case .missed: return "circle"
        case .upcoming: return "circle.dashed"
        }
    }

    /// "Hoy, lunes, con nota": el estado nunca depende solo del color.
    private func dayAccessibilityLabel(_ day: NoteStats.StreakDay) -> String {
        let weekday = fullWeekday(day.date)
        let status = dayStatus(day)
        return day.isToday
            ? "\(String(localized: "Today")), \(weekday), \(status)"
            : "\(weekday), \(status)"
    }

    // MARK: - Goal

    private var goalPanel: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: SafeDesign.m) {
                    goalMessageBlock
                    goalProgress
                }
            } else {
                HStack(alignment: .center, spacing: SafeDesign.m) {
                    goalMessageBlock
                    goalProgress
                        .frame(width: 112)
                }
            }
        }
        .padding(SafeDesign.m)
        .background(
            SafeDesign.surfaceSoft,
            in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous)
                .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
        }
    }

    private var goalMessageBlock: some View {
        HStack(alignment: .top, spacing: SafeDesign.s) {
            ZStack {
                Circle()
                    .fill(streakTint.opacity(0.38))
                    .frame(width: 32, height: 32)
                Image(systemName: "flame.fill")
                    .font(SafeDesign.scaled(13, weight: .semibold, cappedAt: 18))
                    .foregroundStyle(streakTintStrong)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(streak == 0 ? String(localized: "Your first goal") : String(localized: "Keep it going!"))
                    .font(SafeDesign.body)
                    .foregroundStyle(SafeDesign.ink)
                Text(goalMessage)
                    .font(SafeDesign.scaled(12))
                    .foregroundStyle(SafeDesign.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var goalProgress: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(String(localized: "\(streak) / \(goal.target) days"))
                .font(SafeDesign.scaled(11, weight: .medium).monospacedDigit())
                .foregroundStyle(SafeDesign.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(SafeDesign.surfaceStrong)
                    Capsule()
                        .fill(streakTintStrong)
                        .frame(width: max(0, geo.size.width * goal.progress))
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(streak) of \(goal.target) days"))
    }

    private var goalMessage: String {
        if streak == 0 {
            return String(localized: "A note today starts your streak.")
        }
        if goal.remaining == 0 {
            return String(localized: "A year of showing up. Keep going.")
        }
        return String(localized: "You're \(NoteStats.daysLabel(goal.remaining)) from your next goal.")
    }

    // MARK: - Actions

    private func close() {
        Haptics.tap()
        onClose()
    }
}

// MARK: - Flame

/// La llama de la racha, compartida por la fila de Home y el héroe del modal.
/// Loop `flame` del contrato: escala 0.92↔1.08 anclada abajo, ±0.5 pt de deriva
/// y opacidad 0.86↔1. Con Reduce Motion, o sin racha, queda quieta.
struct StreakFlameGlyph: View {
    var size: CGFloat = 12
    var active: Bool = true
    var color: Color = SafeDesign.ink

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flicker = false

    var body: some View {
        Image(systemName: active ? "flame.fill" : "flame")
            // Arte decorativo: crece como mucho un 40 % y así nunca se sale de
            // su círculo (22 pt en Home, 84 pt en el héroe del modal).
            .font(SafeDesign.scaled(size, weight: .semibold, cappedAt: size * 1.4))
            .foregroundStyle(active ? color : SafeDesign.muted)
            .scaleEffect(flicker ? 1.08 : 0.92, anchor: .bottom)
            .offset(y: flicker ? -0.5 : 0.5)
            .opacity(flicker ? 1 : 0.86)
            .animation(active && !reduceMotion ? SafeMotion.flame : .default, value: flicker)
            .onAppear {
                guard active, !reduceMotion else { return }
                flicker = true
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        SafeDesign.canvas.ignoresSafeArea()
        StreakView(store: Store()) {}
    }
}
