import KeyboardShortcuts
import SwiftUI

class TBTimer: ObservableObject {
    static var shared: TBTimer?

    @AppStorage("stopAfterBreak") var stopAfterBreak = false
    @AppStorage("showTimerInMenuBar") var showTimerInMenuBar = true
    @AppStorage("workIntervalLength") var workIntervalLength = 25
    @AppStorage("shortRestIntervalLength") var shortRestIntervalLength = 5
    @AppStorage("longRestIntervalLength") var longRestIntervalLength = 15
    @AppStorage("workIntervalsInSet") var workIntervalsInSet = 4
    // This preference is "hidden"
    @AppStorage("overrunTimeLimit") var overrunTimeLimit = -60.0
    @AppStorage("countUpTimer") var countUpTimer = false

    public let player = TBPlayer()
    private var consecutiveWorkIntervals: Int = 0
    private var notificationCenter = TBNotificationCenter()
    private var finishTime: Date!
    private var totalDuration: TimeInterval = 0
    private var remainingTime: TimeInterval = 0
    private var timerFormatter = DateComponentsFormatter()
    private var dispatchTimer: DispatchSourceTimer?

    @Published var state: TBTimerState = .idle
    @Published var menuBarIconName: String = "BarIconIdle"
    @Published var displayTime: String?
    @Published var timeLeftString: String = ""

    var isRunning: Bool { state != .idle }

    var isPaused: Bool {
        switch state {
        case .working(paused: true), .resting(paused: true):
            return true
        default:
            return false
        }
    }

    var isResting: Bool {
        if case .resting = state { return true }
        return false
    }

    init() {
        Self.shared = self

        timerFormatter.unitsStyle = .positional
        timerFormatter.allowedUnits = [.minute, .second]
        timerFormatter.zeroFormattingBehavior = .pad

        KeyboardShortcuts.onKeyUp(for: .startStopTimer, action: startStop)
        notificationCenter.setActionHandler(handler: onNotificationAction)

        let aem = NSAppleEventManager.shared()
        aem.setEventHandler(self,
                            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
                            forEventClass: AEEventClass(kInternetEventClass),
                            andEventID: AEEventID(kAEGetURL))
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor,
                                 withReplyEvent _: NSAppleEventDescriptor) {
        guard let urlString = event.forKeyword(AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString),
              let scheme = url.scheme,
              let host = url.host else { return }
        guard scheme.caseInsensitiveCompare("tomatobar") == .orderedSame ||
              scheme.caseInsensitiveCompare("tomatobarpro") == .orderedSame else { return }
        switch host.lowercased() {
        case "startstop":
            startStop()
        case "pause":
            pauseResume()
        default:
            return
        }
    }

    func startStop() {
        transition(.startStop)
    }

    func pauseResume() {
        transition(.pauseResume)
    }

    func skipRest() {
        transition(.skipRest)
    }

    private func transition(_ event: TBTimerEvent) {
        let oldState = state
        guard let newState = tbTransition(from: oldState, event: event,
                                          stopAfterBreak: stopAfterBreak) else { return }

        logger.append(event: TBLogEventTransition(event: event, from: oldState, to: newState))
        state = newState

        switch (oldState, newState, event) {
        case (.idle, .working(paused: false), .startStop):
            onWorkStart()

        case (.working(paused: false), .working(paused: true), .pauseResume):
            onPause()

        case (.working(paused: true), .working(paused: false), .pauseResume):
            onResume()

        case (.working, .idle, .startStop):
            onWorkEnd()
            onIdleStart()

        case (.working(paused: false), .resting(paused: false), .timerFired):
            onWorkFinish()
            onWorkEnd()
            onRestStart()

        case (.resting(paused: false), .resting(paused: true), .pauseResume):
            onPause()

        case (.resting(paused: true), .resting(paused: false), .pauseResume):
            onResume()

        case (.resting, .idle, .startStop):
            onIdleStart()

        case (.resting(paused: false), .idle, .timerFired):
            onRestFinish(skipped: false)
            onIdleStart()

        case (.resting(paused: false), .working(paused: false), .timerFired):
            onRestFinish(skipped: false)
            onWorkStart()

        case (.resting, .working(paused: false), .skipRest):
            onRestFinish(skipped: true)
            onWorkStart()

        default:
            break
        }
    }

