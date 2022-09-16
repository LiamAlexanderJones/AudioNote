//
//  NoteView.swift
//  AudioNote
//
//  Created by Liam Jones on 13/01/2022.
//

import SwiftUI

struct NoteView: View {
  
  @ObservedObject var audioManager = AudioManager()
  @State var showDetailView = false
  
  var note: NoteManagedObject
  
  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .short
    return formatter
  }()
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(dateFormatter.string(from: note.creationDate ?? Date()))
        .fontWeight(.semibold)
        .scaledToFit()
        .minimumScaleFactor(0.5)
        .lineLimit(1)
      HStack {
        Button(action: {
          audioManager.playOrPause(url: note.audioUrl)
        }, label: {
          Image(systemName: audioManager.status == . playing ? "pause" : "play.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 25, height: 25)
            .foregroundColor(.black)
        })
          .font(.body)
        IntensityProgressView(audioManager: audioManager, note: note)
          .frame(maxWidth: .infinity)
        Text(audioManager.status == .stopped ? note.duration.timeDisplay() : audioManager.timerOutput.timeDisplay())
          .scaledToFit()
          .minimumScaleFactor(0.5)
          .truncationMode(.head)
          .lineLimit(1)
          .padding(.leading, 6)
        Button(action: {
          showDetailView.toggle()
        }, label: {
          Image(systemName: "chevron.right")
        })
      }
      NavigationLink(isActive: $showDetailView, destination: {NoteDetailView(note: note)}, label: {EmptyView()})
        .hidden()
    }
    .buttonStyle(BorderlessButtonStyle())
  }
}

struct NoteView_Previews: PreviewProvider {
  static var previews: some View {
    let previewContext = PersistenceController.preview.container.viewContext
    let note = NoteManagedObject(context: previewContext)
    note.creationDate = Date.now
    note.reminderDate = Date()
    note.audioUrl = URL(string: "Dummy")!
    note.comment = ""
    note.duration = 30.0
    return NoteView(note: note)
  }
}
