import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI
import UniformTypeIdentifiers

extension KeyboardShortcuts.Name {
    static let startStopTimer = Self("startStopTimer")
}

private struct IntervalsView: View {
    @EnvironmentObject var timer: TBTimer
    private var minStr = NSLocalizedString("IntervalsView.min", comment: "min")

    var body: some View {
        VStack {
            Stepper(value: $timer.workIntervalLength, in: 1 ... 60) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.workIntervalLength.label",
                                           comment: "Work interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String.localizedStringWithFormat(minStr, timer.workIntervalLength))
                }
            }
            Stepper(value: $timer.shortRestIntervalLength, in: 1 ... 60) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.shortRestIntervalLength.label",
                                           comment: "Short rest interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String.localizedStringWithFormat(minStr, timer.shortRestIntervalLength))
                }
            }
            Stepper(value: $timer.longRestIntervalLength, in: 1 ... 60) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.longRestIntervalLength.label",
                                           comment: "Long rest interval label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String.localizedStringWithFormat(minStr, timer.longRestIntervalLength))
                }
            }
            .help(NSLocalizedString("IntervalsView.longRestIntervalLength.help",
                                    comment: "Long rest interval hint"))
            Stepper(value: $timer.workIntervalsInSet, in: 1 ... 10) {
                HStack {
                    Text(NSLocalizedString("IntervalsView.workIntervalsInSet.label",
                                           comment: "Work intervals in a set label"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(timer.workIntervalsInSet)")
                }
            }
            .help(NSLocalizedString("IntervalsView.workIntervalsInSet.help",
                                    comment: "Work intervals in set hint"))
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}

private struct SettingsView: View {
    @EnvironmentObject var timer: TBTimer
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable

    var body: some View {
        VStack {
            KeyboardShortcuts.Recorder(for: .startStopTimer) {
                Text(NSLocalizedString("SettingsView.shortcut.label",
                                       comment: "Shortcut label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Toggle(isOn: $timer.stopAfterBreak) {
                Text(NSLocalizedString("SettingsView.stopAfterBreak.label",
                                       comment: "Stop after break label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Toggle(isOn: $timer.showTimerInMenuBar) {
                Text(NSLocalizedString("SettingsView.showTimerInMenuBar.label",
                                       comment: "Show timer in menu bar label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
                .onChange(of: timer.showTimerInMenuBar) {
                    timer.updateTimeLeft()
                }
            Toggle(isOn: $timer.countUpTimer) {
                Text(NSLocalizedString("SettingsView.countUpTimer.label",
                                       comment: "Count up timer label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Toggle(isOn: $launchAtLogin.isEnabled) {
                Text(NSLocalizedString("SettingsView.launchAtLogin.label",
                                       comment: "Launch at login label"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}

private struct VolumeSlider: View {
    @Binding var volume: Double

    var body: some View {
        Slider(value: $volume, in: 0...2) {
            Text(String(format: "%.1f", volume))
        }.gesture(TapGesture(count: 2).onEnded({
            volume = 1.0
        }))
    }
}

private struct SoundRow: View {
    let label: String
    @Binding var volume: Double
    let customName: String?
    let onPickFile: () -> Void
    let onReset: () -> Void

    var body: some View {
        Text(label)
        HStack(spacing: 4) {
            VolumeSlider(volume: $volume)
            Button(action: onPickFile) {
                Image(systemName: "folder")
            }
            .buttonStyle(.borderless)
            .help(customName ?? NSLocalizedString("SoundsView.builtIn.label", comment: "Built-in"))
        }
        if customName != nil {
            Text("")
            HStack {
                Text(customName!)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
                Button(NSLocalizedString("SoundsView.resetSound.label", comment: "Reset"),
                       action: onReset)
                    .font(.caption)
                    .buttonStyle(.borderless)
            }
        }
    }
}

private struct SoundsView: View {
    @EnvironmentObject var player: TBPlayer
    @State private var activeSlot: TBSoundSlot?

    private var columns = [
        GridItem(.flexible()),
        GridItem(.fixed(130))
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            SoundRow(label: NSLocalizedString("SoundsView.isWindupEnabled.label",
                                              comment: "Windup label"),
                     volume: $player.windupVolume,
                     customName: player.customWindupName,
                     onPickFile: { activeSlot = .windup },
                     onReset: { player.resetSound(for: .windup) })
            SoundRow(label: NSLocalizedString("SoundsView.isDingEnabled.label",
                                              comment: "Ding label"),
                     volume: $player.dingVolume,
                     customName: player.customDingName,
                     onPickFile: { activeSlot = .ding },
                     onReset: { player.resetSound(for: .ding) })
            SoundRow(label: NSLocalizedString("SoundsView.isTickingEnabled.label",
                                              comment: "Ticking label"),
                     volume: $player.tickingVolume,
                     customName: player.customTickingName,
                     onPickFile: { activeSlot = .ticking },
                     onReset: { player.resetSound(for: .ticking) })
        }
        .padding(4)
        .fileImporter(
            isPresented: Binding(
                get: { activeSlot != nil },
                set: { if !$0 { activeSlot = nil } }
            ),
            allowedContentTypes: [.audio]
        ) { result in
            if case .success(let url) = result, let slot = activeSlot {
                player.setCustomSound(for: slot, url: url)
            }
            activeSlot = nil
        }
        Spacer().frame(minHeight: 0)
    }
}

private enum ChildView {
    case intervals, settings, sounds
}

struct TBPopoverView: View {
    @EnvironmentObject var timer: TBTimer
    @State private var buttonHovered = false
    @State private var activeChildView = ChildView.intervals

    private var startLabel = NSLocalizedString("TBPopoverView.start.label", comment: "Start label")
    private var stopLabel = NSLocalizedString("TBPopoverView.stop.label", comment: "Stop label")

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                timer.startStop()
            } label: {
                Text(timer.isRunning ?
                     (buttonHovered ? stopLabel : timer.timeLeftString) :
                        startLabel)
                    .foregroundColor(Color.white)
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity)
            }
            .onHover { over in
                buttonHovered = over
            }
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            if timer.isRunning {
                Button {
                    timer.pauseResume()
                } label: {
                    Text(timer.isPaused ?
                         NSLocalizedString("TBPopoverView.resume.label", comment: "Resume label") :
                         NSLocalizedString("TBPopoverView.pause.label", comment: "Pause label"))
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            }

            if timer.isResting {
                Button {
                    timer.skipRest()
                } label: {
                    Text(NSLocalizedString("TBPopoverView.skipRest.label", comment: "Skip rest label"))
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            }

            Picker("", selection: $activeChildView) {
                Text(NSLocalizedString("TBPopoverView.intervals.label",
                                       comment: "Intervals label")).tag(ChildView.intervals)
                Text(NSLocalizedString("TBPopoverView.settings.label",
                                       comment: "Settings label")).tag(ChildView.settings)
                Text(NSLocalizedString("TBPopoverView.sounds.label",
                                       comment: "Sounds label")).tag(ChildView.sounds)
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .pickerStyle(.segmented)

            GroupBox {
                switch activeChildView {
                case .intervals:
                    IntervalsView().environmentObject(timer)
                case .settings:
                    SettingsView().environmentObject(timer)
                case .sounds:
                    SoundsView().environmentObject(timer.player)
                }
            }

            Group {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel()
                } label: {
                    Text(NSLocalizedString("TBPopoverView.about.label",
                                           comment: "About label"))
                    Spacer()
                    Text("\u{2318} A").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("a")
                Button {
                    NSApplication.shared.terminate(self)
                } label: {
                    Text(NSLocalizedString("TBPopoverView.quit.label",
                                           comment: "Quit label"))
                    Spacer()
                    Text("\u{2318} Q").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
            }
        }
        .padding(12)
        .frame(width: 240)
    }
}
