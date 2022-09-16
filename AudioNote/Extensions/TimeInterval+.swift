//
//  TimeInterval+.swift
//  AudioNote
//
//  Created by Liam Jones on 25/01/2022.
//

import Foundation

extension TimeInterval {
  
  func timeDisplay() -> String {
    
    let rawSeconds = Int((self).rounded(.towardZero))
    let hours = rawSeconds / 3600
    let minutes = (rawSeconds % 3600) / 60
    let seconds = rawSeconds
    if hours > 0 {
      return String(format: "%02i:%02i:%02i", arguments: [hours, minutes, seconds])
    } else if minutes > 9 {
      return String(format: "%02i:%02i", arguments: [minutes, seconds])
    } else {
      return String(format: "%01i:%02i", arguments: [minutes, seconds])
    }
  }
  
}
