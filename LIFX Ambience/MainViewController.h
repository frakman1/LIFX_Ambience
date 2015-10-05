//
//  MainViewController.h
//  LIFX Ambience
//
//  Created by alnaumf on 6/23/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JDFTooltips.h"
#import <AVFoundation/AVFoundation.h>




@interface AKSingleSegmentedControl : UISegmentedControl
{
}

- (id)initWithItem:(id)item;


@end


@interface MainViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISlider *sliderBrightness;

@property (weak, nonatomic) IBOutlet UISlider *sliderHue;
@property (weak, nonatomic) IBOutlet UISlider *sliderSaturation;
@property (weak, nonatomic) IBOutlet UISlider *sliderValue;
@property (weak, nonatomic) IBOutlet UILabel  *lblInfo;
@property (weak, nonatomic) IBOutlet UIButton *btnHelp;
@property (weak, nonatomic) IBOutlet UIButton *btnInfo;
@property (weak, nonatomic) IBOutlet UIButton *btnMotion;
@property (weak, nonatomic) IBOutlet UIButton *btnSiren;



@property (nonatomic, strong) JDFTooltipManager *tooltipManager;

- (void)logIt:(NSString*) event withTag:(NSInteger)tag;
- (void)logIt:(NSString*) event ;


@end


