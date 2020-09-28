//
//  VideoPlayerViewController.swift
//  TrellVods
//
//  Created by abhinay varma on 24/09/20.
//  Copyright © 2020 abhinay varma. All rights reserved.
//

import UIKit
import AVKit

class VideoPlayerViewController: UIViewController {

    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var maxTimeLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet private weak var playerView: PlayerView!
    
    fileprivate var currentProgress:Double = 0.0 {
        didSet {
            self.model?.currentProgress = currentProgress
        }
    }
    
    var videoPlayer:VideoPlayer?
    var model:VideoItem?
    let playImage = UIImage(named: "play")
    let pauseImage = UIImage(named: "pause")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preparePlayer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        clearCache()
    }
    
    private func preparePlayer() {
        slider.minimumTrackTintColor = .red
        slider.maximumTrackTintColor = .darkGray
       // slider.setThumbImage(UIImage(named: "thumb"), for: .normal)
        if let fileUrl = model?.path {
            videoPlayer = VideoPlayer(urlAsset: fileUrl, view: playerView)
            if let player = videoPlayer {
                player.playerRate = 1.0
                player.delegate = self
            }
        }
    }
    
    @IBAction func onClickPlayPauseButton(_ sender: Any) {
        if videoPlayer?.isPlaying() ?? false {
            videoPlayer?.pause()
            playButton.setImage(playImage, for: .normal)
        }else {
            playButton.setImage(pauseImage, for: .normal)
            videoPlayer?.play()
        }
    }
    @IBAction func forwardVideoClicked(_ sender: Any) {
         DispatchQueue.main.async {
            self.videoPlayer?.seekToPosition(seconds: self.videoPlayer!.getTime() + 5.0)
         }
    }
    
    @IBAction func reverseVideoClicked(_ sender: Any) {
         DispatchQueue.main.async {
            self.videoPlayer?.seekToPosition(seconds: self.videoPlayer!.getTime() - 5.0)
        }
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        clearCache()
        self.dismiss(animated: true, completion: nil)
    }
    
    private func clearCache() {
        videoPlayer?.pause()
        videoPlayer?.cleanUp()
        videoPlayer?.delegate = nil
        videoPlayer = nil
        playerView = nil
    }
    
    @IBAction func onClickFullScreen(_ sender: Any) {
    
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        let currentValue = sender.value
        if let totalSeconds = self.videoPlayer?.assetDuration {
            let value = Float64(currentValue) * totalSeconds
            
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            DispatchQueue.main.async {
                self.videoPlayer?.assetPlayer?.seek(to: seekTime, completionHandler: { (completedSeek) in
                    //perhaps do something later here
                })
            }
        }
    }
}

extension VideoPlayerViewController:VideoPlayerDelegate {
    func readyToPlay() {
         self.videoPlayer?.seekToPosition(seconds: (self.videoPlayer?.assetDuration ?? 0.0) * (self.model?.currentProgress ?? 0.0))
    }
    
    func didUpdateProgress(progress: Double) {
        currentProgress = progress
        DispatchQueue.main.async {
            self.slider.value = Float(self.currentProgress)
            let seconds = self.videoPlayer?.getTime() ?? 0.0
            let minuteText = String(format: "%02d", Int(seconds)/60)
            let secondText = String(format: "%02d", Int(seconds)%60)
            self.currentTimeLabel.text = "\(minuteText):\(secondText)"
            let currentSeconds = self.videoPlayer?.assetDuration ?? 0.0 * self.currentProgress
            let currentMinuteText = String(format: "%02d", Int(currentSeconds)/60)
            let currentSecondText = String(format: "%02d", Int(currentSeconds)%60)
            self.maxTimeLabel.text = "\(currentMinuteText):\(currentSecondText)"
        }
    }
}
