//
//  VideosListingViewController.swift
//  TrellVods
//
//  Created by abhinay varma on 24/09/20.
//  Copyright © 2020 abhinay varma. All rights reserved.
//

import UIKit

class VideosListingViewController: UIViewController {
    //MARK:Properties and outlets
    @IBOutlet weak var videosTableView: UITableView!
    @IBOutlet weak var titleVCLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var bookmarkButton: UIButton!
    
    let viewModel = VideosListingViewModel()
    
    var clickFinished = true
    var isBookMarkScreen = false
    
    lazy var playerView:PlayerView? = {
        let playerView = PlayerView()
        let xPosition = UIScreen.main.bounds.size.width/3
        let height = UIScreen.main.bounds.size.height
        playerView.frame = CGRect(x:xPosition, y: height - xPosition*2, width:xPosition*2, height:xPosition*2)
        playerView.isUserInteractionEnabled = true
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(panGesture:)))
        playerView.addGestureRecognizer(gesture)
        let newGesture = UITapGestureRecognizer.init(target: self, action: #selector(playerClicked))
        playerView.addGestureRecognizer(newGesture)
        return playerView
    }()
    
    lazy var videoPlayer:VideoPlayer? = {
        if let path = model?.path {
            let newPlayer = VideoPlayer(urlAsset: path, view: playerView!)
            newPlayer.delegate = self
            return newPlayer
        }
        return nil
    }()
    
    lazy var crossButton:UIButton? = {
        let button = UIButton(frame: CGRect(x: 8.0, y: 8.0, width: 25.0, height: 25.0))
        if let image = UIImage(named: Constants.closeButtonImage) {
            button.setImage(image, for: .normal)
            button.tintColor = UIColor.white
        }
        button.isHidden = true
        button.addTarget(self, action: #selector(crossButtonClicked), for: .allTouchEvents)
        return button
    }()
    
    lazy var fullScreenButton:UIButton? = {
        let button = UIButton(frame: CGRect(x: (playerView?.frame.size.width)! - 8.0, y: 8.0, width: 25.0, height: 25.0))
        if let image = UIImage(named: Constants.fullScreenButtonImage) {
            button.setImage(image, for: .normal)
            button.tintColor = UIColor.white
        }
        button.isHidden = true
        button.addTarget(self, action: #selector(fullScreenButtonClicked), for: .allTouchEvents)
        return button
    }()
    
    var model:VideoItem? {
        didSet {
            if model != nil {
                playerView?.addSubview(crossButton!)
                playerView?.addSubview(fullScreenButton!)
                view.addSubview(playerView!)
                playerView!.bringSubviewToFront(crossButton!)
                self.videoPlayer?.progress = self.model?.currentProgress ?? 0.0
                self.videoPlayer?.path = model?.path
            }
        }
    }
    
    //MARK:Initial Setup on load
    override func viewDidLoad() {
        super.viewDidLoad()
        if isBookMarkScreen {
            titleVCLabel.text = Constants.bookmarkedScreenTitle
        }else {
            titleVCLabel.text = Constants.videosScreenTitle
        }
        backButton.isHidden = !isBookMarkScreen
        bookmarkButton.isHidden = isBookMarkScreen
        setupTableView()
        if !isBookMarkScreen {
            viewModel.fetchAllVideos({ [weak self] () in
                self?.videosTableView.reloadData()
            })
        }else {
            self.videosTableView.reloadData()
        }
    }
    
    private func setupTableView() {
        videosTableView.delegate = self
        videosTableView.dataSource = self
        videosTableView.register(UINib(nibName: Constants.cellIdentifierForVideoListing, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifierForVideoListing)
    }
    
    //MARK:Button Actions On Video Player (Cross and FullScreen)
    @objc func crossButtonClicked() {
        clearCache()
    }
    
    @objc func fullScreenButtonClicked() {
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Constants.videoPlayerVCName) as? VideoPlayerViewController {
            var newModel = model
            newModel?.currentProgress = (videoPlayer?.getTime() ?? 0.0)/(videoPlayer?.assetDuration ?? 1.0)
            viewController.model = newModel
            viewController.transitioningDelegate = viewModel
            clearCache()
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    //MARK:Gesture Methods For VideoPlayer
    @objc func handlePanGesture(panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)
        panGesture.setTranslation(CGPoint.zero, in: view)
        let panView = panGesture.view as! PlayerView
        panView.center = CGPoint(x: panView.center.x+translation.x, y: panView.center.y+translation.y)
        panView.isMultipleTouchEnabled = true
        panView.isUserInteractionEnabled = true
    }
    
    @objc func playerClicked() {
        if clickFinished {
            self.clickFinished = false
            self.crossButton?.isHidden = false
            self.fullScreenButton?.isHidden = false
            let constantValueX:CGFloat = 30.0
            let constantValueY:CGFloat = 15.0
            let originalFrame = playerView?.frame
            var frame = playerView?.frame
            frame?.origin.x -= constantValueX
            frame?.size.width += constantValueX
            frame?.origin.y -= constantValueY
            frame?.size.height += constantValueY
            self.playerView?.frame = frame ?? CGRect.zero
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.crossButton?.isHidden = true
                self.fullScreenButton?.isHidden = true
                self.playerView?.frame = originalFrame ?? CGRect.zero
                self.clickFinished = true
            }
        }
    }
    
    //MARK:Video Player Cleanup
    fileprivate func clearCache() {
        playerView?.player?.pause()
        videoPlayer?.cleanUp()
        playerView?.removeFromSuperview()
        model = nil
    }
    
    @IBAction func bookmarkButtonClicked(_ sender: Any) {
        DatabaseManager.instance.fetchBookmarks { (items) in
            if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Constants.videoListingVCName) as? VideosListingViewController {
                viewController.viewModel.videoItems = items ?? []
                viewController.isBookMarkScreen = true
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
    @IBAction func backButtonClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}


//MARK:TableViewDelegate and Datasource
extension VideosListingViewController:UITableViewDelegate,UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.videoItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0.0
        }
        return 8.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return UIView()
        }
        let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: 6.0))
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        return view
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifierForVideoListing, for: indexPath) as? VideoItemTableViewCell
        cell?.updateCell(self.viewModel.videoItems[indexPath.section])
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if model != nil && model?.path != nil {
            clearCache()
            model = self.viewModel.videoItems[indexPath.section]
            return
        }
        let model = self.viewModel.videoItems[indexPath.section]
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Constants.videoPlayerVCName) as? VideoPlayerViewController {
            viewController.model = model
            viewController.transitioningDelegate = viewModel
            self.present(viewController, animated: true, completion: nil)
        }
    }
}

//MARK:VideoPlayer Delegate
extension VideosListingViewController:VideoPlayerDelegate {
    func readyToPlay() {
        self.videoPlayer?.seekToPosition(seconds: (self.videoPlayer?.assetDuration ?? 0.0) * (self.model?.currentProgress ?? 0.0))
    }
}
