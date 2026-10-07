import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @AppStorage("themeMode") private var themeRaw = ThemeMode.system.rawValue
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 21
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("mascotColorHex") private var mascotColorHex = MascotColorOption.peach.rawValue

    @State private var exportURL: URL?
    @State private var showImporter = false
    @State private var showEraseConfirm = false
    @State private var importMessage: String?

    private var theme: ThemeMode { ThemeMode(rawValue: themeRaw) ?? .system }
    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    private var reminderDate: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents(); c.hour = reminderHour; c.minute = reminderMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { newValue in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = c.hour ?? 21
                reminderMinute = c.minute ?? 0
                if reminderEnabled { Reminders.scheduleDaily(hour: reminderHour, minute: reminderMinute) }
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: SafeDesign.xl) {
                    SheetHeader(title: "Settings", subtitle: "Make SafePlace feel like yours.", onClose: { dismiss() })

                    appearanceSection
                    characterSection
                    remindersSection
                    dataSection
                    aboutSection
                }
                .padding(.horizontal, SafeDesign.l)
                .padding(.bottom, SafeDesign.xxl)
            }
            .background(SafeDesign.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear { exportURL = makeExportFile() }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
        .alert("Erase all data?", isPresented: $showEraseConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Erase", role: .destructive) {
                store.eraseAll()
                Haptics.warning()
                exportURL = makeExportFile()
            }
        } message: {
            Text("This removes every note and saved item from this device. It can't be undone.")
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        SettingsCard(title: "Appearance", icon: "paintbrush") {
            HStack(spacing: SafeDesign.xs) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    SelectionPill(title: mode.label, icon: mode.icon, isSelected: theme == mode) {
                        Haptics.selection()
                        withAnimation(SafeDesign.spring) { themeRaw = mode.rawValue }
                    }
                }
            }
        }
    }

    private var characterSection: some View {
        SettingsCard(title: "Your character", icon: "face.smiling") {
            VStack(spacing: SafeDesign.m) {
                MascotView(color: Color(hex: mascotColorHex), size: 120, animate: true)
                    .frame(height: 130)
                HStack(spacing: SafeDesign.s) {
                    ForEach(MascotColorOption.allCases) { option in
                        Button {
                            Haptics.selection()
                            withAnimation(SafeDesign.spring) { mascotColorHex = option.rawValue }
                        } label: {
                            Circle()
                                .fill(option.color)
                                .frame(width: 34, height: 34)
                                .overlay {
                                    Circle().strokeBorder(mascotColorHex == option.rawValue ? SafeDesign.ink : SafeDesign.hairline, lineWidth: 2)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var remindersSection: some View {
        SettingsCard(title: "Daily reminder", icon: "bell") {
            VStack(alignment: .leading, spacing: SafeDesign.m) {
                Toggle(isOn: Binding(
                    get: { reminderEnabled },
                    set: { on in
                        reminderEnabled = on
                        Haptics.selection()
                        if on {
                            Task {
                                let ok = await Reminders.requestAuthorization()
                                if ok { Reminders.scheduleDaily(hour: reminderHour, minute: reminderMinute) }
                                else { reminderEnabled = false }
                            }
                        } else {
                            Reminders.cancel()
                        }
                    }
                )) {
                    Text("A gentle nudge to check in")
                        .font(SafeDesign.body)
                        .foregroundStyle(SafeDesign.ink)
                }
                .tint(SafeDesign.accentDeep)

                if reminderEnabled {
                    DatePicker("Time", selection: reminderDate, displayedComponents: .hourAndMinute)
                        .font(SafeDesign.body)
                        .foregroundStyle(SafeDesign.ink)
                        .tint(SafeDesign.accentDeep)
                }
            }
        }
    }

    private var dataSection: some View {
        SettingsCard(title: "Your data", icon: "externaldrive") {
            VStack(spacing: SafeDesign.s) {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        settingsRowLabel(title: "Export backup", icon: "square.and.arrow.up", tint: SafeDesign.accentDeep)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    showImporter = true
                } label: {
                    settingsRowLabel(title: "Import backup", icon: "square.and.arrow.down", tint: SafeDesign.accentDeep)
                }
                .buttonStyle(.plain)

                if let importMessage {
                    Text(importMessage)
                        .font(SafeDesign.caption)
                        .foregroundStyle(SafeDesign.inkSecondary)
                }

                Divider().overlay(SafeDesign.hairline)

                Button {
                    showEraseConfirm = true
                } label: {
                    settingsRowLabel(title: "Erase all data", icon: "trash", tint: SafeDesign.error)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var aboutSection: some View {
        SettingsCard(title: "About", icon: "info.circle") {
            VStack(alignment: .leading, spacing: SafeDesign.s) {
                HStack {
                    Text("Version")
                        .font(SafeDesign.body)
                        .foregroundStyle(SafeDesign.inkSecondary)
                    Spacer()
                    Text(version)
                        .font(SafeDesign.body)
                        .foregroundStyle(SafeDesign.ink)
                }
                Link(destination: URL(string: "https://hihirams.github.io/SafePlace-App/source.json")!) {
                    HStack {
                        Text("Update feed (LiveContainer)")
                            .font(SafeDesign.body)
                            .foregroundStyle(SafeDesign.accentDeep)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SafeDesign.accentDeep)
                    }
                }
                Text("Built with care. Your notes stay on your device.")
                    .font(SafeDesign.caption)
                    .foregroundStyle(SafeDesign.muted)
            }
        }
    }

    // MARK: - Helpers

    private func settingsRowLabel(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: SafeDesign.m) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22)
            Text(title)
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.ink)
            Spacer()
        }
        .contentShape(Rectangle())
    }

    private func makeExportFile() -> URL? {
        guard let data = store.exportJSON() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SafePlace-Backup.json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url), store.importJSON(data) {
                importMessage = "Backup restored."
                Haptics.success()
                exportURL = makeExportFile()
            } else {
                importMessage = "That file couldn't be read."
                Haptics.warning()
            }
        case .failure:
            importMessage = "Import cancelled."
        }
    }
}

// MARK: - Settings building blocks

private struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: SafeDesign.m) {
            Label(title, systemImage: icon)
                .font(SafeDesign.headline)
                .foregroundStyle(SafeDesign.ink)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SafeDesign.l)
        .background(SafeDesign.surfaceSoft, in: RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous)
                .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
        }
    }
}

#Preview {
    SettingsView(store: Store())
}
