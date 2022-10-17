//
//  CreateNoteView.swift
//  AudioNote
//
//  Created by Liam Jones on 03/01/2022.
//

import SwiftUI
import AVKit
import CoreData
import Combine

struct RecordAudioView: View {
  
  @ObservedObject var audioManager = AudioManager()
  @State var hasMicAccess = false
  @State var showAlert = false
  @State var showInstructions = false
  @Binding var showNoteCreation: Bool
  
  var oscillator: Double {
    return abs(sin(.pi * audioManager.timerOutput))
  }
  
  let formatter = DateComponentsFormatter()
  
  var body: some View {
    GeometryReader { geometry in
      VStack {
        Text(audioManager.timerOutput.timeDisplay())
          .font(.system(size: 40))
        
        Spacer()
        
        
        HStack {
          Spacer()
          Image(systemName: "mic.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)
            .foregroundColor(.red)
            .overlay(
              Circle()
                .stroke(
                  Color.red.opacity(1 - 0.7 * oscillator),
                  lineWidth: audioManager.status == .recording ? 0.13 * geometry.size.width * oscillator : 1
                )
            )
            .onTapGesture(perform: {
              showInstructions = true
              DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showInstructions = false
              }
            })
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
              if pressing {
                audioManager.startRecording()
              } else {
                audioManager.stopRecording()
              }
            }, perform: { })
            .disabled(!hasMicAccess)
          Spacer()
          Button(action: {
            audioManager.playOrPause(url: audioManager.recordUrl)
          }, label: {
            Image(systemName: audioManager.status == . playing ? "pause.circle.fill" : "play.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)
              .foregroundColor(audioManager.status == .playing ? .orange : .green)
              .opacity(audioManager.duration < 0.2 ? 0.2 : 1)
              .overlay(
                Circle()
                  .trim(from: 0, to: audioManager.timerOutput / max(audioManager.duration, 0.01))
                  .stroke(
                    audioManager.status == .playing ? Color.green : Color.orange,
                    lineWidth: (audioManager.status == .playing) || (audioManager.status == .paused) ? 4 : 0
                  )
              )
          })
            .font(.headline)
            .disabled(audioManager.duration < 0.2 || audioManager.status == .recording)
          Spacer()
        }
        Spacer()
        
        NavigationLink(
          destination: CreateNoteView(showNoteCreation: self.$showNoteCreation, audioManager: audioManager),
          label: {
            Text("Next")
              .fontWeight(.bold)
              .padding()
              .foregroundColor(.white)
              .font(.largeTitle)
              .background(
                Capsule()
                  .fill(Color.teal)
                  .frame(width: audioManager.duration < 0.2 ? 0 : geometry.size.width * 0.8)
                  .shadow(color: .black, radius: 1, x: 1, y: 1)
                  .animation(.easeIn, value: audioManager.duration)
              )
          })
          .disabled(audioManager.recordUrl == nil || audioManager.status == .recording || audioManager.duration < 0.2)
          .padding(.bottom)
      }
      .overlay(
        Text(hasMicAccess ? "Press and hold to record." : "AudioNote needs access to your microphone to record audio.")
          .font(.system(size: 20))
          .fontWeight(.bold)
          .padding(3)
          .foregroundColor(.white)
          .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray))
          .opacity(showInstructions ? 0.8 : 0)
          .animation(.easeIn, value: showInstructions)
      )
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Cancel", action: cancel)
        }
      }
      .onAppear {
        audioManager.setupRecorder()
        requestMicAccess()
        showInstructions = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          showInstructions = false
        }
      }
      .alert(isPresented: $showAlert) {
        Alert(
          title: Text("AudioNote needs access to your microphone"),
          message: Text("Go to settings > AudioNote > Allow AudioNote to access microphone. \nSet switch to enable"),
          dismissButton: .default(Text("OK")))
      }
    }
  }
  
  func requestMicAccess() {
    let session = AVAudioSession.sharedInstance()
    session.requestRecordPermission { granted in
      if granted {
        hasMicAccess = granted
      } else {
        showAlert = true
      }
    }
  }
  
  
  func cancel() {
    audioManager.cancelAndCleanUp()
    showNoteCreation = false
  }
  
  
}

struct RecordAudioView_Previews: PreviewProvider {
  static var previews: some View {
    RecordAudioView(showNoteCreation: .constant(true))
  }
}

