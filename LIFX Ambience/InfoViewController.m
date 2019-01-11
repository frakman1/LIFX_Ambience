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

#define FUTURE @"1/20/2019"

@interface InfoViewController ()

@end

@implementation InfoViewController



- (BOOL) prefersStatusBarHidden {return YES;}

- (void)viewDidLoad
{
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
    
    self.lblBuild.text = [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];


}

- (void) viewWillAppear:(BOOL) animated
{
    [super viewWillAppear:animated];
    NSLog(@"***Overriding orientation.");
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    NSDate* enteredDate = [df dateFromString:FUTURE];
    NSDate * today = [NSDate date];
    NSComparisonResult result = [today compare:enteredDate];
    switch (result)
    {
        case NSOrderedAscending:
            NSLog(@"Future Date");
            break;
        case NSOrderedDescending:
            NSLog(@"Earlier Date");
            self.lblDonate.hidden = NO;
            self.btnDonate.hidden = NO;
            break;
        case NSOrderedSame:
            //NSLog(@"Today/Null Date Passed"); //Not sure why This is case when null/wrong date is passed
            break;
    }

}

- (void)viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];


    self.tooltipManager = [[JDFTooltipManager alloc] initWithHostView:self.view];

 
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnHelp.center.x, self.btnHelp.center.y+20) tooltipText:@"Tap to dismiss" arrowDirection:JDFTooltipViewArrowDirectionUp hostView:[self.navigationController view] width:120];
    
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnRate.center.x, self.btnRate.center.y) tooltipText:@"Rate App" arrowDirection:JDFTooltipViewArrowDirectionRight hostView:[self.navigationController view] width:100];


    [self.tooltipManager addTooltipWithTargetView:self.lblMail  hostView:self.view tooltipText:@"Shoot me an email if you have any questions. I'll try and get back to you as soon as I can" arrowDirection:JDFTooltipViewArrowDirectionUp  width:200];
    
    //[self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnMail.center.x, self.btnMail.center.y+20) tooltipText:@"Shoot me an email if you have any questions. I'll try and get back to you as soon as I can" arrowDirection:JDFTooltipViewArrowDirectionUp hostView:[self view] width:200];

    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    NSDate* enteredDate = [df dateFromString:FUTURE];
    NSDate * today = [NSDate date];
    NSComparisonResult result = [today compare:enteredDate];
    switch (result)
    {
        case NSOrderedAscending:
            NSLog(@"Future Date");
            break;
        case NSOrderedDescending:
            NSLog(@"Earlier Date");
            [self.tooltipManager addTooltipWithTargetView:self.btnDonate  hostView:self.view tooltipText:@"If you like this app or find it useful, then please consider making a Paypal donation to keep this app free and ad-free to frak@snakebite.com " arrowDirection:JDFTooltipViewArrowDirectionDown  width:300];
            break;
        case NSOrderedSame:
            //NSLog(@"Today/Null Date Passed"); //Not sure why This is case when null/wrong date is passed
            break;
    }

    //[self.tooltipManager addTooltipWithTargetBarButtonItem:self.navigationItem.leftBarButtonItem.customView hostView:self.view tooltipText:@"Toggle Light List and Controls. Green when lights are detected." arrowDirection:JDFTooltipViewArrowDirectionUp width:200 ];


}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.tooltipManager hideAllTooltipsAnimated:FALSE];
    [self.btnHelp setSelected:NO];
    [self.btnHelp setImage: [UIImage imageNamed:@"help"] forState:UIControlStateNormal] ;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction) donateButtonTapped:(id)sender
{
    NSURL *url = [ [ NSURL alloc ] initWithString: @"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=WU67ZQDC8CEZQ" ];
    //UIButton* btn = (UIButton*)sender;
    //NSLog(@"btn.tag:%d",btn.tag);
    [[UIApplication sharedApplication] openURL:url];
    
    // !HACK ALERT! getting a reference to parent view controller to access its elements.
    MainViewController *parentViewController = (MainViewController*)[self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
    [parentViewController logIt:@"DonateButtonPressed" ];
    
}


- (IBAction) sendButtonTapped:(id)sender
{
    /*     NSString* theMessage = [NSString stringWithFormat:@"I’m %@ and feeling %@ about it.",
     [activities_ objectAtIndex:[emailPicker_ selectedRowInComponent:0]],
     [feelings_ objectAtIndex:[emailPicker_ selectedRowInComponent:1]]];
     NSLog(@"%@",theMessage);
     [ProofingLabel setText:theMessage];
     */
    
    //UIButton* btn = (UIButton*)sender;

    
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
    // !HACK ALERT! getting a reference to parent view controller to access its elements.
    MainViewController *parentViewController = (MainViewController*)[self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
    [parentViewController logIt:@"EmailButtonPressed"];

    
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


- (IBAction)btnHelpPressed:(id)sender
{
    self.btnHelp.selected = !self.btnHelp.selected;
    
    if (self.btnHelp.selected)
    {
        [self.tooltipManager showAllTooltips];
        [self.btnHelp setSelected:YES];
        [self.btnHelp setImage: [UIImage imageNamed:@"help_on"] forState:UIControlStateNormal] ;
        
    }
    else
    {
        [self.tooltipManager hideAllTooltipsAnimated:TRUE];
        [self.btnHelp setSelected:NO];
        [self.btnHelp setImage: [UIImage imageNamed:@"help"] forState:UIControlStateNormal] ;
        [sender removeFromSuperview];
        sender = nil;
        
    }
    
}


- (IBAction)btnRatePressed:(UIButton *)sender
{
    #define YOUR_APP_STORE_ID 1012474625 //Change this one to your ID
    
    static NSString *const iOS7AppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%d";
    static NSString *const iOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%d&action=write-review";
    
    
    
    [ [UIApplication sharedApplication] openURL:
      [NSURL URLWithString:[NSString stringWithFormat:([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)? iOS7AppStoreURLFormat: iOSAppStoreURLFormat, YOUR_APP_STORE_ID]]
    ];

    
}



@end
