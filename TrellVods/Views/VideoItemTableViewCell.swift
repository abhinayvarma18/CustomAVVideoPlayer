//
//  VideoItemTableViewCell.swift
//  TrellVods
//
//  Created by abhinay varma on 24/09/20.
//  Copyright © 2020 abhinay varma. All rights reserved.
//

import UIKit

class VideoItemTableViewCell: UITableViewCell {
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var bookmarkImage: UIImageView!
    
    let unselectedBookmarkImage = UIImage(named: Constants.unselectedBookmark)
    let selectedBookmarkImage = UIImage(named: Constants.selectedBookmark)
    var storedModel:VideoItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let gesture = UITapGestureRecognizer.init(target: self, action: #selector(bookmarkImageClicked))
        bookmarkImage.addGestureRecognizer(gesture)
        bookmarkImage.isUserInteractionEnabled = true
    }
    
    @objc func bookmarkImageClicked() {
        if bookmarkImage.image == selectedBookmarkImage {
            bookmarkImage.image = unselectedBookmarkImage
            DatabaseManager.instance.deleteBookmark(storedModel!)
            //remove from bookmark
        }else {
            bookmarkImage.image = selectedBookmarkImage
            DatabaseManager.instance.saveBookmark(storedModel!)
            //add in bookmark
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func updateCell(_ model:VideoItem) {
        cellImage.image = model.image
        let value = DatabaseManager.instance.checkIfModelIsBookmark(model)
        bookmarkImage.image = value ? selectedBookmarkImage : unselectedBookmarkImage
        storedModel = model
    }
}