    func updateTimeLeft() {
        let remaining: TimeInterval
        if isPaused {
            remaining = remainingTime
        } else {
            remaining = finishTime.timeIntervalSince(Date())
        }

        let displayInterval: TimeInterval
        if countUpTimer {
            displayInterval = totalDuration - remaining
        } else {
            displayInterval = remaining
        }

        timeLeftString = timerFormatter.string(from: max(0, displayInterval)) ?? "0:00"

        if isRunning, showTimerInMenuBar {
            displayTime = timeLeftString
        } else {
            displayTime = nil
        }
    }

    private func startTimer(seconds: Int) {
        totalDuration = TimeInterval(seconds)
        finishTime = Date().addingTimeInterval(totalDuration)

        let queue = DispatchQueue(label: "Timer")
        dispatchTimer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        dispatchTimer!.schedule(deadline: .now(), repeating: .seconds(1), leeway: .never)
        dispatchTimer!.setEventHandler(handler: onTimerTick)
        dispatchTimer!.resume()
    }

    private func stopTimer() {
        dispatchTimer?.cancel()
        dispatchTimer = nil
    }

    private func onTimerTick() {
        DispatchQueue.main.async { [self] in
            updateTimeLeft()
            let timeLeft = finishTime.timeIntervalSince(Date())
            if timeLeft <= 0 {
                if timeLeft < overrunTimeLimit {
                    transition(.startStop)
                } else {
                    transition(.timerFired)
                }
            }
        }
    }

    private func onNotificationAction(action: TBNotification.Action) {
        if action == .skipRest, isResting {
            skipRest()
        }
    }

    // MARK: - State handlers

    private func onWorkStart() {
        menuBarIconName = "BarIconWork"
        player.playWindup()
        player.startTicking()
        startTimer(seconds: workIntervalLength * 60)
    }

    private func onWorkFinish() {
        consecutiveWorkIntervals += 1
        player.playDing()
    }

    private func onWorkEnd() {
        player.stopTicking()
    }

    private func onRestStart() {
        var body = NSLocalizedString("TBTimer.onRestStart.short.body", comment: "Short break body")
        var length = shortRestIntervalLength
        var imgName = "BarIconShortRest"
        if consecutiveWorkIntervals >= workIntervalsInSet {
            body = NSLocalizedString("TBTimer.onRestStart.long.body", comment: "Long break body")
            length = longRestIntervalLength
            imgName = "BarIconLongRest"
            consecutiveWorkIntervals = 0
        }
        notificationCenter.send(
            title: NSLocalizedString("TBTimer.onRestStart.title", comment: "Time's up title"),
            body: body,
            category: .restStarted
        )
        menuBarIconName = imgName
        startTimer(seconds: length * 60)
    }

    private func onRestFinish(skipped: Bool) {
        if !skipped {
            notificationCenter.send(
                title: NSLocalizedString("TBTimer.onRestFinish.title", comment: "Break is over title"),
                body: NSLocalizedString("TBTimer.onRestFinish.body", comment: "Break is over body"),
                category: .restFinished
            )
        }
    }

    private func onIdleStart() {
        stopTimer()
        menuBarIconName = "BarIconIdle"
        displayTime = nil
        timeLeftString = ""
        consecutiveWorkIntervals = 0
    }

    private func onPause() {
        remainingTime = finishTime.timeIntervalSince(Date())
        dispatchTimer?.cancel()
        dispatchTimer = nil
        player.stopTicking()
        updateTimeLeft()
    }

    private func onResume() {
        finishTime = Date().addingTimeInterval(remainingTime)

        let queue = DispatchQueue(label: "Timer")
        dispatchTimer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        dispatchTimer!.schedule(deadline: .now(), repeating: .seconds(1), leeway: .never)
        dispatchTimer!.setEventHandler(handler: onTimerTick)
        dispatchTimer!.resume()
        player.startTicking()
    }
}
