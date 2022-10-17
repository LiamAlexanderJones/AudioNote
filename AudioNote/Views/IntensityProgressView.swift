//
//  IntensityProgressView.swift
//  AudioNote
//
//  Created by Liam Jones on 23/01/2022.
//

import SwiftUI

struct IntensityProgressView: View {
  
  @ObservedObject var audioManager: AudioManager
  
  var note: NoteManagedObject
  @State var barData: [(height: CGFloat, colour: Color)] = []
  
  var position: Double {
    audioManager.timerOutput / Double(note.duration)
  }
  
  var body: some View {
    GeometryReader { geometry in
      HStack(alignment: .center, spacing: 6) {
        ForEach(0..<Int(geometry.size.width / 12), id: \.self) { index in
          Capsule()
            .foregroundColor(barData[safe: index]?.colour ?? .gray)
            .frame(width: 6, height: barData[safe: index]?.height ?? 6, alignment: .bottom)
        }
      }
      .frame(height: geometry.size.height, alignment: .center)
      .onChange(of: audioManager.timerOutput) { progress in
        guard note.duration > 0 else { return }
        let normalisedProgress = progress * Double(geometry.size.width / 12) / note.duration
        guard normalisedProgress.isFinite else { return }
        let i = Int(normalisedProgress.rounded(.towardZero))

        let decibels = audioManager.audioPlayer?.averagePower(forChannel: 0) ?? -160
        let power = pow(2, decibels / 12) //Normally would be /6
        
        //Check bardata[i] exists, and if not, append it
        if barData.count <= i {
          barData.append((height: CGFloat(power * 60), colour: .gray))
        } else {
          barData[i].height = CGFloat(power * 60)
        }
        
        if audioManager.status == .playing {
          barData[i].colour = Color(hue: Double(0.75 - power), saturation: 1, brightness: 0.75)
        }
      }
      .onChange(of: audioManager.status) { status in
        if status == .stopped {
          barData = barData.map { (height: $0.height, colour: Color.gray) }
        }
      }
    }
  }
  
  
  
}

struct IntensityProgressView_Previews: PreviewProvider {
  static var previews: some View {
    let previewContext = PersistenceController.preview.container.viewContext
    let note = NoteManagedObject(context: previewContext)
    note.creationDate = Date.now
    note.reminderDate = Date()
    note.audioUrl = URL(string: "Dummy")!
    note.comment = ""
    note.duration = 30.0
    return IntensityProgressView(audioManager: AudioManager(), note: note)
  }
}
