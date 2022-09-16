//
//  AudioManager.swift
//  AudioNote
//
//  Created by Liam Jones on 03/01/2022.
//

import Foundation
import AVKit
import Combine

enum AudioStatus: Int, CustomStringConvertible {
  
  case stopped, recording, playing, paused
  
  var description: String {
    return ["Stopped", "Recording", "Playing", "Paused"][rawValue]
  }
  
}

class AudioManager: NSObject, ObservableObject {
  
  @Published var status: AudioStatus = .stopped
  var audioRecorder: AVAudioRecorder?
  @Published var audioPlayer: AVAudioPlayer?
  var recordUrl: URL?
  var duration: Double = 0.0
  
  
  @Published var timerOutput: Double = 0
  private var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
  var subscriptions: Set<AnyCancellable> = []
  
  override init() {
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.routeChangeNotification, object: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func handleRouteChange(notification: Notification) {
    if let info = notification.userInfo,
       let rawValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt {
      let reason = AVAudioSession.RouteChangeReason(rawValue: rawValue)
      if reason == .oldDeviceUnavailable {
        guard let previousRoute = info[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription,
              let previousOutput = previousRoute.outputs.first else {
                return
              }
        if previousOutput.portType == .headphones {
          if status == .playing {
            stopPlaying()
          } else if status == .recording {
            stopRecording()
          }
        }
      }
    }
  }
  
  @objc func handleInterruption(notification: Notification) {
    if let info = notification.userInfo,
       let rawValue = info[AVAudioSessionInterruptionTypeKey] as? UInt {
      let type = AVAudioSession.InterruptionType(rawValue: rawValue)
      if type == .began {
        if status == .playing {
          pausePlayback()
        } else if status == .recording {
          stopRecording()
        }
      } else {
        if let rawValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
          let options = AVAudioSession.InterruptionOptions(rawValue: rawValue)
          if options == .shouldResume {
            resumePlayback()
          }
        }
      }
      
      
    }
  }
  
  
  
  func setupRecorder(testing: Bool = false) {
    //GenerateUrl
    let creationDate = Date.now
    let path: URL!
    if testing {
      path = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    } else {
      path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MM-yyyy-HH-mm-ss"
    let stringOutput = formatter.string(from: creationDate)
    let audioUrl = path.appendingPathComponent("audionote-\(stringOutput).caf")
    self.recordUrl = audioUrl
    
    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatLinearPCM),
      AVSampleRateKey: 44100.0,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    do {
      audioRecorder = try AVAudioRecorder(url: audioUrl, settings: settings)
      audioRecorder?.delegate = self
    } catch {
      print("Error setting up recorder: \(error.localizedDescription)")
    }
  }
  
  
  func startRecording() {
    
    if status == .playing {
      stopPlaying()
    }
    
    audioRecorder?.record()
    status = .recording
    startTimer()
  }
  
  func stopRecording() {
    duration = audioRecorder?.currentTime ?? 0
    audioRecorder?.stop()
    stopTimer()
    status = .stopped
  }
  
  func play(url: URL?) {
    guard let url = url else {
      print("Error: Tried to play nil")
      return
    }
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: url)
    } catch {
      print(error.localizedDescription)
    }
    guard let audioPlayer = audioPlayer else { return }
    if audioPlayer.duration > 0.0 {
      audioPlayer.isMeteringEnabled = true
      audioPlayer.delegate = self
      audioPlayer.play()
      status = .playing
      startTimer()
    }
  }
  
  func pausePlayback() {
    audioPlayer?.pause()
    stopTimer()
    status = .paused
  }
  
  func resumePlayback() {
    audioPlayer?.currentTime = timerOutput
    audioPlayer?.play()
    startTimer()
    status = .playing
  }
  
  
  func stopPlaying() {
    audioPlayer?.stop()
    stopTimer()
    status = .stopped
  }
  
  func playOrPause(url: URL?) {
    switch status {
    case .stopped:
      play(url: url)
    case .recording:
      break
    case .playing:
      pausePlayback()
    case .paused:
      resumePlayback()
    }
  }
  
  
  func respondToSlider(began: Bool) {
    if status == .playing {
      if began {
        audioPlayer?.pause()
        stopTimer()
      } else {
        audioPlayer?.currentTime = timerOutput
        startTimer()
        audioPlayer?.play()
      }
    }
    
  }
  
  
  func stopTimer() {
    self.timer?.upstream.connect().cancel()
    self.timer = nil
  }
  
  func startTimer() {
    self.timer = Timer.publish(every: 0.05, on: RunLoop.main, in: .common).autoconnect()
    timer?.sink { [self] _ in
      switch self.status {
      case .recording:
        self.timerOutput = self.audioRecorder?.currentTime ?? 0
      case .playing, .paused:
        self.timerOutput = self.audioPlayer?.currentTime ?? 0
        self.audioPlayer?.updateMeters()
      case .stopped:
        print("Error: Timer should never run in stopped state")
        self.stopTimer()
      }
    }
    .store(in: &subscriptions)
  }
  
  func cancelAndCleanUp() {
    audioRecorder?.stop()
    audioPlayer?.stop()
    stopTimer()
    duration = 0
    timerOutput = 0
    status = .stopped
    //If there is a file at the url, remove it
    if let url = recordUrl,
       FileManager.default.fileExists(atPath: url.path) {
      do {
        try FileManager.default.removeItem(at: url)
      } catch {
        print("Error: FileManager couldn't remove item at \(url.path). The error was: \(error.localizedDescription)")
      }
    }
  }
  
}





extension AudioManager: AVAudioRecorderDelegate {

  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    if status == .recording {
      stopTimer()
      status = .stopped
    }
  }
  
}

extension AudioManager: AVAudioPlayerDelegate {
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    if status == .playing {
      stopTimer()
      status = .stopped
    }
  }
  
}

