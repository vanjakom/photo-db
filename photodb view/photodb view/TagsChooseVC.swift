//
//  TagsChooseVC.swift
//  photodb view
//
//  Created by Vanja Komadinovic on 2/3/16.
//  Copyright © 2016 mungolab.com. All rights reserved.
//

import UIKit

class TagChooseCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel! = nil
    @IBOutlet weak var statusLabel: UILabel! = nil
}

class TagsChooseVC: UITableViewController {
    // in
    var imageRef: ImageRef! = nil
    var photoDbClient: PhotoDBClient! = nil
    
    var availableTags: [Tag]! = []
    var imageTags: Set<Tag>! = Set<Tag>()
    
    override func viewWillAppear(_ animated: Bool) {
        self.photoDbClient.listTags { (availableTagsO: [Tag]?) -> Void in
            if let availableTags = availableTagsO {
                self.photoDbClient.imageMetadata(self.imageRef) { (imageMetadataO: ImageMetadata?) -> Void in
                    if let imageMetadata = imageMetadataO {
                        let imageTags = Set<Tag>(imageMetadata.tags)
                        
                        // show only dynamic tags in tag choose menu, to make editing easier
                        self.availableTags = availableTags.filter({ (tag) -> Bool in
                            tag.name.hasPrefix("#")
                        })
                        self.imageTags = imageTags
                        self.tableView.reloadData()
                    } else {
                        print("Unable to load image metadata")
                    }
                }
            } else {
                print("Unable to load tags")
            }
        }
        
    }
    
    @IBAction func dismissClicked(_ sender: AnyObject) {
        self.dismiss(animated: false) { () -> Void in
            // empty
        }
    }
    
    @IBAction func okClicked(_ sender: AnyObject) {
        // todo save image tags back to server
        self.photoDbClient.updateImageTags(self.imageRef, tags: Array(imageTags)) { (imageMetadata: ImageMetadata?) -> Void in
            if (imageMetadata == nil) {
                print("Unable to update image tags")
            }
        }
        
        self.dismiss(animated: false) { () -> Void in
            // empty
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableTags.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // empty
        
        let tagChooseCell = self.tableView.dequeueReusableCell(withIdentifier: "TagChooseCell") as! TagChooseCell
        
        tagChooseCell.nameLabel.text = availableTags[(indexPath as NSIndexPath).row].name
        
        if (imageTags.contains(availableTags[(indexPath as NSIndexPath).row])) {
            tagChooseCell.statusLabel.backgroundColor = UIColor.red
        } else {
            tagChooseCell.statusLabel.backgroundColor = UIColor.green
        }
        
        return tagChooseCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (self.imageTags.contains(self.availableTags[(indexPath as NSIndexPath).row])) {
            self.imageTags.remove(self.availableTags[(indexPath as NSIndexPath).row])
        } else {
            self.imageTags.insert(self.availableTags[(indexPath as NSIndexPath).row])
        }
        self.tableView.reloadData()
    }
}
