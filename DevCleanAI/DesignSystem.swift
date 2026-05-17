import SwiftUI

// MARK: ─────────────────────────────────────────────────────────────────────
// DESIGN SYSTEM  –  DevClean AI  –  OLED Dark + Liquid Glass Pro
// ─────────────────────────────────────────────────────────────────────────────

// MARK: - Palette
public extension Color {
    /// Initialize a dynamic color that automatically updates based on the current macOS appearance
    init(light: Color, dark: Color) {
        self.init(NSColor(name: nil, dynamicProvider: { appearance in
            if appearance.name == .darkAqua || appearance.name == .vibrantDark {
                return NSColor(dark)
            } else {
                return NSColor(light)
            }
        }))
    }

    // Dynamic Semantic Colors
    static let dcBackground  = Color(light: Color(hex: "#F8FAFC"), dark: Color(hex: "#020617"))
    static let dcSurface     = Color(light: .white, dark: Color(hex: "#0F172A"))
    static let dcSurface2    = Color(light: Color(hex: "#F1F5F9"), dark: Color(hex: "#1E293B"))
    static let dcBorder      = Color(light: Color.black.opacity(0.08), dark: Color.white.opacity(0.07))
    static let dcText        = Color(light: Color(hex: "#0F172A"), dark: Color(hex: "#F1F5F9"))
    static let dcSubtext     = Color(light: Color(hex: "#64748B"), dark: Color(hex: "#64748B"))
    
    // Dynamic Overlays for cards and borders
    static let dcOverlay     = Color(light: Color.black.opacity(0.03), dark: Color.white.opacity(0.04))
    static let dcOverlayLine = Color(light: Color.black.opacity(0.06), dark: Color.white.opacity(0.06))
    
    // Dynamic Accents (Slightly darker in light mode for better contrast against white)
    static let dcPurple      = Color(light: Color(hex: "#6D28D9"), dark: Color(hex: "#7C3AED"))
    static let dcBlue        = Color(light: Color(hex: "#1D4ED8"), dark: Color(hex: "#2563EB"))
    static let dcGreen       = Color(light: Color(hex: "#15803D"), dark: Color(hex: "#22C55E"))
    static let dcOrange      = Color(light: Color(hex: "#D97706"), dark: Color(hex: "#F59E0B"))
    static let dcRed         = Color(light: Color(hex: "#B91C1C"), dark: Color(hex: "#F87171"))
    static let dcCyan        = Color(light: Color(hex: "#0E7490"), dark: Color(hex: "#22D3EE"))
}

public extension ShapeStyle where Self == Color {
    static var dcBackground: Color { Color.dcBackground }
    static var dcSurface: Color { Color.dcSurface }
    static var dcSurface2: Color { Color.dcSurface2 }
    static var dcBorder: Color { Color.dcBorder }
    static var dcText: Color { Color.dcText }
    static var dcSubtext: Color { Color.dcSubtext }
    static var dcOverlay: Color { Color.dcOverlay }
    static var dcOverlayLine: Color { Color.dcOverlayLine }
    static var dcPurple: Color { Color.dcPurple }
    static var dcBlue: Color { Color.dcBlue }
    static var dcGreen: Color { Color.dcGreen }
    static var dcOrange: Color { Color.dcOrange }
    static var dcRed: Color { Color.dcRed }
    static var dcCyan: Color { Color.dcCyan }
}
