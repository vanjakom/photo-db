//
//  TagViewVC.swift
//  photodb view
//
//  Created by Vanja Komadinovic on 1/23/16.
//  Copyright © 2016 mungolab.com. All rights reserved.
//

import UIKit

class TagViewVC: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var commandStatus: UILabel!
    
    // in
    var tag: String! = nil
    
    var photoDbClient: PhotoDBClient! = nil
    var imageRefs: [ImageRef]! = []
    var currentImage: Int = -1
    
    override func viewDidAppear(animated: Bool) {
        // todo load list of images
        // retrieve first image and assing to imageView
        
        self.photoDbClient = SimplePhotoDBClient(serverUri: "192.168.88.32:8988")
        
        self.photoDbClient.tagView([Tag(name: tag)], callback: { (imageRefs: [ImageRef]?) -> Void in
            guard let _: [ImageRef] = imageRefs else {
                print("unable to recieve image ids")
                self.displayCommandStatus("unable to retrieve image ids")
                return
            }
            
            print("image ids recieved")
            
            self.imageRefs = imageRefs!
            self.currentImage = 0
            
            if (self.imageRefs.count > 0) {
                self.displayImage()
            } else {
                self.displayCommandStatus("no images")
            }
        })
    }
    
    /*
    @IBAction func imageViewSwipeLeft(sender: UISwipeGestureRecognizer) {
        if (sender.state == .Ended) {
            print("swipe left")
            if (self.currentImage < self.imageRefs.count - 1) {
                self.currentImage++
                displayImage()
            } else {
                print("ignoring")
            }
        }
    }
    
    @IBAction func imageViewSwipeRight(sender: UISwipeGestureRecognizer) {
        if (sender.state == .Ended) {
            print("swipe right")
            if (self.currentImage > 0) {
                self.currentImage--
                displayImage()
            } else {
                print("ignoring")
            }
        }
    }
    */
    
    // disabled
    /*
    @IBAction func tagGestureOnImageView(sender: UITapGestureRecognizer) {
        
        
        if (sender.state == UIGestureRecognizerState.Ended) {
            print("tap")
            let location = sender.locationInView(self.imageView)
            if location.x > self.imageView.bounds.width / 2 {
                print("tap right")
                if (self.currentImage < self.imageRefs.count - 1) {
                    self.currentImage++
                    displayImage()
                } else {
                    print("ignoring")
                }
            } else {
                print("tap left")
                if (self.currentImage > 0) {
                    self.currentImage--
                    displayImage()
                } else {
                    print("ignoring")
                }
            }
        }
        
        
        
    }
    */
    
    @IBAction func tapGestureOnImageView(sender: UITapGestureRecognizer) {
        if (sender.state == .Ended) {
            print("tap gesture")
            let position = sender.locationInView(self.imageView)
            print(position)
            let centarX = self.imageView.bounds.width / 2
            let maxTopY = self.imageView.bounds.height / 5
            let minBottomY = self.imageView.bounds.height  / 5 * 4
            
            if (position.y < maxTopY) {
                //displayCommandStatus("top")
                self.dismissViewControllerAnimated(false, completion: { () -> Void in
                    // empty
                })
            } else if (position.y > minBottomY) {
                displayCommandStatus("bottom")
                
                let tagsChooseVC = self.storyboard?.instantiateViewControllerWithIdentifier("TagsChooseVC") as! TagsChooseVC
                tagsChooseVC.modalPresentationStyle = .FormSheet
                tagsChooseVC.photoDbClient = self.photoDbClient
                tagsChooseVC.imageRef = self.imageRefs[self.currentImage]
                
                self.presentViewController(tagsChooseVC, animated: false, completion: {
                    // empty
                })
            } else {
                if (position.x > centarX) {
                    if (self.imageRefs.count > 0) {
                        if (self.currentImage < self.imageRefs.count - 1) {
                            self.currentImage++
                            displayImage()
                            displayCommandStatus("\(self.currentImage + 1) of \(self.imageRefs.count)")
                        } else {
                            displayCommandStatus("\(self.currentImage + 1) of \(self.imageRefs.count)")
                        }
                    } else {
                        displayCommandStatus("no images")
                    }
                } else {
                    if (self.imageRefs.count > 0) {
                        print("swipe right")
                        if (self.currentImage > 0) {
                            self.currentImage--
                            displayImage()
                            displayCommandStatus("\(self.currentImage + 1) of \(self.imageRefs.count)")
                        } else {
                            displayCommandStatus("\(self.currentImage + 1) of \(self.imageRefs.count)")
                        }
                    } else {
                        displayCommandStatus("no images")
                    }
                }
            }
        }
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        if let _: UIImage = self.imageView.image {
            let floorAspectImage = floor(self.imageView.image!.size.width / self.imageView.image!.size.height)
            let floorAspectImageView = floor(self.imageView.bounds.width / self.imageView.bounds.height)
            if (floorAspectImage - floorAspectImageView == 0) {
                self.imageView.contentMode = UIViewContentMode.ScaleAspectFill
            } else {
                self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
            }
        }
    }
    
    private func displayImage() {
        self.photoDbClient.previewImage(self.imageRefs[self.currentImage]) { (imageData: NSData?) -> Void in
            guard let _: NSData = imageData else {
                print("unable to retireve image: " + self.imageRefs[self.currentImage].id)
                return
            }
            
            print("setting image")
            
            let image = UIImage(data: imageData!)

            dispatch_async(dispatch_get_main_queue(), {
                let floorAspectImage = floor(image!.size.width / image!.size.height)
                let floorAspectImageView = floor(self.imageView.bounds.width / self.imageView.bounds.height)
                if (floorAspectImage - floorAspectImageView == 0) {
                    self.imageView.contentMode = UIViewContentMode.ScaleAspectFill
                } else {
                    self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
                }
                
                self.imageView.image = image
            })            
        }
    }
    
    private func displayCommandStatus(status: String) {
        self.commandStatus.text = status
        self.commandStatus.hidden = false
        
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "commandStatusTimer", userInfo: nil, repeats: false)
    }
    
    func commandStatusTimer() {
        dispatch_async(dispatch_get_main_queue(), {
             self.commandStatus.hidden = true
        })
    }
}




