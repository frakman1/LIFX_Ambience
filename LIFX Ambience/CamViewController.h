//
//  myCamViewController.h
//  GameFX
//
//  Created by alnaumf on 6/18/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CamViewController : UIViewController

- (IBAction)btnMicPressed:(id)sender;
- (IBAction)btnLockPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *btnMic;
@property (weak, nonatomic) IBOutlet UIButton *btnLock;

@end
