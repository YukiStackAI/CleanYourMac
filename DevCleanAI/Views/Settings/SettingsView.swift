import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("scanOnLaunch") var scanOnLaunch = false
    @AppStorage("showMenuBarExtra") var showMenuBarExtra = true
    @AppStorage("weeklyReport") var weeklyReport = true
    @AppStorage("claudeAPIKey") var claudeAPIKey = ""
    @AppStorage("appTheme") var appTheme: AppTheme = .system
    @AppStorage("advancedScanning") var advancedScanning = false

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(
                icon: "gearshape.fill",
                title: "Settings",
                subtitle: "Manage your preferences and personalize the application experience",
                accent: appState.selectedSection.themeColor
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Visual Experience ──────────────────────
                    SettingsSection(title: "Visual Experience", icon: "paintbrush.fill", accent: appState.selectedSection.themeColor) {
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Application Theme").font(.system(size: 13, weight: .bold)).foregroundStyle(Color.dcText)
                                    Text("Switch between Light, Dark, or System appearances").font(.system(size: 11)).foregroundStyle(.dcSubtext)
                                }
                                Spacer()
                                Picker("", selection: $appTheme) {
                                    Text("System").tag(AppTheme.system)
                                    Text("Light").tag(AppTheme.light)
                                    Text("Dark").tag(AppTheme.dark)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 200)
                            }
                            .padding(.vertical, 16)
                            
                            Divider().background(Color.dcOverlayLine)
                            
                            PremiumToggleRow(
                                label: "Show Menu Bar Extra",
                                subtitle: "Access quick cleaning tools directly from your menu bar",
                                icon: "menubar.arrow.up.rectangle",
                                iconColor: .dcCyan,
                                accent: appState.selectedSection.themeColor,
                                isOn: $showMenuBarExtra
                            )
                        }
                        .padding(.horizontal, 20)
                    }

                    // ── Cleaning & Performance ──────────────────
                    SettingsSection(title: "Cleaning & Performance", icon: "bolt.fill", accent: appState.selectedSection.themeColor) {
                        VStack(spacing: 0) {
                            PremiumToggleRow(
                                label: "Auto-scan on Launch",
                                subtitle: "Automatically begin system analysis when the app opens",
                                icon: "clock.arrow.circlepath",
                                iconColor: .dcGreen,
                                accent: appState.selectedSection.themeColor,
                                isOn: $scanOnLaunch
                            )
                            
                            Divider().background(Color.dcOverlayLine)
                            
                            PremiumToggleRow(
                                label: "Advanced Deep Scanning",
                                subtitle: "Enable more thorough searching for system-wide leftovers (may take longer)",
                                icon: "magnifyingglass",
                                iconColor: .dcGreen,
                                accent: appState.selectedSection.themeColor,
                                isOn: $advancedScanning
                            )
                            
                            Divider().background(Color.dcOverlayLine)
                            
                            PremiumToggleRow(
                                label: "Weekly Health Reports",
                                subtitle: "Get a summary of your system health and space saved",
                                icon: "chart.bar.doc.horizontal.fill",
                                iconColor: .dcOrange,
                                accent: appState.selectedSection.themeColor,
                                isOn: $weeklyReport
                            )
                        }
                        .padding(.horizontal, 20)
                    }

                    // ── Intelligence ──────────────────────────
                    SettingsSection(title: "Intelligence", icon: "brain.head.profile.fill", accent: appState.selectedSection.themeColor) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10).fill(Color.dcCyan.opacity(0.12)).frame(width: 40, height: 40)
                                    Image(systemName: "cpu").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.dcCyan)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Apple Silicon Neural Engine").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.dcText)
                                    Text("Active & optimized for M1/M2/M3 chips").font(.system(size: 11)).foregroundStyle(.dcSubtext)
                                }
                                Spacer()
                                HStack(spacing: 8) {
                                    Circle().fill(Color.dcGreen).frame(width: 8, height: 8).shadow(color: Color.dcGreen, radius: 4)
                                    Text("ENABLED").font(.system(size: 10, weight: .black)).foregroundStyle(Color.dcGreen).kerning(1)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color.dcGreen.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(20)
                    }

                    // ── About ──────────────────────────────────
                    SettingsSection(title: "About CleanYourMac", icon: "info.circle.fill", accent: appState.selectedSection.themeColor) {
                        VStack(spacing: 0) {
                            SettingsMetaRow(label: "Product Version", value: "2.0.1 (Platinum)")
                            Divider().background(Color.dcOverlayLine).padding(.horizontal, 20)
                            SettingsMetaRow(label: "Build Signature", value: "2025.05.16.MAC")
                            Divider().background(Color.dcOverlayLine).padding(.horizontal, 20)
                            SettingsMetaRow(label: "Engine Status", value: "Optimized", valueColor: .dcGreen)
                        }
                    }
                }
                .padding(24)
                .padding(.bottom, 40)
            }
        }
        .background(Color.dcBackground)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let accent: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(accent)
                Text(title.uppercased()).font(.system(size: 11, weight: .black)).foregroundStyle(.dcSubtext).kerning(1.2)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.dcSurface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.dcOverlayLine, lineWidth: 0.5))
        }
    }
}

private struct SettingsMetaRow: View {
    let label: String
    let value: String
    var valueColor: Color = .dcText

    var body: some View {
        HStack {
            Text(label).font(.system(size: 13, weight: .medium)).foregroundStyle(.dcSubtext)
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold)).foregroundStyle(valueColor)
        }
        .padding(20)
    }
}
