import SwiftUI

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    private let features: [OnboardingFeature] = [
        OnboardingFeature(
            icon: "leaf.fill",
            title: "Collect what helped",
            subtitle: "A quiet home for the small wins, habits, people and places that gently carried you forward."
        ),
        OnboardingFeature(
            icon: "book.fill",
            title: "Remember gently",
            subtitle: "Your safe place turns the notes you keep into a soft timeline you can revisit any time you need it."
        ),
        OnboardingFeature(
            icon: "note.text",
            title: "Notes from your iPhone",
            subtitle: "Share text from Apple Notes straight into SafePlace with the iOS share sheet. It lands safely here, ready to keep."
        )
    ]

    private var isLast: Bool { page == features.count - 1 }

    var body: some View {
        ZStack {
            BackgroundOrbs()

            VStack(spacing: 0) {
                // Brand lockup
                HStack(spacing: SafeDesign.s) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SafeDesign.accentDeep)
                    Text("SafePlace")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(SafeDesign.ink)
                }
                .padding(.top, SafeDesign.xl)

                Spacer()

                TabView(selection: $page) {
                    ForEach(features.indices, id: \.self) { i in
                        featureCard(features[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: 360)

                // Dots
                HStack(spacing: SafeDesign.s) {
                    ForEach(features.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? SafeDesign.accentDeep : SafeDesign.hairline)
                            .frame(width: i == page ? 20 : 6, height: 6)
                            .animation(SafeDesign.spring, value: page)
                    }
                }
                .padding(.top, SafeDesign.xl)

                Spacer()

                // Actions
                VStack(spacing: SafeDesign.l) {
                    PrimaryButton(title: isLast ? "Get started" : "Continue", icon: isLast ? nil : "arrow.right") {
                        if isLast {
                            withAnimation(.easeInOut(duration: 0.4)) { hasSeenOnboarding = true }
                        } else {
                            withAnimation(SafeDesign.spring) { page += 1 }
                        }
                    }
                    .padding(.horizontal, SafeDesign.xl)

                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) { hasSeenOnboarding = true }
                    } label: {
                        Text("Skip")
                            .font(SafeDesign.caption)
                            .foregroundStyle(SafeDesign.inkSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, SafeDesign.xxxl)
            }
        }
    }

    private func featureCard(_ feature: OnboardingFeature) -> some View {
        VStack(spacing: SafeDesign.xl) {
            ZStack {
                Circle()
                    .fill(SafeDesign.surfaceCard)
                    .frame(width: 132, height: 132)
                Circle()
                    .strokeBorder(SafeDesign.accentDeep.opacity(0.25), lineWidth: 1)
                    .frame(width: 132, height: 132)
                Image(systemName: feature.icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(SafeDesign.accentDeep)
            }
            .shadow(color: SafeDesign.accentDeep.opacity(0.2), radius: 26, y: 12)

            VStack(spacing: SafeDesign.s) {
                Text(feature.title)
                    .font(SafeDesign.largeTitle)
                    .foregroundStyle(SafeDesign.ink)
                    .multilineTextAlignment(.center)
                Text(feature.subtitle)
                    .font(SafeDesign.body)
                    .foregroundStyle(SafeDesign.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, SafeDesign.xl)
            }
        }
        .padding(.horizontal, SafeDesign.l)
    }
}

#Preview {
    OnboardingView()
}