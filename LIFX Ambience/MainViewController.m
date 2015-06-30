//
//  MainViewController.m
//  LIFX Ambience
//
//  Created by alnaumf on 6/23/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import "MainViewController.h"
#import <LIFXKit/LIFXKit.h>
#import "UIView+Glow.h"
#import <QuartzCore/QuartzCore.h>


typedef NS_ENUM(NSInteger, TableSection) {
    TableSectionLights = 0,
    //TableSectionTags = 1,
};

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate,LFXNetworkContextObserver, LFXLightCollectionObserver, LFXLightObserver>
{
    UIBarButtonItem *tempButton;
    UIBarButtonItem *tempButton2;
}

@property (nonatomic) LFXNetworkContext *lifxNetworkContext;

@property (nonatomic) UIView *connectionStatusView;
@property (nonatomic) NSArray *lights;
@property (nonatomic) NSArray *taggedLightCollections;
@property (weak, nonatomic) IBOutlet UITableView * tableView;
@property (weak, nonatomic) IBOutlet UIButton *btnMusic;
@property (weak, nonatomic) IBOutlet UIButton *btnCam;
@property (strong,nonatomic) IBOutlet UIButton *someButton;
@property (strong,nonatomic) IBOutlet UIButton *someButton2;
@property (nonatomic, retain) UIBarButtonItem *tempButton;
@property (nonatomic, retain) UIBarButtonItem *tempButton2;


@end

@implementation MainViewController

@synthesize tempButton;
@synthesize tempButton2;

UIImage* offImg;
UIImage* onImg;

NSTimer *timer;
-(void)myTick:(NSTimer *)timer
{
    //NSLog(@"myTick..\n\n");
    [self updateLights];
    [self updateNavBar];
    //[self updateTags];
    
    
    

    
    //take screenshot
    /*
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    CGRect rect = [keyWindow bounds];
    UIGraphicsBeginImageContextWithOptions(rect.size,YES,0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [keyWindow.layer renderInContext:context];
    UIImage *capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    //UIColor* averageColor = [capturedScreen averageColor];
    CGFloat red, green, blue;
    CGFloat hue, saturation, brightness, alpha;
    LFXHSBKColor *lifxColor;
    
    //[averageColor getRed:&red green:&green blue:&blue alpha:NULL];
    //[averageColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    NSLog(@"hue:%f   saturation:%f  brightness:%f  alpha:%f",hue,saturation,brightness,alpha);
    NSLog(@"red:%f   green:%f  blue:%f  alpha2:%f",red,green,blue,alpha);
    
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    //[localNetworkContext.allLightsCollection setPowerState:LFXPowerStateOn];
    lifxColor = [LFXHSBKColor colorWithHue:(hue*360) saturation:saturation brightness:self.visualizer.glevel];
    [localNetworkContext.allLightsCollection setColor:lifxColor overDuration:0.5];
    */
    
}

- (void)toggleLightList:(id)sender
{
    
    [UIView transitionWithView:self.tableView
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    self.tableView.hidden = !self.tableView.hidden;

}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        self.lifxNetworkContext = [LFXClient sharedClient].localNetworkContext;
        [self.lifxNetworkContext addNetworkContextObserver:self];
        [self.lifxNetworkContext.allLightsCollection addLightCollectionObserver:self];
    }
    return self;
}



