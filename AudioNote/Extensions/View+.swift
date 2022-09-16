//
//  View+.swift
//  AudioNote
//
//  Created by Liam Jones on 31/01/2022.
//

import Foundation
import SwiftUI

extension View {
  func navigationBarTitle<Content>(
    @ViewBuilder content: () -> Content
  ) -> some View where Content: View {
    self.toolbar {
      ToolbarItem(placement: .principal, content: content)
    }
  }
}
