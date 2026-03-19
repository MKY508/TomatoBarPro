import LaunchAtLogin
import SwiftUI

@main
struct TomatoBarProApp: App {
    @StateObject private var timer = TBTimer()

    init() {
        LaunchAtLogin.migrateIfNeeded()
        logger.append(event: TBLogEventAppStart())
    }

    var body: some Scene {
        MenuBarExtra {
            TBPopoverView()
                .environmentObject(timer)
                .environmentObject(timer.player)
        } label: {
            HStack(spacing: 4) {
                Image(timer.menuBarIconName)
                if timer.showTimerInMenuBar, let timeStr = timer.displayTime {
                    Text(timeStr).monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
