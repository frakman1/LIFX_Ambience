//
//  myCamViewController.h
//  GameFX
//
//  Created by alnaumf on 6/18/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

//turn this off for simulator runs
#define CROP 1

#import <UIKit/UIKit.h>
#if (CROP==1)
#import "ImageCropView.h"
#endif

#if (CROP==1)
@interface CamViewController : UIViewController <ImageCropViewControllerDelegate>
#else
@interface CamViewController : UIViewController
#endif
{
#if (CROP==1)
    ImageCropView* imageCropView;
#endif
    UIImage* myimage;
    UIImage* gCroppedImage;
    //IBOutlet UIImageView *imageView;
    //CGRect cropDimension;
    //UIView* paintView;
    //UIImageView *overlayImageView;
    
}



- (IBAction)btnMicPressed:(id)sender;
- (IBAction)btnLockPressed:(id)sender;
- (IBAction)btnHelpPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *btnMic;
@property (weak, nonatomic) IBOutlet UIButton *btnLock;
@property (weak, nonatomic) IBOutlet UIButton *btnCrop;
@property (weak, nonatomic) IBOutlet UIButton *btnHelp;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *barbtnHelp;


//@property (weak, nonatomic) IBOutlet UIView *viewCropSquare;
//@property (assign,nonatomic) CGRect cropDimension;

@end