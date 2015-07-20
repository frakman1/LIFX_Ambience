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
#import "UIView+Glow.h"

#import <sys/utsname.h> // import it in your header or implementation file.


@interface InfoViewController ()

@end

@implementation InfoViewController



- (BOOL) prefersStatusBarHidden {return YES;}

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
    [self.btnMail.imageView startGlowingWithColor:[UIColor orangeColor] intensity:5];
    [self.btnDonate.imageView startGlowingWithColor:[UIColor greenColor] intensity:5];

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
        //[mailController setMessageBody:@"Version:%@\n\n Hi Frak! \n\nI have an idea to make LIFX Ambience better. How about this:\n\n" isHTML:NO];
        //[NSString stringWithFormat:@"Version %@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], kRevisionNumber];
        NSString* myversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ;NSLog (@"myversion:%@",myversion);
        NSString* myios = [[UIDevice currentDevice] systemVersion];NSLog (@"myios:%@",myios);
        NSLog(@"model: %@",deviceName());
        NSString* theMessage = [NSString stringWithFormat:@"Version: %@\niOS: %@\nModel: %@\n\n Hi Frak! \n\nI have an idea to make LIFX Ambience better. How about this:\n\n",myversion,myios,deviceName()];
        [mailController setMessageBody:theMessage isHTML:NO];
        
        [self presentViewController:mailController animated:YES completion:NULL];
        

    }
    else
    {
        NSLog(@"%@", @"Sorry, you need to setup mail first!");
    }
    
    NSLog(@"Email sent");
    
}


NSString* deviceName()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
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
