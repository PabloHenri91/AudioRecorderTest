//
//  MainViewController.swift
//  AudioRecorder
//
//  Created by Pablo Henrique Bertaco on 15/04/20.
//  Copyright © 2020 Organization. All rights reserved.
//

import UIKit
import AVFoundation

class MainViewController: UIViewController {
    
    @IBOutlet weak var labelFileSize: UILabel!
    @IBOutlet weak var buttonRecord: UIButton!
    @IBOutlet weak var buttonStop: UIButton!
    @IBOutlet weak var buttonPlay: UIButton!
    @IBOutlet weak var buttonClear: UIButton!
    
    
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    
    init() {
        super.init(nibName: "\(Self.self)", bundle: .main)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.buttonRecord.setTitle("Record", for: .normal)
        self.buttonStop.setTitle("Stop", for: .normal)
        self.buttonPlay.setTitle("Play", for: .normal)
        self.buttonClear.setTitle("Clear", for: .normal)
        for i in [self.buttonStop, self.buttonPlay, self.buttonClear] {
            i?.isHidden = true
        }
        self.updateLabelFileSize()
    }
    
    @IBAction func buttonRecord(_ sender: Any) {
        self.record(recordPermission: false)
    }
    
    @IBAction func buttonStop(_ sender: Any) {
        self.stop()
    }
    
    @IBAction func buttonPlay(_ sender: Any) {
        self.play()
    }
    
    @IBAction func buttonClear(_ sender: Any) {
        self.clear()
    }
    
    func url() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("fineName.m4a")
        return url
    }
    
    func settings() -> [String : Any] {
        let settings: [String : Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVEncoderBitRateKey: 48000,
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 1
        ]
        return settings
    }
    
    func requestRecordPermission(_ response: @escaping PermissionBlock) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: AVAudioSession.Mode.default, options: [])
            try audioSession.setActive(true, options: [])
            audioSession.requestRecordPermission(response)
        } catch let error as NSError {
            self.show(error: error)
        }
    }
    
    func record() {
        let url = self.url()
        let settings = self.settings()
        
        do {
            let audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder.prepareToRecord()
            audioRecorder.record()
            self.audioRecorder = audioRecorder
            self.buttonRecord.isHidden = true
            self.buttonStop.isHidden = false
            self.buttonPlay.isHidden = true
            self.buttonClear.isHidden = true
            self.updateLabelFileSize()
        } catch let error as NSError {
            self.audioRecorder = nil
            self.show(error: error)
        }
    }

    func record(recordPermission granted: Bool = true) {
        if granted {
            self.record()
        } else {
            self.requestRecordPermission { (granted: Bool) in
                if granted {
                    self.record()
                }
            }
        }
    }
    
    func updateLabelFileSize() {
        self.labelFileSize.isHidden = self.buttonPlay.isHidden
        guard !self.labelFileSize.isHidden else { return }
        let url = self.url()
        let data = FileManager.default.contents(atPath: url.path) ?? Data()
        let byteCount: Int64 = Int64(data.count)
        let byteCountFormatter = ByteCountFormatter()
        let text = byteCountFormatter.string(fromByteCount: byteCount)
        self.labelFileSize.text = text
    }
    
    func stop() {
        self.audioRecorder?.stop()
        self.buttonRecord.isHidden = false
        self.buttonStop.isHidden = true
        self.buttonPlay.isHidden = false
        self.buttonClear.isHidden = false
        self.updateLabelFileSize()
    }
    
    func play() {
        let url = self.url()
        
        if let audioPlayer = try? AVAudioPlayer(contentsOf: url) {
            audioPlayer.play()
            self.audioPlayer = audioPlayer
        } else {
            self.audioPlayer = nil
        }
    }
    
    func clear() {
        let url = self.url()
        do {
            try FileManager.default.removeItem(at: url)
            self.buttonPlay.isHidden = true
            self.buttonClear.isHidden = true
            self.updateLabelFileSize()
        } catch let error as NSError {
            self.show(error: error)
            
        }
    }
    
    func show(error: NSError) {
        self.show(UIAlertController(title: error.localizedDescription, message: error.localizedRecoverySuggestion, preferredStyle: UIAlertController.Style.alert), sender: self)
    }

}
