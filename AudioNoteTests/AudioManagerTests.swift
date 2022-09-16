//
//  AudioNoteTests.swift
//  AudioNoteTests
//
//  Created by Liam Jones on 03/01/2022.
//

import XCTest
import AVKit
@testable import AudioNote

class AudioManagerTests: XCTestCase {
  
  var audioManager: AudioManager!
  
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    audioManager = AudioManager()
    audioManager.setupRecorder(testing: true)
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    audioManager.cancelAndCleanUp()
  }
  
  
  //To test: create a note, retrieve a note from coredata, Edit comment with existing note, create a reminder, delete a reminder, edit a reminder
  
  
  
  func test_setupRecorder() {
    XCTAssertNotNil(audioManager.audioRecorder)
    XCTAssertNotNil(audioManager.recordUrl)
    XCTAssertEqual(audioManager.recordUrl, audioManager.audioRecorder?.url)
  }
  
  func test_startRecording() {
    //Given
    let expectation = expectation(description: "Audio finished recording")
    let recordTime = 1.0
    var statusMidway = AudioStatus.stopped
    var timerOutputMidway = 0.0
    //When
    audioManager.startRecording()
    DispatchQueue.main.asyncAfter(deadline: .now() + (recordTime * 0.5)) {
      statusMidway = self.audioManager.status
      timerOutputMidway = self.audioManager.timerOutput
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + recordTime) {
      self.audioManager.stopRecording()
      expectation.fulfill()
    }
    //Then
    waitForExpectations(timeout: recordTime + 0.1)
    XCTAssertEqual(timerOutputMidway, recordTime * 0.5, accuracy: 0.1)
    XCTAssertEqual(statusMidway, .recording)
  }
  
  func test_recordAudio() {
    //Given
    let expectation = expectation(description: "Audio recorded")
    let recordTime = 1.0
    //When
    self.audioManager.startRecording()
    DispatchQueue.main.asyncAfter(deadline: .now() + recordTime) {
      self.audioManager.stopRecording()
      expectation.fulfill()
    }
    //Then
    waitForExpectations(timeout: recordTime + 0.1)
    XCTAssertEqual(audioManager.duration, recordTime, accuracy: 0.1)
    XCTAssertEqual(audioManager.status, .stopped)
  }
  
  func test_recordAndStartPlaying() {
    //Given
    let recordTime = 1.0
    var statusMidway = AudioStatus.stopped
    var timerOutputMidway = 0.0
    var playerTimeMidway = 0.0
    let expectation = expectation(description: "Audio finished playing")
    //When
    audioManager.startRecording()
    DispatchQueue.main.asyncAfter(deadline: .now() + recordTime) {
      self.audioManager.stopRecording()
      self.audioManager.play(url: self.audioManager.recordUrl)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + (1.5 * recordTime) ) {
      statusMidway = self.audioManager.status
      timerOutputMidway = self.audioManager.timerOutput
      playerTimeMidway = self.audioManager.audioPlayer?.currentTime ?? 0.0
      expectation.fulfill()
    }
//    DispatchQueue.main.asyncAfter(deadline: .now() + (2 * recordTime) + 0.1) {
//      expectation.fulfill()
//    }
    //Then
    waitForExpectations(timeout: (1.5 * recordTime) + 0.1)
    XCTAssertNotNil(audioManager.audioPlayer)
    XCTAssertEqual(timerOutputMidway, recordTime * 0.5, accuracy: 0.1)
    XCTAssertEqual(playerTimeMidway, recordTime * 0.5, accuracy: 0.1)
    XCTAssertEqual(statusMidway, .playing)
  }
  
  func test_recordAndPlayAudio() {
    //Given
    let recordTime = 1.0
    let expectation = expectation(description: "Audio recorded and played")
    //When
    audioManager.startRecording()
    DispatchQueue.main.asyncAfter(deadline: .now() + recordTime) {
      self.audioManager.stopRecording()
      self.audioManager.play(url: self.audioManager.recordUrl)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + (2 * recordTime) + 0.1) {
      expectation.fulfill()
    }
    //Then
    waitForExpectations(timeout: (2 * recordTime) + 0.2)
    XCTAssertNotNil(audioManager.audioPlayer)
    XCTAssertEqual(audioManager.timerOutput, recordTime, accuracy: 0.1)
    XCTAssertEqual(audioManager.status, .stopped)
  }
  
  func test_pauseAudio() {
    //Given
    let recordTime = 1.0
    let expectation = expectation(description: "Audio recorded, played, and paused")
    var statusPaused = AudioStatus.stopped
    var timerOutputPaused = 0.0
    var playerTimerPaused = 0.0
    //When
    audioManager.startRecording()
    DispatchQueue.main.asyncAfter(deadline: .now() + recordTime) {
      self.audioManager.stopRecording()
      self.audioManager.playOrPause(url: self.audioManager.recordUrl)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + (1.5 * recordTime) ) {
      self.audioManager.playOrPause(url: self.audioManager.recordUrl)
      statusPaused = self.audioManager.status
      timerOutputPaused = self.audioManager.timerOutput
      playerTimerPaused = self.audioManager.audioPlayer?.currentTime ?? 0.0
      expectation.fulfill()
    }
    //Then
    waitForExpectations(timeout: 1.5 * recordTime + 0.2)
    XCTAssertNotNil(audioManager.audioPlayer)
    XCTAssertEqual(timerOutputPaused, recordTime * 0.5, accuracy: 0.1)
    XCTAssertEqual(playerTimerPaused, recordTime * 0.5, accuracy: 0.1)
    XCTAssertEqual(statusPaused, .paused)
  }
  
  
  func test_pauseAndResumeAudio() {
    //Given
    let recordTime = 1.0
    let expectation = expectation(description: "Audio paused and resumed")
    var statusResumed = AudioStatus.stopped
    var timerOutputResumed = 0.0
    var playerTimerResumed = 0.0
    //When
    audioManager.startRecording()
    DispatchQueue.main.asyncAfter(deadline: .now() + recordTime) {
      self.audioManager.stopRecording()
      self.audioManager.playOrPause(url: self.audioManager.recordUrl)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + (1.5 * recordTime) ) {
      self.audioManager.playOrPause(url: self.audioManager.recordUrl)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + (2 * recordTime) ) {
      self.audioManager.playOrPause(url: self.audioManager.recordUrl)
      statusResumed = self.audioManager.status
      timerOutputResumed = self.audioManager.timerOutput
      playerTimerResumed = self.audioManager.audioPlayer?.currentTime ?? 0.0
      expectation.fulfill()
    }
    //Then
    waitForExpectations(timeout: 2 * recordTime + 0.2)
    XCTAssertNotNil(audioManager.audioPlayer)
    XCTAssertEqual(timerOutputResumed, recordTime * 0.5, accuracy: 0.1)
    XCTAssertEqual(playerTimerResumed, recordTime * 0.5, accuracy: 0.1)
    XCTAssertEqual(statusResumed, .playing)
  }
  
 
//
//  func testPerformanceExample() throws {
//    // This is an example of a performance test case.
//    self.measure {
//      // Put the code you want to measure the time of here.
//    }
//  }
  
}
