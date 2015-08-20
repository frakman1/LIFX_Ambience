//
//  myCamViewController.h
//  GameFX
//
//  Created by alnaumf on 6/18/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageCropView.h" 

@interface CamViewController : UIViewController <ImageCropViewControllerDelegate>
{
    ImageCropView* imageCropView;
    UIImage* myimage;
    UIImage* gCroppedImage;
    //IBOutlet UIImageView *imageView;
    CGRect cropDimension;
    //UIView* paintView;
    //UIImageView *overlayImageView;
    
}



- (IBAction)btnMicPressed:(id)sender;
- (IBAction)btnLockPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *btnMic;
@property (weak, nonatomic) IBOutlet UIButton *btnLock;
@property (weak, nonatomic) IBOutlet UIButton *btnCrop;
//@property (weak, nonatomic) IBOutlet UIView *viewCropSquare;

@end
