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
    @IBOutlet weak var tagsLabel: UILabel!

    var photoDbClient: PhotoDBClient! = nil
    var imageRefs: [ImageRef]! = nil
    
    //var currentImage: Int = -1
    var currentImage: Int = 0
    
    override func viewDidAppear(_ animated: Bool) {
        // todo load list of images
        // retrieve first image and assing to imageView
        
        //self.photoDbClient = SimplePhotoDBClient(serverUri: "192.168.88.32:8988")
        //self.photoDbClient = SimplePhotoDBClient(serverUri: "127.0.0.1:8988")


        /*
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
         */

        displayImage()
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
    
    @IBAction func tapGestureOnImageView(_ sender: UITapGestureRecognizer) {
        if (sender.state == .ended) {
            print("tap gesture")
            let position = sender.location(in: self.imageView)
            print(position)
            let centarX = self.imageView.bounds.width / 2
            let maxTopY = self.imageView.bounds.height / 5
            let minBottomY = self.imageView.bounds.height  / 5 * 4
            
            if (position.y < maxTopY) {
                //displayCommandStatus("top")
                self.dismiss(animated: false, completion: { () -> Void in
                    // empty
                })
            } else if (position.y > minBottomY) {
                displayCommandStatus("bottom")
                
                let tagsChooseVC = self.storyboard?.instantiateViewController(withIdentifier: "TagsChooseVC") as! TagsChooseVC
                tagsChooseVC.modalPresentationStyle = .formSheet
                tagsChooseVC.photoDbClient = self.photoDbClient
                tagsChooseVC.imageRef = self.imageRefs[self.currentImage]
                
                self.present(tagsChooseVC, animated: false, completion: {
                    // empty
                })
            } else {
                if (position.x > centarX) {
                    if (self.imageRefs.count > 0) {
                        if (self.currentImage < self.imageRefs.count - 1) {
                            self.currentImage += 1
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
                            self.currentImage -= 1
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
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if let _: UIImage = self.imageView.image {
            let floorAspectImage = floor(self.imageView.image!.size.width / self.imageView.image!.size.height)
            let floorAspectImageView = floor(self.imageView.bounds.width / self.imageView.bounds.height)
            if (floorAspectImage - floorAspectImageView == 0) {
                self.imageView.contentMode = UIViewContentMode.scaleAspectFill
            } else {
                self.imageView.contentMode = UIViewContentMode.scaleAspectFit
            }
        }
    }
    
    fileprivate func displayImage() {
        self.photoDbClient.previewImage(self.imageRefs[self.currentImage]) { (imageData: Data?) -> Void in
            guard let _: Data = imageData else {
                print("unable to retireve image: " + self.imageRefs[self.currentImage].id)
                return
            }
            
            print("setting image")
            
            let image = UIImage(data: imageData!)

            DispatchQueue.main.async(execute: {
                let floorAspectImage = floor(image!.size.width / image!.size.height)
                let floorAspectImageView = floor(self.imageView.bounds.width / self.imageView.bounds.height)
                if (floorAspectImage - floorAspectImageView == 0) {
                    self.imageView.contentMode = UIViewContentMode.scaleAspectFill
                } else {
                    self.imageView.contentMode = UIViewContentMode.scaleAspectFit
                }
                
                self.imageView.image = image
            })            
        }
    }
    
    fileprivate func displayCommandStatus(_ status: String) {
        self.commandStatus.text = status
        self.commandStatus.isHidden = false
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(TagViewVC.commandStatusTimer), userInfo: nil, repeats: false)
    }
    
    func displayTags(tags: [String]) {
        self.tagsLabel.text = tags.joined(separator: ",")
        self.tagsLabel.isHidden = false
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(TagViewVC.tagsLabelTimer), userInfo: nil, repeats: false)
    }
    
    func commandStatusTimer() {
        DispatchQueue.main.async(execute: {
             self.commandStatus.isHidden = true
        })
    }
    
    func tagsLabelTimer() {
        DispatchQueue.main.async {
            self.tagsLabel.isHidden = true
        }
    }
}




