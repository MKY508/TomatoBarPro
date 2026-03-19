import AVFoundation
import SwiftUI

enum TBSoundSlot: String, CaseIterable {
    case windup, ding, ticking
}

class TBPlayer: ObservableObject {
    private var windupSound: AVAudioPlayer
    private var dingSound: AVAudioPlayer
    private var tickingSound: AVAudioPlayer

    @AppStorage("windupVolume") var windupVolume: Double = 1.0 {
        didSet {
            setVolume(windupSound, windupVolume)
        }
    }
    @AppStorage("dingVolume") var dingVolume: Double = 1.0 {
        didSet {
            setVolume(dingSound, dingVolume)
        }
    }
    @AppStorage("tickingVolume") var tickingVolume: Double = 1.0 {
        didSet {
            setVolume(tickingSound, tickingVolume)
        }
    }

    @Published var customWindupName: String?
    @Published var customDingName: String?
    @Published var customTickingName: String?

    private func setVolume(_ sound: AVAudioPlayer, _ volume: Double) {
        sound.setVolume(Float(volume), fadeDuration: 0)
    }

    private static func loadBuiltinSound(name: String) -> AVAudioPlayer {
        let asset = NSDataAsset(name: name)!
        return try! AVAudioPlayer(data: asset.data, fileTypeHint: AVFileType.wav.rawValue)
    }

    private static func loadCustomSound(bookmark: Data?) -> (AVAudioPlayer, String)? {
        guard let bookmark = bookmark else { return nil }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark,
                                 options: .withSecurityScope,
                                 relativeTo: nil,
                                 bookmarkDataIsStale: &isStale),
              url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url),
              let player = try? AVAudioPlayer(data: data) else { return nil }
        return (player, url.lastPathComponent)
    }

    init() {
        windupSound = Self.loadBuiltinSound(name: "windup")
        dingSound = Self.loadBuiltinSound(name: "ding")
        tickingSound = Self.loadBuiltinSound(name: "ticking")

        let defaults = UserDefaults.standard
        if let (player, name) = Self.loadCustomSound(bookmark: defaults.data(forKey: "customWindupBookmark")) {
            windupSound = player
            customWindupName = name
        }
        if let (player, name) = Self.loadCustomSound(bookmark: defaults.data(forKey: "customDingBookmark")) {
            dingSound = player
            customDingName = name
        }
        if let (player, name) = Self.loadCustomSound(bookmark: defaults.data(forKey: "customTickingBookmark")) {
            tickingSound = player
            customTickingName = name
        }

        windupSound.prepareToPlay()
        dingSound.prepareToPlay()
        tickingSound.numberOfLoops = -1
        tickingSound.prepareToPlay()

        setVolume(windupSound, windupVolume)
        setVolume(dingSound, dingVolume)
        setVolume(tickingSound, tickingVolume)
    }

    func setCustomSound(for slot: TBSoundSlot, url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let bookmarkData = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ),
        let data = try? Data(contentsOf: url),
        let player = try? AVAudioPlayer(data: data) else { return }

        let name = url.lastPathComponent
        let defaults = UserDefaults.standard

        switch slot {
        case .windup:
            defaults.set(bookmarkData, forKey: "customWindupBookmark")
            windupSound = player
            windupSound.prepareToPlay()
            setVolume(windupSound, windupVolume)
            customWindupName = name
        case .ding:
            defaults.set(bookmarkData, forKey: "customDingBookmark")
            dingSound = player
            dingSound.prepareToPlay()
            setVolume(dingSound, dingVolume)
            customDingName = name
        case .ticking:
            defaults.set(bookmarkData, forKey: "customTickingBookmark")
            tickingSound = player
            tickingSound.numberOfLoops = -1
            tickingSound.prepareToPlay()
            setVolume(tickingSound, tickingVolume)
            customTickingName = name
        }
    }

    func resetSound(for slot: TBSoundSlot) {
        let defaults = UserDefaults.standard

        switch slot {
        case .windup:
            defaults.removeObject(forKey: "customWindupBookmark")
            windupSound = Self.loadBuiltinSound(name: "windup")
            windupSound.prepareToPlay()
            setVolume(windupSound, windupVolume)
            customWindupName = nil
        case .ding:
            defaults.removeObject(forKey: "customDingBookmark")
            dingSound = Self.loadBuiltinSound(name: "ding")
            dingSound.prepareToPlay()
            setVolume(dingSound, dingVolume)
            customDingName = nil
        case .ticking:
            defaults.removeObject(forKey: "customTickingBookmark")
            tickingSound = Self.loadBuiltinSound(name: "ticking")
            tickingSound.numberOfLoops = -1
            tickingSound.prepareToPlay()
            setVolume(tickingSound, tickingVolume)
            customTickingName = nil
        }
    }

    func playWindup() {
        windupSound.play()
    }

    func playDing() {
        dingSound.play()
    }

    func startTicking() {
        tickingSound.play()
    }

    func stopTicking() {
        tickingSound.stop()
    }
}
