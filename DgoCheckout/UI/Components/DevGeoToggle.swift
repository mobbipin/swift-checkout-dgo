import SwiftUI

/// Edge tab that expands into the `DEV · GEO / STATE` panel and auto-hides after 4s idle.
struct DevGeoToggle: View {
    let region: PriceRegion
    let subscribed: Bool
    let onRegion: (PriceRegion) -> Void
    let onSubscribed: (Bool) -> Void

    @State private var expanded = false
    @State private var touches = 0

    private static let autoHide: Duration = .seconds(4)

    var body: some View {
        HStack(spacing: 0) {
            if expanded {
                panel.transition(.move(edge: .leading).combined(with: .opacity))
            }
            handle
        }
        .animation(.easeOut(duration: 0.22), value: expanded)
        .task(id: "\(expanded)-\(touches)") {
            guard expanded else { return }
            try? await Task.sleep(for: Self.autoHide)
            if !Task.isCancelled { expanded = false }
        }
    }

    private var handle: some View {
        Button { expanded.toggle() } label: {
            VStack(spacing: 1) {
                Text(expanded ? "‹" : "›").font(.dgo(12, .bold)).foregroundStyle(Color.devLime)
                if !expanded {
                    Text(region.toggleLabel).font(.dgo(9, .bold, mono: true)).foregroundStyle(Color.devLime.opacity(0.9))
                    Text(subscribed ? "SUB" : "OFF").font(.dgo(8, mono: true)).foregroundStyle(Color.devLime.opacity(0.6))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.85))
            .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: 8, topTrailingRadius: 8))
            .overlay(
                UnevenRoundedRectangle(bottomTrailingRadius: 8, topTrailingRadius: 8)
                    .strokeBorder(Color.devLime.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("devHandle")
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(Color.devLime).frame(width: 6, height: 6)
                Text("DEV · GEO / STATE").font(.dgo(10, mono: true)).tracking(0.8).foregroundStyle(Color.devLime.opacity(0.9))
            }
            HStack(spacing: 6) {
                ForEach(PriceRegion.allCases) { option in
                    chip(option.toggleLabel, selected: region == option) { touches += 1; onRegion(option) }
                }
                Rectangle().fill(Color.devLime.opacity(0.25)).frame(width: 1, height: 12)
                chip("OFF", selected: !subscribed) { touches += 1; onSubscribed(false) }
                chip("SUB", selected: subscribed) { touches += 1; onSubscribed(true) }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.85))
        .overlay(Rectangle().strokeBorder(Color.devLime.opacity(0.4), lineWidth: 1))
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.dgo(10, .bold, mono: true)).tracking(0.6)
                .foregroundStyle(selected ? Color.black : Color.devLime.opacity(0.7))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(selected ? Color.devLime : Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dev_\(label)")
    }
}
