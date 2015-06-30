//
//  InfoViewController.m
//  LIFX Ambience
//
//  Created by alnaumf on 6/29/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import "InfoViewController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <QuartzCore/QuartzCore.h>


@interface InfoViewController ()

@end

@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
   
    
    UIColor *color = self.lblDonate.textColor;
    self.lblDonate.layer.shadowColor = [color CGColor];
    self.lblDonate.layer.shadowRadius = 4.0f;
    self.lblDonate.layer.shadowOpacity = .9;
    self.lblDonate.layer.shadowOffset = CGSizeZero;
    self.lblDonate.layer.masksToBounds = NO;
    
    self.lblMail.layer.shadowColor = [color CGColor];
    self.lblMail.layer.shadowRadius = 4.0f;
    self.lblMail.layer.shadowOpacity = .9;
    self.lblMail.layer.shadowOffset = CGSizeZero;
    self.lblMail.layer.masksToBounds = NO;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction) donateButtonTapped:(id)sender
{
    NSURL *url = [ [ NSURL alloc ] initWithString: @"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=WU67ZQDC8CEZQ" ];
    
    [[UIApplication sharedApplication] openURL:url];
}


- (IBAction) sendButtonTapped:(id)sender
{
    /*     NSString* theMessage = [NSString stringWithFormat:@"I’m %@ and feeling %@ about it.",
     [activities_ objectAtIndex:[emailPicker_ selectedRowInComponent:0]],
     [feelings_ objectAtIndex:[emailPicker_ selectedRowInComponent:1]]];
     NSLog(@"%@",theMessage);
     [ProofingLabel setText:theMessage];
     */
    
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];
        mailController.mailComposeDelegate = self;
        NSArray *toRecipients = [NSArray arrayWithObject:@"frakman@hotmail.com"];
        [mailController setToRecipients:toRecipients];
        [mailController setSubject:@"LIFX Ambience Feedback."];
        [mailController setMessageBody:@"Hi Frak! \n\nI have an idea to make LIFX Ambience better. How about this:\n\n" isHTML:NO];
        [self presentViewController:mailController animated:YES completion:NULL];
    }
    else
    {
        NSLog(@"%@", @"Sorry, you need to setup mail first!");
    }
    
    NSLog(@"Email sent");
    
}
#pragma mark Mail composer delegate method

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error

{
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
