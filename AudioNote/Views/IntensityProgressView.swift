//
//  IntensityProgressView.swift
//  AudioNote
//
//  Created by Liam Jones on 23/01/2022.
//

import SwiftUI

struct IntensityProgressView: View {
  
  @ObservedObject var audioManager: AudioManager
  static let numberOfBars = 10
  //number of bars = view width / double bar width
  
  var note: NoteManagedObject
  @State var barData: [(height: CGFloat, colour: Color)] = Array(repeating: (height: 6, colour: .gray), count: numberOfBars)
  //Remove?
  
  var position: Double {
    audioManager.timerOutput / Double(note.duration)
  }
  
  var body: some View {
    GeometryReader { geometry in
      HStack(alignment: .bottom, spacing: 6) {
        ForEach(0..<Int(geometry.size.width / 12), id: \.self) { index in
          Capsule()
            .foregroundColor(barData[safe: index]?.colour ?? .gray)
            .frame(width: 6, height: barData[safe: index]?.height ?? 6, alignment: .bottom)
        }
      }
      .frame(height: geometry.size.height, alignment: .bottom)
      .onChange(of: audioManager.timerOutput) { progress in
        let i = Int((progress * Double(geometry.size.width / 12) / Double(note.duration)).rounded(.towardZero))
        
        let decibels = audioManager.audioPlayer?.averagePower(forChannel: 0) ?? -160
        let power = pow(2, decibels / 18) //Normally would be /6
        
        //Check bardata[i] exists, and if not, append it
        if barData.count <= i {
          barData.append((height: CGFloat(power * 20), colour: .gray))
        } else {
          barData[i].height = CGFloat(power * 20)
        }
        
        if audioManager.status == .playing {
          barData[i].colour = .teal
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
