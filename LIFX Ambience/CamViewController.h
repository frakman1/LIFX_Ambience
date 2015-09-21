//
//  myCamViewController.h
//  GameFX
//
//  Created by alnaumf on 6/18/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

//turn this off for simulator runs



#import <UIKit/UIKit.h>
#if !(TARGET_IPHONE_SIMULATOR)
#import "ImageCropView.h"
#endif

#if !(TARGET_IPHONE_SIMULATOR)
@interface CamViewController : UIViewController <ImageCropViewControllerDelegate>
#else
@interface CamViewController : UIViewController
#endif
{
#if !(TARGET_IPHONE_SIMULATOR)
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

@property (weak, nonatomic) IBOutlet UISlider *powerLevel;

@property (nonatomic) NSMutableArray *inputLights;


@end