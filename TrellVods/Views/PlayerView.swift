//
//  PlayerView.swift
//  TrellVods
//
//  Created by abhinay varma on 24/09/20.
//  Copyright © 2020 abhinay varma. All rights reserved.
//

import AVFoundation
import UIKit

class PlayerView: UIView {
    
override final class var layerClass: AnyClass {
    return AVPlayerLayer.self
}
weak var player:AVPlayer? {
    set {
        if let layer = layer as? AVPlayerLayer {
            layer.player = newValue
        }
    }
    get {
        if let layer = layer as? AVPlayerLayer {
            return layer.player
        } else {
            return nil
        }
    }
}
}
