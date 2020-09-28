//
//  CustomDismissAnimationController.swift
//  TrellVods
//
//  Created by abhinay varma on 27/09/20.
//  Copyright © 2020 abhinay varma. All rights reserved.
//

import UIKit
//MARK:CustomDismissAnimation
class CustomDismissAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
       
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let containerView = transitionContext.containerView
       
        let snapshotView = fromViewController.view.resizableSnapshotView(from: CGRect(x: 0.0, y: 60.0, width: UIScreen.main.bounds.size.width , height: UIScreen.main.bounds.size.height - 160.0), afterScreenUpdates: false, withCapInsets: UIEdgeInsets.zero)
        snapshotView?.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 160.0)
        
        containerView.addSubview(snapshotView!)
        containerView.bringSubviewToFront(snapshotView!)
        
        fromViewController.view.removeFromSuperview()
        
        if fromViewController.isKind(of: VideoPlayerViewController.self) {
            let model = (fromViewController as! VideoPlayerViewController).model
            ((toViewController as? UINavigationController)?.topViewController as? VideosListingViewController)?.model = model
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            let xPosition = (UIScreen.main.bounds.size.width)/3
            let height = UIScreen.main.bounds.size.height
            snapshotView?.frame = CGRect(x: xPosition, y: height - (xPosition*2), width: xPosition * 2, height: xPosition*2)
        }, completion: {
            _ in
            transitionContext.completeTransition(true)
        })
        
    }
   
}

//MARK:CustomPresentingAnimation
class CustomPresentAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1.7
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let finalFrameForVC = transitionContext.finalFrame(for: toViewController)
        let containerView = transitionContext.containerView
        let bounds = UIScreen.main.bounds
        toViewController.view.frame = finalFrameForVC.offsetBy(dx: 0, dy: -bounds.size.height)
        containerView.addSubview(toViewController.view)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .curveLinear, animations: {
            fromViewController.view.alpha = 0.5
            toViewController.view.frame = finalFrameForVC
            }, completion: {
                _ in
                fromViewController.view.alpha = 1.0
                transitionContext.completeTransition(true)
        })
    }
}

