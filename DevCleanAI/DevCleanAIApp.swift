import SwiftUI

@main
struct DevCleanAIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1100, minHeight: 700)
                .preferredColorScheme(appTheme.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .commands { CommandGroup(replacing: .newItem) {} }
        MenuBarExtra("CleanYourMac", systemImage: "sparkles.rectangle.stack") {
            MenuBarView().environmentObject(appState)
                .preferredColorScheme(appTheme.colorScheme)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    
    @MainActor @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        // Try to find the main ContentView window (usually the largest one)
        let mainWindow = NSApp.windows.filter { $0.canBecomeKey && !($0 is NSPanel) }
            .sorted { $0.frame.width > $1.frame.width }
            .first
        
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else {
            // Fallback: If no window found, try to trigger a new one via the standard selector
            NSApp.sendAction(#selector(NSWindow.makeKeyAndOrderFront(_:)), to: nil, from: nil)
        }
    }
}
