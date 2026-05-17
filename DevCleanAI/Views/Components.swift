import SwiftUI

// MARK: - Premium Toggle Row
struct PremiumToggleRow: View {
    let label: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let accent: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dcText)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.dcSubtext)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: accent))
                .labelsHidden()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    let accent: Color
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(configuration.isOn ? accent : .dcSubtext.opacity(0.3))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Row Divider
struct RowDivider: View {
    var body: some View {
        Divider()
            .background(Color.dcOverlayLine)
            .padding(.horizontal, 16)
    }
}

// MARK: - Premium Button Style
struct PremiumButtonStyle: ButtonStyle {
    let accent: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
