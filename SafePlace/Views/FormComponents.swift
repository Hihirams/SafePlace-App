import SwiftUI

// MARK: - Primary button (clay: dark ink capsule)

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SafeDesign.s) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(SafeDesign.headline)
            }
            .foregroundStyle(SafeDesign.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                Capsule().fill(SafeDesign.primary)
            }
        }
        .buttonStyle(.plain)
        .pressable()
    }
}

// MARK: - Secondary button (outlined)

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SafeDesign.s) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(SafeDesign.headline)
            }
            .foregroundStyle(SafeDesign.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .pressable()
    }
}

// MARK: - Text fields

struct ClayTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: SafeDesign.m) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(SafeDesign.muted)
                .frame(width: 18)
            TextField(placeholder, text: $text)
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.ink)
                .tint(SafeDesign.accentDeep)
        }
        .padding(.horizontal, SafeDesign.l)
        .padding(.vertical, SafeDesign.m)
        .background(SafeDesign.surfaceSoft, in: Capsule())
        .overlay { Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1) }
    }
}

struct ClayTextArea: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(SafeDesign.body)
            .foregroundStyle(SafeDesign.ink)
            .tint(SafeDesign.accentDeep)
            .scrollContentBackground(.hidden)
            .padding(SafeDesign.m)
            .frame(minHeight: 110)
            .background(SafeDesign.surfaceSoft, in: RoundedRectangle(cornerRadius: SafeDesign.radiusM, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SafeDesign.radiusM, style: .continuous)
                    .strokeBorder(SafeDesign.hairline, lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(SafeDesign.body)
                        .foregroundStyle(SafeDesign.muted)
                        .padding(SafeDesign.l)
                        .padding(.top, 4)
                }
            }
    }
}

// MARK: - Selection pill

struct SelectionPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SafeDesign.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(SafeDesign.caption)
            }
            .foregroundStyle(isSelected ? SafeDesign.onPrimary : SafeDesign.inkSecondary)
            .padding(.horizontal, SafeDesign.l)
            .padding(.vertical, SafeDesign.s)
            .background {
                if isSelected {
                    Capsule().fill(SafeDesign.primary)
                } else {
                    Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.95)
    }
}

// MARK: - Sheet chrome

struct SheetHeader: View {
    let title: String
    var subtitle: String? = nil
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: SafeDesign.xs) {
            Capsule()
                .fill(SafeDesign.hairline)
                .frame(width: 40, height: 5)
                .padding(.top, SafeDesign.s)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SafeDesign.largeTitle)
                        .foregroundStyle(SafeDesign.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(SafeDesign.caption)
                            .foregroundStyle(SafeDesign.inkSecondary)
                    }
                }
                Spacer()
                GlassIconButton(icon: "xmark", action: onClose)
            }
            .padding(.top, SafeDesign.m)
        }
        .padding(.bottom, SafeDesign.l)
    }
}

// MARK: - Search bar

struct ClaySearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: SafeDesign.m) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(SafeDesign.muted)
            TextField("Search", text: $text)
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.ink)
                .tint(SafeDesign.accentDeep)
        }
        .padding(.horizontal, SafeDesign.l)
        .padding(.vertical, SafeDesign.m)
        .background(SafeDesign.surfaceSoft, in: Capsule())
        .overlay { Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1) }
    }
}