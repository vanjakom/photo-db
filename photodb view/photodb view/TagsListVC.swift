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
    var rootTags: [Tag] = []
    
    override func viewDidLoad() {
        //self.photoDbClient = SimplePhotoDBClient(serverUri: "10.255.198.81:8988")
        if (self.photoDbClient == nil) {
            self.photoDbClient = SimplePhotoDBClient(serverUri: "192.168.88.32:8988")
        }
        //self.photoDbClient = SimplePhotoDBClient(serverUri: "127.0.0.1:8988")
        
        let viewBarButton = UIBarButtonItem(title: "View", style: .plain, target: self, action: #selector(viewTagsPressed))
        self.navigationItem.rightBarButtonItem = viewBarButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (self.rootTags.count == 0) {
            self.photoDbClient.listTags { (tagsList: [Tag]?) -> Void in
                if let tags: [Tag] = tagsList {
                    self.tags = tags
                    self.tableView.reloadData()
                }
            }
        } else {
            self.navigationItem.title = self.rootTags.last?.name
            self.photoDbClient.tagView(self.rootTags, callback: { (_, tags: [Tag]?) in
                if let tags = tags {
                    self.tags = tags
                    self.tableView.reloadData()
                } else {
                    print("[ERROR] TagsListVC:viewWillAppear unable to retrieve tags")
                }
            })
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _: Int = tags?.count {
            return tags!.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "TagNameCell") as! TagNameCell

        cell.nameLabel.text = self.tags![(indexPath as NSIndexPath).row].name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tagListVC = self.storyboard?.instantiateViewController(withIdentifier: "TagsListVC") as! TagsListVC
        tagListVC.photoDbClient = self.photoDbClient
        var newRootTags = self.rootTags
        newRootTags.append(self.tags![indexPath.row])
        tagListVC.rootTags = newRootTags
        
        self.navigationController?.pushViewController(tagListVC, animated: false)
        
        /*
        self.present(tagThumbnailViewVC, animated: false) { 
            // empty
        }
        */
        
        /*
        let tagViewVC = self.storyboard?.instantiateViewControllerWithIdentifier("TagViewVC") as! TagViewVC
        
        tagViewVC.tag = tags![indexPath.row].name
        
        self.presentViewController(tagViewVC, animated: false) { () -> Void in
            // empty
        }
        */
    }
    
    func viewTagsPressed() -> Void {
        let tagThumbnailViewVC = self.storyboard?.instantiateViewController(withIdentifier: "TagThumbnailViewVC") as! TagThumbnailViewVC
        tagThumbnailViewVC.photoDbClient = self.photoDbClient
        tagThumbnailViewVC.tags = self.rootTags
        
        self.navigationController?.pushViewController(tagThumbnailViewVC, animated: false)
    }
}
