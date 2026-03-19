import Foundation

enum TBTimerState: Equatable {
    case idle
    case working(paused: Bool)
    case resting(paused: Bool)
}

enum TBTimerEvent {
    case startStop
    case pauseResume
    case timerFired
    case skipRest
}

func tbTransition(from state: TBTimerState, event: TBTimerEvent, stopAfterBreak: Bool) -> TBTimerState? {
    switch (state, event) {
    case (.idle, .startStop):
        return .working(paused: false)
    case (.working, .startStop),
         (.resting, .startStop):
        return .idle
    case (.working(paused: false), .pauseResume):
        return .working(paused: true)
    case (.working(paused: true), .pauseResume):
        return .working(paused: false)
    case (.resting(paused: false), .pauseResume):
        return .resting(paused: true)
    case (.resting(paused: true), .pauseResume):
        return .resting(paused: false)
    case (.working(paused: false), .timerFired):
        return .resting(paused: false)
    case (.resting(paused: false), .timerFired):
        return stopAfterBreak ? .idle : .working(paused: false)
    case (.resting, .skipRest):
        return .working(paused: false)
    default:
        return nil
    }
}
