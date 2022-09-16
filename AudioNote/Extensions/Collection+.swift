//
//  Collection+.swift
//  AudioNote
//
//  Created by Liam Jones on 07/02/2022.
//

import Foundation

extension Collection {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
