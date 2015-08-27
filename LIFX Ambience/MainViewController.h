//
//  MainViewController.h
//  LIFX Ambience
//
//  Created by alnaumf on 6/23/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import <UIKit/UIKit.h>


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
@property AKSingleSegmentedControl *seg;



@end


