//
//  ViewController.swift
//  SpeecherLang
//
//  Created by Alfian Losari on 06/10/19.
//  Copyright © 2019 Alfian Losari. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController {
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var hintLabel: UILabel!
    
    private var speechRecognitionType = SpeechRecognitionType.live
    
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var speechResultsViewController: SpeechResultsViewController?
    private var exportSession: AVAssetExportSession?
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearButton.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = playerView.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    let interaction = UIDropInteraction(delegate: self)
                    self.playerView.interactions.append(interaction)
                    
                default:
                    self.hintLabel.isHidden = true
                    self.speechResultsViewController?.update(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Access to Speech recognizer is restricted"]))
                }
            }
        }
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        self.speechRecognitionType = sender.speechRecognitionType
    }
    
    @IBAction func clearTapped(_ sender: Any) {
        clearButton.isHidden = true
        hintLabel.isHidden = false
        segmentedControl.isEnabled = true
        
        recognitionRequest = nil
        recognitionTask?.cancel()
        exportSession?.cancelExport()
        player?.pause()
        player?.rate = 0
        player = nil
        
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        speechResultsViewController?.update(nil, isFinal: false)
    }
    
    private func setupVideoPlayer() {
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        guard playerLayer == nil else {
            return
        }
        let playerLayer = AVPlayerLayer()
        
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = playerView.bounds
        playerView.clipsToBounds = true
        playerView.layer.addSublayer(playerLayer)
        
        self.playerLayer = playerLayer
    }
    
    private func play(url: URL) {
        setupVideoPlayer()
        
        player?.pause()
        player = nil
        
        player = AVPlayer(url: url)
        playerLayer?.player = player
        
        player?.play()
    }
    
    private func extractAudioFromVideo(url: URL) {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        
        guard let asset = try? AVURLAsset(url: url).audioAsset() else {
            return
        }
        let preset = AVAssetExportPresetAppleM4A
        let outputFileType = AVFileType.m4a
        let filename = String(UUID().uuidString.split(separator: "-")[0])
        
        let outputFileURL = cacheURL.appendingPathComponent("\(filename).m4a")
        AVAssetExportSession.determineCompatibility(ofExportPreset: preset, with: asset, outputFileType: outputFileType) {[weak self] (isCompatible) in
            guard let self = self, isCompatible, let export = AVAssetExportSession(asset: asset, presetName: preset) else { return}
            export.outputFileType = outputFileType
            export.outputURL = outputFileURL
            export.exportAsynchronously {
                print(export.status)
                switch export.status {
                case .cancelled:
                    print("cancelled")
                case .exporting:
                    print("exporting")
                case .failed:
                    print("failed")
                case .completed:
                    DispatchQueue.main.async {
                        self.handleCompletedAudioAssetExportSession(export)
                    }
                default:
                    print("Default: \(export.status)")
                    
                }
            }
        }
    }
    
    private func handleCompletedAudioAssetExportSession(_ exportSession: AVAssetExportSession) {
        guard let url = exportSession.outputURL else { return }
        performSpeechAnalysis(url: url)
    }
    
    private func performSpeechAnalysis(url: URL) {
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognitionTask = speechRecognizer.recognitionTask(with: request) { (result, error) in
            if let error = error {
                self.speechResultsViewController?.update(error as NSError)
                return
            }
            
            guard let result = result else {
                return
            }
            
            DispatchQueue.main.async {
                self.speechResultsViewController?.update(result.bestTranscription.formattedString, isFinal: result.isFinal)
            }
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "embed", let resultVC = segue.destination as? SpeechResultsViewController else {
            fatalError()
        }
        self.speechResultsViewController = resultVC
        
    }
}

extension ViewController: UIDropInteractionDelegate {
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        if let item = session.items.first?.itemProvider {
            return item.hasRepresentationConforming(toTypeIdentifier: "public.mpeg-4")
        } else {
            return false
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let item = session.items.first?.itemProvider else {
            return
        }
        
        item.loadFileRepresentation(forTypeIdentifier: "public.mpeg-4") { [unowned self] (url, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let url = url else {
                return
            }
            
            DispatchQueue.main.async {
                self.speechResultsViewController?.update(nil, isFinal: false)
                self.segmentedControl.isEnabled = false
                self.hintLabel.isHidden = true
                self.clearButton.isHidden = false
                self.play(url: url)
            }
            switch self.speechRecognitionType {
            case .file:
                self.extractAudioFromVideo(url: url)
                
            case .live:
                try? self.startRecording()
            }
        }
    }
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // Configure the audio session for the app.z
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            let isFinal = result?.isFinal ?? false
            
            if let result = result {
                self.speechResultsViewController?.update(result.bestTranscription.formattedString, isFinal: isFinal)
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                if let error = error {
                    self.speechResultsViewController?.update(error as NSError)
                }
                
            }
        }
        
        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
    }
    
}


extension AVAsset {
    
    func audioAsset() throws -> AVAsset {
        let composition = AVMutableComposition()
        let _tracks = tracks(withMediaType: .audio)
        
        for track in _tracks {
            let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compositionTrack?.insertTimeRange(track.timeRange, of: track, at: track.timeRange.start)
            compositionTrack?.preferredTransform = track.preferredTransform
        }
        
        return composition
    }
}

enum SpeechRecognitionType {
    case live
    case file
}

fileprivate extension UISegmentedControl {
    
    
    var speechRecognitionType: SpeechRecognitionType {
        switch self.selectedSegmentIndex {
        case 0: return .live
        default: return .file
        }
        
        
    }
    
}
