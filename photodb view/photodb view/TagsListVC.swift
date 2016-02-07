//
//  TagsListVC.swift
//  photodb view
//
//  Created by Vanja Komadinovic on 2/3/16.
//  Copyright © 2016 mungolab.com. All rights reserved.
//

import UIKit

class TagNameCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
}

class TagsListVC: UITableViewController {
    var photoDbClient: PhotoDBClient! = nil
    
    var tags: [Tag]? = nil

    override func viewWillAppear(animated: Bool) {
        self.photoDbClient = SimplePhotoDBClient(serverUri: "192.168.88.32:8988")

        self.photoDbClient.listTags { (tagsList: [Tag]?) -> Void in
            if let tags: [Tag] = tagsList {
                self.tags = tags
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _: Int = tags?.count {
            return tags!.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("TagNameCell") as! TagNameCell

        cell.nameLabel.text = self.tags![indexPath.row].name
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tagViewVC = self.storyboard?.instantiateViewControllerWithIdentifier("TagViewVC") as! TagViewVC
        
        tagViewVC.tag = tags![indexPath.row].name
        
        self.presentViewController(tagViewVC, animated: false) { () -> Void in
            // empty
        }
    }
}
