import AVFoundation
import CoreAudio
import Foundation

// 🔍 Step 1: Find AudioDeviceID for BlackHole
func getInputDevice(named deviceName: String) -> AudioDeviceID? {
    var props = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    var dataSize: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &props, 0, nil, &dataSize) == noErr else {
        return nil
    }

    let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
    var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &props, 0, nil, &dataSize, &deviceIDs) == noErr else {
        return nil
    }

    for id in deviceIDs {
        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var nameProps = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let result = AudioObjectGetPropertyData(id, &nameProps, 0, nil, &size, &name)
        if result == noErr, let name = name?.takeRetainedValue(), String(name).contains(deviceName) {
            return id
        }
    }

    return nil
}

// 🎯 Step 2: Set BlackHole as default input
func setDefaultInputDevice(_ deviceID: AudioDeviceID) -> Bool {
    var deviceID = deviceID
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    let result = AudioObjectSetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &address,
        0,
        nil,
        UInt32(MemoryLayout.size(ofValue: deviceID)),
        &deviceID
    )
    return result == noErr
}

// 🧹 Step 3: Auto-delete recordings older than N days
func deleteOldRecordings(olderThan days: Int) {
    let folder = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Documents/SystemAudioRecordings")

    let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey])

    let expiration = Date().addingTimeInterval(TimeInterval(-days * 24 * 60 * 60))

    files?.forEach { file in
        let attrs = try? file.resourceValues(forKeys: [.contentModificationDateKey])
        if let modified = attrs?.contentModificationDate, modified < expiration {
            try? FileManager.default.removeItem(at: file)
        }
    }
}

// 🎧 Step 4: Record system audio
func startRecording() {
    guard let blackholeID = getInputDevice(named: "BlackHole") else {
        print("❌ BlackHole input device not found.")
        exit(1)
    }

    if setDefaultInputDevice(blackholeID) {
        print("✅ Input device switched to BlackHole")
    } else {
        print("❌ Failed to switch input device")
        exit(1)
    }

    let engine = AVAudioEngine()
    let input = engine.inputNode
    let format = input.inputFormat(forBus: 0)

    let fileManager = FileManager.default
    let homeDir = fileManager.homeDirectoryForCurrentUser
    let recordingsDir = homeDir.appendingPathComponent("Documents/SystemAudioRecordings")

    try? fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let timestamp = formatter.string(from: Date())
    let outputPath = recordingsDir.appendingPathComponent("system_audio_\(timestamp).caf").path

    guard let file = try? AVAudioFile(forWriting: URL(fileURLWithPath: outputPath), settings: format.settings) else {
        print("❌ Failed to create audio file")
        exit(1)
    }

    input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
        try? file.write(from: buffer)
    }

    do {
        try engine.start()
        print("🎤 Recording system audio... Output: \(outputPath)")
        RunLoop.main.run()
    } catch {
        print("❌ Error starting engine: \(error.localizedDescription)")
        exit(1)
    }
}

// 🚀 Main
deleteOldRecordings(olderThan: 3)
startRecording()
