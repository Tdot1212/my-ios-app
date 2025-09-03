import Foundation
import Speech
import AVFoundation

@MainActor
class VoiceCommandService: ObservableObject {
    static let shared = VoiceCommandService()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var permissionGranted = false
    
    private init() {
        checkPermissions()
    }
    
    private func checkPermissions() {
        permissionGranted = SFSpeechRecognizer.authorizationStatus() == .authorized &&
                           AVAudioSession.sharedInstance().recordPermission == .granted
    }
    
    func requestPermissions() async -> Bool {
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        // Request microphone permission
        let audioStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        permissionGranted = speechStatus == .authorized && audioStatus
        return permissionGranted
    }
    
    func startRecording() async throws {
        guard permissionGranted else {
            let granted = await requestPermissions()
            if !granted {
                throw VoiceCommandError.permissionDenied
            }
        }
        
        // Reset state
        transcribedText = ""
        isRecording = true
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceCommandError.recognitionRequestFailed
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
            }
            
            if error != nil || result?.isFinal == true {
                self.stopAudioEngine()
            }
        }
    }
    
    func stopRecording() async throws -> String {
        isRecording = false
        stopAudioEngine()
        
        // Return the transcribed text
        let finalText = transcribedText
        transcribedText = ""
        return finalText
    }
    
    func cancelRecording() {
        isRecording = false
        stopAudioEngine()
        transcribedText = ""
    }
    
    private func stopAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

enum VoiceCommandError: Error, LocalizedError {
    case permissionDenied
    case recognitionRequestFailed
    case audioEngineFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone and speech recognition permissions are required"
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request"
        case .recognitionRequestFailed:
            return "Failed to start audio recording"
        }
    }
}