- (BOOL) prefersStatusBarHidden {return YES;}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //[self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    //self.navigationController.navigationBar.shadowImage = [UIImage new];
    //self.navigationController.navigationBar.translucent = YES;}
    
    //self.connectionStatusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    //self.connectionStatusView.backgroundColor = [UIColor redColor];
    //self.connectionStatusView.layer.cornerRadius = self.connectionStatusView.frame.size.height / 2.0;
    //self.connectionStatusView.layer.borderWidth = 5.0 / [UIScreen mainScreen].scale;
    //self.connectionStatusView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    //UITapGestureRecognizer *singleFingerTap =[[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector (toggleLightList:)];
    //[self.connectionStatusView addGestureRecognizer:singleFingerTap];
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.connectionStatusView];
    
    
    offImg = [UIImage imageNamed:@"lightbulb_icon.png"];
    onImg = [UIImage imageNamed:@"lightbulb_on.png"];
    CGRect frameimg = CGRectMake(0, 0, offImg.size.width, offImg.size.height);
    self.someButton = [[UIButton alloc] initWithFrame:frameimg];
    self.someButton2 = [[UIButton alloc] initWithFrame:frameimg];
    [self.someButton setBackgroundImage:offImg forState:UIControlStateNormal];
    [self.someButton2 setBackgroundImage:onImg forState:UIControlStateNormal];
    [self.someButton addTarget:self action:@selector(toggleLightList:) forControlEvents:UIControlEventTouchUpInside];
    [self.someButton2 addTarget:self action:@selector(toggleLightList:) forControlEvents:UIControlEventTouchUpInside];
    [self.someButton setShowsTouchWhenHighlighted:YES];
    [self.someButton2 setShowsTouchWhenHighlighted:YES];
    
    //[self.btnMusic.imageView startGlowingWithColor:[UIColor whiteColor] intensity:0.5];
    //[self.btnCam.imageView startGlowingWithColor:[UIColor whiteColor] intensity:0.5];
    
    //UIBarButtonItem *lightBarButton =[[UIBarButtonItem alloc] initWithCustomView:self.someButton];
    tempButton = [[UIBarButtonItem alloc] initWithCustomView:self.someButton];
    tempButton2 = [[UIBarButtonItem alloc] initWithCustomView:self.someButton2];
    self.navigationItem.leftBarButtonItem=tempButton;
    
    
    
    //self.navigationItem.rightBarButtonItem.target = self;
    //self.navigationItem.rightBarButtonItem.action = @selector(toggleLightList:);
    //[self.navigationItem.rightBarButtonItem setAction:@selector(toggleLightList:)];
    
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.hidden = YES;
    

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNavBar];
    [self updateLights];
    [self updateTags];
}

- (void)viewDidAppear:(BOOL)animated
{
    //LFXHSBKColor* tmpColor = [LFXHSBKColor colorWithHue:(200) saturation:0.6 brightness:0.35];
    //LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    //[localNetworkContext.allLightsCollection setColor:tmpColor];
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector:@selector(myTick:) userInfo: nil repeats:YES];
    //[(UIImageView *)self.navigationItem.leftBarButtonItem.customView startGlowingWithColor:[UIColor whiteColor] intensity:5];
    [self.btnMusic.imageView startGlowingWithColor:[UIColor whiteColor] intensity:5];
    [self.btnCam.imageView startGlowingWithColor:[UIColor whiteColor] intensity:5];
    
    //reset the lights
    LFXHSBKColor* tmpColor = [LFXHSBKColor whiteColorWithBrightness:1  kelvin:3500];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    [localNetworkContext.allLightsCollection setColor:tmpColor];
    
    
    
}


- (void)updateTags
{
    self.taggedLightCollections = self.lifxNetworkContext.taggedLightCollections;
    [self.tableView reloadData];
}

- (void)updateNavBar
{
    BOOL isConnected = (self.lifxNetworkContext.connectionState == LFXConnectionStateConnected);
    //self.title = [NSString stringWithFormat:@"LIFX Ambience (%@)", isConnected ? @"connected" : @"searching"];
    //self.connectionStatusView.backgroundColor = isConnected ? [UIColor greenColor] : [UIColor redColor];
    //[self.navigationItem.leftBarButtonItem. setBackgroundImage:onImg forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = isConnected ? tempButton2 : tempButton;
}

- (void)updateLights
{
    self.lights = self.lifxNetworkContext.allLightsCollection.lights;
    [self.tableView reloadData];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    //LFXHSBKColor* tmpColor = [LFXHSBKColor whiteColorWithBrightness:1  kelvin:3500];

}

#pragma mark - LFXNetworkContextObserver

- (void)networkContextDidConnect:(LFXNetworkContext *)networkContext
{
    NSLog(@"Network Context Did Connect");
    [self updateNavBar];
}

- (void)networkContextDidDisconnect:(LFXNetworkContext *)networkContext
{
    NSLog(@"Network Context Did Disconnect");
    [self updateNavBar];
}

- (void)networkContext:(LFXNetworkContext *)networkContext didAddTaggedLightCollection:(LFXTaggedLightCollection *)collection
{
    NSLog(@"Network Context Did Add Tagged Light Collection: %@", collection.tag);
    [collection addLightCollectionObserver:self];
    [self updateTags];
}

- (void)networkContext:(LFXNetworkContext *)networkContext didRemoveTaggedLightCollection:(LFXTaggedLightCollection *)collection
{
    NSLog(@"Network Context Did Remove Tagged Light Collection: %@", collection.tag);
    [collection removeLightCollectionObserver:self];
    [self updateTags];
}

#pragma mark - LFXLightCollectionObserver

