//
//  InfoViewController.h
//  LIFX Ambience
//
//  Created by alnaumf on 6/29/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface InfoViewController : UIViewController <MFMailComposeViewControllerDelegate>

- (IBAction) sendButtonTapped:(id)sender;
- (IBAction) donateButtonTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *lblDonate;
@property (weak, nonatomic) IBOutlet UILabel *lblMail;
@property (weak, nonatomic) IBOutlet UIButton *btnDonate;
@property (weak, nonatomic) IBOutlet UIButton *btnMail;
@end
