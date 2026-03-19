import AppIntents

struct StartTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start TomatoBar Pro Timer"
    static var description = IntentDescription("Starts a new pomodoro work session")

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            TBTimer.shared?.startStop()
        }
        return .result()
    }
}

struct StopTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop TomatoBar Pro Timer"
    static var description = IntentDescription("Stops the current pomodoro session")

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            if TBTimer.shared?.isRunning == true {
                TBTimer.shared?.startStop()
            }
        }
        return .result()
    }
}

struct PauseResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause/Resume TomatoBar Pro Timer"
    static var description = IntentDescription("Pauses or resumes the current pomodoro session")

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            TBTimer.shared?.pauseResume()
        }
        return .result()
    }
}

struct TomatoBarProShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: ["Start \(.applicationName) timer"],
            shortTitle: "Start Timer",
            systemImageName: "timer"
        )
    }
}
