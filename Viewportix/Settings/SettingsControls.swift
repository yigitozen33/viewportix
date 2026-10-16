import AppKit
import DesignSystem
import SwiftUI

/// Settings switch: yellow track with a dark knob when on, `surface/pill` with a grey knob when off.
struct ChromeToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        StyledToggle(configuration: configuration)
    }

    private struct StyledToggle: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            Button {
                withAnimation(.easeInOut(duration: DesignTokens.Motion.standard)) { configuration.isOn.toggle() }
            } label: {
                Capsule()
                    .fill(configuration.isOn ? DesignTokens.Color.accent : DesignTokens.Color.surfacePill)
                    .frame(width: 30, height: 18)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(configuration.isOn ? DesignTokens.Color.accentInk : DesignTokens.Color.inkSecondary)
                            .frame(width: 14, height: 14)
                            .padding(2)
                    }
                    .opacity(isEnabled ? 1 : 0.4)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .chromeFocusRing(cornerRadius: 9)
            .accessibilityValue(configuration.isOn ? "Açık" : "Kapalı")
        }
    }
}

/// A select box (value + chevron) that opens an AppKit menu under itself.
struct ChromeSelect: View {
    struct Option {
        let title: String
        var isSelected = false
        var isEnabled = true
        let action: () -> Void
    }

    let value: String
    let options: () -> [Option]
    var minWidth: CGFloat = 140

    @State private var anchor = MenuAnchor()
    @State private var isOpen = false

    var body: some View {
        Button {
            isOpen = true
            DispatchQueue.main.async {
                let menu = NSMenu()
                menu.autoenablesItems = false
                for option in options() {
                    if option.title == "-" {
                        menu.addItem(.separator())
                    } else {
                        menu.addItem(ActionMenuItem(option.title, isChecked: option.isSelected, isEnabled: option.isEnabled, action: option.action))
                    }
                }
                anchor.popUpBelow(menu, gap: DesignTokens.Space.s1)
                isOpen = false
            }
        } label: {
            HStack(spacing: DesignTokens.Space.s2) {
                Text(value)
                    .font(.system(size: DesignTokens.FontSize.label))
                    .foregroundStyle(DesignTokens.Color.inkPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ChromeSymbol("chevron.down", box: 12).foregroundStyle(DesignTokens.Color.inkSecondary)
            }
            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 8))
            .frame(minWidth: minWidth, maxWidth: 170)
            .background(isOpen ? DesignTokens.Color.surfaceHeaderLeader : DesignTokens.Color.surfaceCard,
                        in: .rect(cornerRadius: DesignTokens.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control).strokeBorder(DesignTokens.Color.line, lineWidth: DesignTokens.Stroke.hairline)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background(alignment: .bottomLeading) { MenuAnchorView(anchor: anchor).frame(width: 0, height: 0) }
        .chromeFocusRing(cornerRadius: DesignTokens.Radius.control)
        .accessibilityValue(value)
    }
}

/// Small segmented control (Ölçek 1× / 2×, device type filter).
struct ChromeSegments<Value: Hashable>: View {
    let items: [(Value, String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 1) {
            ForEach(items, id: \.0) { value, title in
                Button {
                    withAnimation(.easeInOut(duration: DesignTokens.Motion.standard)) { selection = value }
                } label: {
                    Text(title)
                        .font(.system(size: DesignTokens.FontSize.caption))
                        .foregroundStyle(selection == value ? DesignTokens.Color.inkPrimary : DesignTokens.Color.inkSecondary)
                        .padding(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                        .background(selection == value ? DesignTokens.Color.surfaceHeaderLeader : DesignTokens.Color.surfaceCard)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == value ? .isSelected : [])
            }
        }
        .background(DesignTokens.Color.line)
        .clipShape(.rect(cornerRadius: DesignTokens.Radius.badge))
    }
}
