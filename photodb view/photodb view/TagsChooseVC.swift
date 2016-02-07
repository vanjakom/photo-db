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
    
    override func viewWillAppear(animated: Bool) {
        self.photoDbClient.listTags { (availableTagsO: [Tag]?) -> Void in
            if let availableTags = availableTagsO {
                self.photoDbClient.imageMetadata(self.imageRef) { (imageMetadataO: ImageMetadata?) -> Void in
                    if let imageMetadata = imageMetadataO {
                        let imageTags = Set<Tag>(imageMetadata.tags)
                        
                        self.availableTags = availableTags
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
    
    @IBAction func dismissClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(false) { () -> Void in
            // empty
        }
    }
    
    @IBAction func okClicked(sender: AnyObject) {
        // todo save image tags back to server
        self.photoDbClient.updateImageTags(self.imageRef, tags: Array(imageTags)) { (imageMetadata: ImageMetadata?) -> Void in
            if (imageMetadata == nil) {
                print("Unable to update image tags")
            }
        }
        
        self.dismissViewControllerAnimated(false) { () -> Void in
            // empty
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableTags.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // empty
        
        let tagChooseCell = self.tableView.dequeueReusableCellWithIdentifier("TagChooseCell") as! TagChooseCell
        
        tagChooseCell.nameLabel.text = availableTags[indexPath.row].name
        
        if (imageTags.contains(availableTags[indexPath.row])) {
            tagChooseCell.statusLabel.backgroundColor = UIColor.redColor()
        } else {
            tagChooseCell.statusLabel.backgroundColor = UIColor.greenColor()
        }
        
        return tagChooseCell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (self.imageTags.contains(self.availableTags[indexPath.row])) {
            self.imageTags.remove(self.availableTags[indexPath.row])
        } else {
            self.imageTags.insert(self.availableTags[indexPath.row])
        }
        self.tableView.reloadData()
    }
}
