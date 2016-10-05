//
//  TagThumbnailViewVC.swift
//  photodb view
//
//  Created by Vanja Komadinovic on 9/24/16.
//  Copyright © 2016 mungolab.com. All rights reserved.
//

import Foundation
import UIKit

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView! = nil
}

class TagThumbnailViewVC: UICollectionViewController {
    var photoDbClient: PhotoDBClient! = nil
    var tags: [Tag]! = nil
    
    var imageRefs: [ImageRef]! = nil
    
    override func viewWillAppear(_ animated: Bool) {
        // reset image refs on each appear
        self.imageRefs = []
        
        // todo add loading section
        
        self.photoDbClient.tagView(self.tags) { (imageRefs: [ImageRef]?, _: [Tag]?) in
            if let imageRefs = imageRefs {
                self.imageRefs = imageRefs
                print("TagThumbnailViewVC:viewWillAppear number of images \(self.imageRefs.count)")
                
                self.collectionView?.reloadData()
            } else {
                print("[ERROR] TagThumbnailViewVC:viewWillAppear unable to load images")
            }
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageRefs.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        
        cell.backgroundColor = UIColor.white
        
        self.photoDbClient.thumbnailSquareImage(self.imageRefs[(indexPath as NSIndexPath).row]) { (thumbnailData: Data?) in
            if let thumbnailData = thumbnailData {
                let image = UIImage(data: thumbnailData)
                cell.imageView.image = image
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected image \(indexPath.row)");
        
        let tagViewVC = self.storyboard?.instantiateViewController(withIdentifier: "TagViewVC") as! TagViewVC
        tagViewVC.photoDbClient = self.photoDbClient
        tagViewVC.imageRefs = self.imageRefs
        tagViewVC.currentImage = indexPath.row
        
        self.present(tagViewVC, animated: false) { 
            // empty
        }
    }
}