- (void)lightCollection:(LFXLightCollection *)lightCollection didAddLight:(LFXLight *)light
{
    NSLog(@"Light Collection: %@ Did Add Light: %@", lightCollection, light);
    [light addLightObserver:self];
    [self updateLights];
    [self updateNavBar];
}

- (void)lightCollection:(LFXLightCollection *)lightCollection didRemoveLight:(LFXLight *)light
{
    NSLog(@"Light Collection: %@ Did Remove Light: %@", lightCollection, light);
    [light removeLightObserver:self];
    [self updateLights];
    [self updateNavBar];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ((TableSection)section)
    {
        case TableSectionLights:	return self.lights.count;
        //case TableSectionTags:		return self.taggedLightCollections.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    //switch ((TableSection)section)
    {
        //case TableSectionLights:	return @"Lights";
        //case TableSectionTags:		return @"Tags";
    }
    return @"Lights";
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    //gColor = [UIColor colorWithRed:0.27f green:0.5f blue:0.7f alpha:1.0f] ;
    view.tintColor = [UIColor colorWithRed:0.27f green:0.5f blue:0.7f alpha:0.3f] ;
    
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor grayColor]];
    
    // Another way to set the background color
    // Note: does not preserve gradient effect of original header
    // header.contentView.backgroundColor = [UIColor blackColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    switch ((TableSection)indexPath.section)
    {
        case TableSectionLights:
        {
            LFXLight *light = self.lights[indexPath.row];
            //cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = light.label;
            cell.detailTextLabel.text = light.deviceID;
           // NSLog(@"color:%@",light.color);
            cell.textLabel.textColor = [UIColor colorWithHue:light.color.hue/360 saturation:light.color.saturation brightness:light.color.brightness alpha:1];
            
            break;
        }
/*
        case TableSectionTags:
        {
            LFXTaggedLightCollection *taggedLightCollection = self.taggedLightCollections[indexPath.row];
            
            cell.textLabel.text = taggedLightCollection.tag;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%i devices", (int)taggedLightCollection.lights.count];
            
            break;
        }
 */
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.detailTextLabel.textColor = [UIColor grayColor];

    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if(cell.selectionStyle == UITableViewCellSelectionStyleNone){
        return nil;
    }
    return indexPath;
}
#pragma mark - LFXLightObserver

- (void)light:(LFXLight *)light didChangeLabel:(NSString *)label
{
    NSLog(@"Light: %@ Did Change Label: %@", light, label);
    NSUInteger rowIndex = [self.lights indexOfObject:light];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:rowIndex inSection:TableSectionLights]] withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

}


//This function gets called AFTER autolayout/contraint has finished and BEFORE viewWillAppear
- (void)viewDidLayoutSubviews
{
    
    [super viewDidLayoutSubviews];
    CGRect frame = self.view.frame;
    
    CGRect tableFrame = [self.tableView frame];
    tableFrame.size.height = frame.size.height - self.tableView.frame.origin.y;
    tableFrame.size.width = frame.size.width;
    tableFrame.origin.x = frame.origin.x;
    tableFrame.origin.y = self.btnMusic.frame.origin.y + self.btnMusic.frame.size.height;
    
    [self.tableView setFrame:tableFrame];
    
    
   /*
    self.tableView.frame = CGRectMake(0,
                                      self.btnMusic.frame.origin.y + self.btnMusic.frame.size.height,
                                      frame.size.width,
                                      frame.size.height
                                      );
    */
    
    //frame.origin.x + (float)frame.size.height - (float) self.tableView.frame.size.height;
/*
    self.audioPlayerBackgroundLayer.frame = CGRectMake(self.audioPlayerBackgroundLayer.frame.origin.x, self.audioPlayerBackgroundLayer.frame.origin.y, frame.size.width ,self.audioPlayerBackgroundLayer.frame.size.height);
    self.lblSongTitle.frame = CGRectMake(self.lblSongTitle.frame.origin.x, self.lblSongTitle.frame.origin.y, frame.size.width ,self.lblSongTitle.frame.size.height);
    
    
    self.currentTimeSlider.center = self.audioPlayerBackgroundLayer.center;
    CGPoint mypoint;
    mypoint.x = (self.audioPlayerBackgroundLayer.frame.origin.x + self.audioPlayerBackgroundLayer.frame.size.width)-50;
    mypoint.y = self.audioPlayerBackgroundLayer.center.y;
    self.duration.center = mypoint;
    
*/
}


@end
