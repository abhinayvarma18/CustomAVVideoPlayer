//
//  VideosListingViewModel.swift
//  TrellVods
//
//  Created by abhinay varma on 28/09/20.
//  Copyright © 2020 abhinay varma. All rights reserved.
//

import Foundation
import Photos
import UIKit

struct VideoItem {
    var path:NSURL?
    var image:UIImage?
    var name:Int?
    var data:NSData?
    var currentProgress:Double?
    var isBookmarked:Bool
}

class VideosListingViewModel:NSObject {
    var videoItems:[VideoItem] = []
    var dg = DispatchGroup()
    var videoAssets:[URL] = []
    let customDismissAnimationController = CustomDismissAnimationController()
    let customPresentAnimationController = CustomPresentAnimationController()
    var videoCount = 0
    
    override init() {
        super.init()
    }
    
    convenience init(player:Int) {
        self.init()
    }
    
    func fetchAllVideos(_ completion:@escaping(()->())) {
           let fetchOptions = PHFetchOptions()
           fetchOptions.predicate = NSPredicate(format: "mediaType = %d ", PHAssetMediaType.video.rawValue )

           let allVideo = PHAsset.fetchAssets(with: .video, options: fetchOptions)
           videoCount = allVideo.count
           allVideo.enumerateObjects { (asset, index, bool) in
               let imageManager = PHCachingImageManager()
               imageManager.allowsCachingHighQualityImages = true
               imageManager.requestAVAsset(forVideo: asset, options: nil, resultHandler: { (asset, audioMix, info) in
                   if asset != nil {
                       let avasset = asset as! AVURLAsset
                       let urlVideo = avasset.url
                       self.videoAssets.append(urlVideo)
                       if self.videoCount == self.videoAssets.count {
                           self.reloadVideos(completion)
                       }
                   }
               })
           }
    }
    
    func reloadVideos(_ completion:@escaping(()->())) {
           for asset in videoAssets {
               let url = asset
               dg.enter()
               let image = imagePreview(from: url, in: 2.0)
            let item = VideoItem(path: url as NSURL, image: image, name: videoItems.count + 1, data: nil, currentProgress: nil, isBookmarked: false)
               videoItems.append(item)
           }
           
           dg.notify(queue: DispatchQueue.main) {
               self.videoItems.sort { (item1, item2) -> Bool in
                   return item1.name ?? 1 < item2.name ?? 0
               }
             completion()
           }
    }
    
    func imagePreview(from moviePath: URL, in seconds: Double) -> UIImage? {
        let timestamp = CMTime(seconds: seconds, preferredTimescale: 60)
        let asset = AVURLAsset(url: moviePath)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        guard let imageRef = try? generator.copyCGImage(at: timestamp, actualTime: nil) else {
            dg.leave()
            return nil
        }
        dg.leave()
        return UIImage(cgImage: imageRef)
    }
}

extension VideosListingViewModel:UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return customPresentAnimationController as UIViewControllerAnimatedTransitioning
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return customDismissAnimationController as UIViewControllerAnimatedTransitioning
    }
}
