//
//  VideoPlayer.swift
//  TrellVods
//
//  Created by abhinay varma on 24/09/20.
//  Copyright © 2020 abhinay varma. All rights reserved.
//
import AVFoundation
import Foundation

@objc protocol VideoPlayerDelegate:AnyObject {
  @objc optional func downloadedProgress(progress:Double)
  @objc optional  func readyToPlay()
  @objc optional  func didUpdateProgress(progress:Double)
  @objc optional func didFinishPlayItem()
  @objc optional func didFailPlayToEnd()
}

class VideoPlayer : NSObject {
    private var observer1: NSKeyValueObservation?
    var assetPlayer:AVPlayer?
    var playerItem:AVPlayerItem?
    var urlAsset:AVURLAsset?
    private var videoOutput:AVPlayerItemVideoOutput?

    var assetDuration:Double = 0
    private weak var playerView:PlayerView?

    private var autoRepeatPlay:Bool = true
    private var autoPlay:Bool = true

    weak var delegate:VideoPlayerDelegate?
    var progress:Double?

    var playerRate:Float = 1 {
        didSet {
            if let player = assetPlayer {
                player.rate = playerRate > 0 ? playerRate : 0.0
            }
        }
    }

    var volume:Float = 1.0 {
        didSet {
            if let player = assetPlayer {
                player.volume = volume > 0 ? volume : 0.0
            }
        }
    }
    
    var path:NSURL? {
        didSet {
             initialSetupWithURL(url: path!)
             prepareToPlay()
        }
    }

    // MARK: - Init

    convenience init(urlAsset:NSURL, view:PlayerView, startAutoPlay:Bool = true, repeatAfterEnd:Bool = false) {
        self.init()

        playerView = view
        autoPlay = startAutoPlay
        autoRepeatPlay = repeatAfterEnd

        if let playView = playerView, let playerLayer = playView.layer as? AVPlayerLayer {
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }
        initialSetupWithURL(url: urlAsset)
        prepareToPlay()
    }

    override init() {
        super.init()
    }

    // MARK: - Public

    func isPlaying() -> Bool {
        if let player = assetPlayer {
            return player.rate > 0
        } else {
            return false
        }
    }

    func seekToPosition(seconds:Float64) {
        if let player = assetPlayer {
            pause()
            if let timeScale = player.currentItem?.asset.duration.timescale {
                player.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: timeScale), completionHandler: { (complete) in
                    self.play()
                })
            }
        }
    }

    func pause() {
        if let player = assetPlayer {
            player.pause()
        }
    }

    func play() {
        if let player = assetPlayer {
            if (player.currentItem?.status == .readyToPlay) {
                player.play()
                player.rate = playerRate
            }
        }
    }

    func cleanUp() {
        self.observer1?.invalidate()
        self.observer1 = nil
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Private

    func prepareToPlay() {
        let keys = ["tracks"]
        if let asset = urlAsset {
            asset.loadValuesAsynchronously(forKeys: keys) {
                DispatchQueue.main.async {
                    self.startLoading()
                }
            }
        }
    }

    private func startLoading(){
        var error:NSError?
        guard let asset = urlAsset else {return}
        let status:AVKeyValueStatus = asset.statusOfValue(forKey: "tracks", error: &error)

        if status == AVKeyValueStatus.loaded {
            assetDuration = CMTimeGetSeconds(asset.duration)

            let videoOutputOptions = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)]
            videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: videoOutputOptions)
            playerItem = AVPlayerItem(asset: asset)

            if let item = playerItem {
                self.observer1 = item.observe(\.status, options: [.new, .old], changeHandler: { [weak self](playerItem, change) in
                    if playerItem.status == .readyToPlay {
                        //Do your work here
                        self?.playerDidChangeStatus(status: .readyToPlay)
                    }
                })

                NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(didFailedToPlayToEnd), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: nil)

                if let output = videoOutput {
                    item.add(output)

                    item.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.varispeed
                    assetPlayer = AVPlayer(playerItem: item)
                    if let player = assetPlayer {
                        player.rate = playerRate
                    }

                    addPeriodicalObserver()
                    if let playView = playerView, let layer = playView.layer as? AVPlayerLayer {
                        layer.player = assetPlayer
                        print("player created")
                    }
                }
            }
        }
    }

    private func addPeriodicalObserver() {
        let timeInterval = CMTimeMake(value: 1, timescale: 1)

        if let player = assetPlayer {
            player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: { (time) in
                self.playerDidChangeTime(time: time)
            })
        }
    }

    private func playerDidChangeTime(time:CMTime) {
        if let player = assetPlayer {
            let timeNow = CMTimeGetSeconds(player.currentTime())
            let progress = timeNow / assetDuration

            delegate?.didUpdateProgress?(progress: progress)
        }
    }

    @objc private func playerItemDidReachEnd() {
        delegate?.didFinishPlayItem?()

        if let player = assetPlayer {
            player.seek(to: CMTime.zero)
            if autoRepeatPlay == true {
                play()
            }
        }
    }

    @objc private func didFailedToPlayToEnd() {
        delegate?.didFailPlayToEnd?()
    }

    private func playerDidChangeStatus(status:AVPlayer.Status) {
        if status == .failed {
            print("Failed to load video")
        } else if status == .readyToPlay, let player = assetPlayer {
            volume = player.volume
            delegate?.readyToPlay?()

            if autoPlay == true && player.rate == 0.0 {
                play()
            }
        }
    }

    private func moviewPlayerLoadedTimeRangeDidUpdated(ranges:Array<NSValue>) {
        var maximum:TimeInterval = 0
        for value in ranges {
            let range:CMTimeRange = value.timeRangeValue
            let currentLoadedTimeRange = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration)
            if currentLoadedTimeRange > maximum {
                maximum = currentLoadedTimeRange
            }
        }
        let timeNow = CMTimeGetSeconds(assetPlayer!.currentTime())
        let progress:Double = assetDuration == 0 ? 0.0 : Double(timeNow) / Double(maximum)

       // delegate?.downloadedProgress(progress: progress)
    }

    deinit {
        cleanUp()
    }

     func initialSetupWithURL(url:NSURL) {
        let options = [AVURLAssetPreferPreciseDurationAndTimingKey : true]
        urlAsset = AVURLAsset(url: url as URL, options: options)
    }
    
    func getTime() -> Double {
        return CMTimeGetSeconds(assetPlayer!.currentTime())
    }

}
