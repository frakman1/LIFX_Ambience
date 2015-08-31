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
#import "UIView+HierarchyLogging.h"
//#import "Constants.h"




typedef NS_ENUM(NSInteger, TableSection) {
    TableSectionLights = 0,
    //TableSectionTags = 1,
};

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate,LFXNetworkContextObserver, LFXLightCollectionObserver, LFXLightObserver>
{
    UIBarButtonItem *tempButton;
    UIBarButtonItem *tempButton2;
    NSMutableArray *yourItemsArray;
    

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

@implementation AKSingleSegmentedControl

- (id)initWithItem:(id)item {
    NSArray *a = [NSArray arrayWithObject:item];
    return [super initWithItems:a];
}

- (void)setSelectedSegmentIndex:(NSInteger)toValue {
    NSLog(@"setSelectedSegmentIndex() self.selectedSegmentIndex:%ld",(long)self.selectedSegmentIndex);
    NSInteger newValue = self.selectedSegmentIndex==0 ? -1 : 0;
    [super setSelectedSegmentIndex:newValue];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    int oldValue = self.selectedSegmentIndex;
    
    NSLog(@"\n\ntouchesBegan.OldValue: %d", oldValue);
    
    [super touchesBegan:touches withEvent:event];
    
    NSLog(@"selectedSegmentIndex %ld", (long)self.selectedSegmentIndex);
    
    if ( oldValue == self.selectedSegmentIndex )
    {
        NSLog(@"oldValue == self.selectedSegmentIndex ");
        [self setSelectedSegmentIndex:-1];

        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }

}


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
    [self.tableView reloadData];
    //[self updateTags];
 
    
}

- (void)toggleLightList:(id)sender
{
    
    [UIView transitionWithView:self.tableView
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    [UIView transitionWithView:self.sliderBrightness
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    [UIView transitionWithView:self.sliderHue
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    [UIView transitionWithView:self.sliderSaturation
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    [UIView transitionWithView:self.sliderValue
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    
    
    self.tableView.hidden = !self.tableView.hidden;
    self.sliderBrightness.hidden = !self.sliderBrightness.hidden;
    self.sliderHue.hidden = !self.sliderHue.hidden;
    self.sliderSaturation.hidden = !self.sliderSaturation.hidden;
    self.sliderValue.hidden = !self.sliderValue.hidden;

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
    
    [self.sliderBrightness setThumbImage: [UIImage imageNamed:@"bright"] forState:UIControlStateNormal];
    [self.sliderHue setThumbImage: [UIImage imageNamed:@"hue"] forState:UIControlStateNormal];
    [self.sliderSaturation setThumbImage: [UIImage imageNamed:@"sat"] forState:UIControlStateNormal];
    [self.sliderValue setThumbImage: [UIImage imageNamed:@"value"] forState:UIControlStateNormal];
  
    
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
    
    
    offImg = [UIImage imageNamed:@"bulb_off"];
    onImg = [UIImage imageNamed:@"bulb_on"];
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
    
    //UIBarButtonItem *item = (UIBarButtonItem *)self.navigationItem.rightBarButtonItem;
    //UIBarButtonItem *item = self.navigationController.navigationBar.topItem.rightBarButtonItem;
    //UIButton *myBtn = (UIButton *)item.customView;
    //[myBtn setShowsTouchWhenHighlighted:YES];
   
    //[(UIButton *)(UIBarButtonItem *)self.navigationItem.rightBarButtonItem.customView setShowsTouchWhenHighlighted:YES];
    
    //myBtn setShowsTouchWhenHighlighted:YES];
    

    
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.hidden = YES;
    //self.tableView.bounces = NO;
    
    //yourItemsArray = [[NSMutableArray alloc] initWithObjects:@"item 01", @"item 02", @"item 03",@"item 04",@"item 05",@"item 01", @"item 02", @"item 03",@"item 04",@"item 05",nil];
    
    //self.navigationController.navigationBar.topItem.title = @"";
    
    //=======================================================================================================================================
    /*
    UIView * container = [[UIView alloc]initWithFrame:CGRectZero];
    UIButton * button = [[UIButton alloc]initWithFrame:CGRectZero];
    [button addTarget:self action:@selector(btnHelpPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"help"] forState:UIControlStateNormal];
    [button sizeToFit];
    [container addSubview:button];
    [container sizeToFit];
    self.navigationItem.titleView = container;
    [[self.navigationItem.titleView superview] bringSubviewToFront:self.navigationItem.titleView];
     */
   // NSArray *itemArray = [NSArray arrayWithObjects: @"Example", nil];
   // NSArray *itemArray = [NSArray arrayWithObjects: [UIImage imageNamed:@"help"],nil];
   // self.seg = [[AKSingleSegmentedControl alloc] initWithItem:[UIImage imageNamed:@"help"]];
    
    //self.seg.segmentedControlStyle = UISegmentedControlStyleBar;
    
    //UIColor *newTintColor = [UIColor colorWithRed: 0/255.0 green:175/255.0 blue:0/255.0 alpha:1.0];
    //self.seg.tintColor = newTintColor;
    
    //UIColor *newSelectedTintColor = [UIColor colorWithRed: 251/255.0 green:175/255.0 blue:93/255.0 alpha:1.0];
    //[[[self.seg subviews] objectAtIndex:0] setTintColor:newSelectedTintColor];
    
    //self.seg.segmentedControlStyle = UISegmentedControlStylePlain;
    //[self.seg addTarget:self action:@selector(btnHelpPressed:)
                 //forControlEvents:UIControlEventValueChanged];
    //self.seg.selectedSegmentIndex = -1;
    
    //self.navigationItem.titleView = self.seg;
    
    /* Make Button in Code
    UIView *container = [[UIView alloc] init];
    container.frame = CGRectMake(0, 0, 32, 32);
    
    // create a button and add it to the container
    UIButton *notificationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [notificationButton setImage:[UIImage imageNamed:@"help"] forState:UIControlStateNormal];
    notificationButton.frame = CGRectMake(0, 0, 32, 32);
    [notificationButton addTarget:self
                           action:@selector(btnHelpPressed:)
                 forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:notificationButton];
    
    
    
    // Set the titleView to the container view
    [self.navigationItem setTitleView:container];
    */
    
    
    //=======================================================================================================================================

    timer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector:@selector(myTick:) userInfo: nil repeats:YES];
}
/*
- (IBAction)btnHelpPressed:(UIButton *)sender
{
    
    //NSLog(@"\n\nPressed: self.seg.selectedSegmentIndex:%ld",(long)self.seg.selectedSegmentIndex);
 
    //self.seg.selectedSegmentIndex = -1;
    if (self.seg.selectedSegmentIndex==0)
    {
        NSLog(@"1: self.seg.selectedSegmentIndex:%ld",(long)self.seg.selectedSegmentIndex);
        //self.seg.selectedSegmentIndex = -1;
    }
    else
    {
        NSLog(@"2: self.seg.selectedSegmentIndex:%ld",(long)self.seg.selectedSegmentIndex);
        //self.seg.selectedSegmentIndex = 0;
    }
 

    
}
*/
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNavBar];
    [self updateLights];
    [self updateTags];
    

}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.tooltipManager hideAllTooltipsAnimated:FALSE];
    [self.btnHelp setSelected:NO];
    [self.btnHelp setImage: [UIImage imageNamed:@"help"] forState:UIControlStateNormal] ;
    
}


- (void)viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
    
    //LFXHSBKColor* tmpColor = [LFXHSBKColor colorWithHue:(200) saturation:0.6 brightness:0.35];
    //LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    //[localNetworkContext.allLightsCollection setColor:tmpColor];
    

    //[(UIImageView *)self.navigationItem.leftBarButtonItem.customView startGlowingWithColor:[UIColor whiteColor] intensity:5];
    [self.btnMusic.imageView startGlowingWithColor:[UIColor whiteColor] intensity:5];
    [self.btnCam.imageView startGlowingWithColor:[UIColor whiteColor] intensity:5];
    
    /*
    UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    
    //UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    //self.navigationItem.rightBarButtonItem=barButton;
    [(UIImageView *)self.navigationItem.rightBarButtonItem.customView setImage:infoButton.imageView.image];
     */
    /*
    NSLog(@"Looking for BUTTON!");
    //if ([self.navigationItem.rightBarButtonItem.customView.subviews.lastObject isKindOfClass:[UIButton class]])
    {
        NSLog(@"FOUND BUTTON!");
        UIButton * btn = ((UIButton *)(self.navigationItem.rightBarButtonItem.customView ));
        [btn setShowsTouchWhenHighlighted:YES];
    }
    NSLog(@" type: %@",self.navigationItem.rightBarButtonItem.customView);
    [[self.view]  logViewHierarchy];
    */
    
    //reset the lights
    self.sliderBrightness.value = 1;
    LFXHSBKColor* tmpColor = [LFXHSBKColor whiteColorWithBrightness:1  kelvin:3500];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    [localNetworkContext.allLightsCollection setColor:tmpColor];
    self.sliderHue.value = tmpColor.hue/360;
    self.sliderSaturation.value = tmpColor.saturation;
    self.sliderValue.value = tmpColor.brightness;

    
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    // do this once per installation. Welcome/Instructions page.
    // currently using the UIAlertAction and hacking an image into it.
    // TODO: need to find a better way to improve images so that they have colour (instead of blue tint) etc.
    if (! [defaults boolForKey:@"alertShown"]) {
    
        //
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"LIFX Ambience\rQuick Guide"
                                      message:nil
                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"No LIFX bulbs detected"
                             style:UIAlertActionStyleDefault
                             handler:nil];
        
        UIAlertAction* ok2 = [UIAlertAction
                             actionWithTitle:@"LIFX bulb(s) detected"
                             style:UIAlertActionStyleDefault
                             handler:nil];
        
        UIAlertAction* ok3 = [UIAlertAction
                             actionWithTitle:@"Music Player"
                             style:UIAlertActionStyleDefault
                             handler:nil];
        
        UIAlertAction* ok4 = [UIAlertAction
                              actionWithTitle:@"Camera Viewer"
                              style:UIAlertActionStyleDefault
                              handler:nil];
              
        UIAlertAction* ok5 = [UIAlertAction
                              actionWithTitle:@"OK"
                              style:UIAlertActionStyleDefault
                              handler:nil];
        
        UIImage *image =  [UIImage imageNamed:@"bulb_off"]; [ok  setValue:image  forKey:@"image"];
        UIImage *image2 = [UIImage imageNamed:@"bulb_on"]; [ok2 setValue:image2 forKey:@"image"];
        UIImage *image3 = [UIImage imageNamed:@"music_sm"];[ok3 setValue:image3 forKey:@"image"];
        //UIImage* smallImage = [image3 scaleToSize:CGSizeMake(40.0f,40.0f)];[ok3 setValue:smallImage forKey:@"image"];
        //UIImage *image3 = [UIImage imageNamed:@"music"];   [ok3 setValue:image3 forKey:@"image"];
        UIImage *image4 = [UIImage imageNamed:@"cam_sm"];[ok4 setValue:image4 forKey:@"image"];
        //UIImage* smallImage2 = [image4 scaleToSize:CGSizeMake(40.0f,40.0f)];[ok4 setValue:smallImage2 forKey:@"image"];
        
        [alert addAction:ok];  // add action to uialertcontroller
        [alert addAction:ok2]; // add action to uialertcontroller
        [alert addAction:ok3]; // add action to uialertcontroller
        [alert addAction:ok4]; // add action to uialertcontroller
        [alert addAction:ok5]; // add action to uialertcontroller
        
        //UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        //imgView.image = [UIImage imageNamed:@"music"];
        //[alert.view addSubview:imgView];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        
        //
    
    
        [defaults setBool:YES forKey:@"alertShown"];
    }
    

    
    self.tooltipManager = [[JDFTooltipManager alloc] initWithHostView:self.view];
    
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(30,40)  tooltipText:@"Toggle Light List and Controls.\nIcon will be green when lights are detected." arrowDirection:JDFTooltipViewArrowDirectionUp hostView:[self.navigationController view] width:250];
    
    
    //[self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnHelp.center.x, self.btnHelp.center.y) tooltipText:@"Tap to dismiss all, or tap each one individually" arrowDirection:JDFTooltipViewArrowDirectionRight hostView:[self.navigationController view] width:150];
    
     [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnInfo.center.x, self.btnInfo.center.y) tooltipText:@"Info Page" arrowDirection:JDFTooltipViewArrowDirectionRight hostView:[self.navigationController view] width:100];
    
    [self.tooltipManager addTooltipWithTargetView:self.btnMusic  hostView:self.view tooltipText:@"Music Player.\nPulse your lights in time to the music." arrowDirection:JDFTooltipViewArrowDirectionUp  width:200];
    
    
    [self.tooltipManager addTooltipWithTargetView:self.btnCam  hostView:self.view tooltipText:@"Camera.\nPoint the Camera at anything and instantly match the bulb colour to it." arrowDirection:JDFTooltipViewArrowDirectionDown  width:210];
    
    //[self.tooltipManager addTooltipWithTargetBarButtonItem:self.navigationItem.leftBarButtonItem.customView hostView:self.view tooltipText:@"Toggle Light List and Controls. Green when lights are detected." arrowDirection:JDFTooltipViewArrowDirectionUp width:200 ];
  
    
}


- (void)updateTags
{
    self.taggedLightCollections = self.lifxNetworkContext.taggedLightCollections;
    [self.tableView reloadData];
}

- (void)updateNavBar
{
    //NSLog(@"updateNavBar()");
    BOOL isConnected = (self.lifxNetworkContext.connectionState == LFXConnectionStateConnected);
    //self.title = [NSString stringWithFormat:@"LIFX Ambience (%@)", isConnected ? @"connected" : @"searching"];
    //self.connectionStatusView.backgroundColor = isConnected ? [UIColor greenColor] : [UIColor redColor];
    //[self.navigationItem.leftBarButtonItem. setBackgroundImage:onImg forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = isConnected ? tempButton2 : tempButton;
}

- (void)updateLights
{
    //NSLog(@"updateLights()");
    self.lights = self.lifxNetworkContext.allLightsCollection.lights;
    [self.tableView reloadData];
    //LFXLight * tmplight = self.lights.lastObject;
    //self.sliderBrightness.value = tmplight.color.brightness;
    //self.sliderSaturation.value = tmplight.color.saturation;
    //self.sliderHue.value = tmplight.color.hue/360;
    //self.sliderValue.value = tmplight.color.brightness;
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
        //case TableSectionLights:	return [yourItemsArray count];
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
    BOOL isConnected = (self.lifxNetworkContext.connectionState == LFXConnectionStateConnected);
    //[self updateLights];
    //[self updateNavBar];
    //[self.tableView reloadData];
    
    if (isConnected)
    {
        return @"Lights";
    }
    else
    {
        self.lights=nil;
        return @"No Lights Detected";
    }
    
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
            //NSLog(@"color:%ld",(long)indexPath.row);
            cell.textLabel.textColor = [UIColor colorWithHue:light.color.hue/360 saturation:light.color.saturation brightness:light.color.brightness alpha:1];
        
            //cell.textLabel.text = [NSString stringWithFormat:[yourItemsArray objectAtIndex:indexPath.row]];
            
            //update sliders. just do it once instead of on every row
            if (indexPath.row==0)
            {
                self.sliderBrightness.value = light.color.brightness;
                self.sliderSaturation.value = light.color.saturation;
                self.sliderHue.value = light.color.hue/360;
                self.sliderValue.value = light.color.brightness;
            }

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


- (IBAction)brightnessOrKelvinChanged:(UISlider *)sender
{
    LFXHSBKColor* tmpColor = [LFXHSBKColor whiteColorWithBrightness:self.sliderBrightness.value  kelvin:3500];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    [localNetworkContext.allLightsCollection setColor:tmpColor];
    
   /*
    LFXHSBKColor *colour = [LFXHSBKColor colorWithHue:self.selectedLight.color.hue
                                           saturation:self.selectedLight.color.saturation
                                           brightness:self.brightnessSlider.value
                                               kelvin:self.kelvinSlider.value];
    */
    // LFXHSBKColor * colour = [LFXHSBKColor whiteColorWithBrightness:self.brightnessSlider.value
    //                                                         kelvin:self.kelvinSlider.value];
    //self.selectedLight.color = colour;
    self.sliderHue.value = tmpColor.hue/360;
    self.sliderSaturation.value = tmpColor.saturation;
    self.sliderValue.value = tmpColor.brightness;
    
    [UIView transitionWithView:self.lblInfo
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    

    self.lblInfo.hidden=FALSE;
    NSString* s = [NSString stringWithFormat:@"White Brightness: %0.2f",self.sliderBrightness.value];
    [self.lblInfo setText:s ];
}


- (IBAction)HueChanged:(UISlider *)sender
{
    
    LFXHSBKColor* tmpColor = [LFXHSBKColor colorWithHue:self.sliderHue.value * 360 saturation:self.sliderSaturation.value brightness:self.sliderValue.value];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    [localNetworkContext.allLightsCollection setColor:tmpColor];
    
    [UIView transitionWithView:self.lblInfo
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    

    self.lblInfo.hidden=FALSE;
    if (self.sliderSaturation.value == 0.0f)
    {
        NSString* s1 = [NSString stringWithFormat:@"Hue (Colour): %0.2f \n(ensure Saturation is non-zero)",self.sliderHue.value];
        [self.lblInfo setText:s1 ];
    }
    else
    {
        NSString* s2 = [NSString stringWithFormat:@"Hue (Colour): %0.2f",self.sliderHue.value];
        [self.lblInfo setText:s2 ];
    }
    
    

    
 }

- (IBAction)SaturationChanged:(UISlider *)sender
{
    
    LFXHSBKColor* tmpColor = [LFXHSBKColor colorWithHue:self.sliderHue.value * 360 saturation:self.sliderSaturation.value brightness:self.sliderValue.value];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    [localNetworkContext.allLightsCollection setColor:tmpColor];
    
    [UIView transitionWithView:self.lblInfo
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    

    self.lblInfo.hidden=FALSE;
    NSString* s = [NSString stringWithFormat:@"Saturation (Intensity): %0.2f",self.sliderSaturation.value];
    [self.lblInfo setText:s ];

    
}

- (IBAction)ValueChanged:(UISlider *)sender
{
    
    LFXHSBKColor* tmpColor = [LFXHSBKColor colorWithHue:self.sliderHue.value * 360 saturation:self.sliderSaturation.value brightness:self.sliderValue.value];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    [localNetworkContext.allLightsCollection setColor:tmpColor];
    
    [UIView transitionWithView:self.lblInfo
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    

    self.lblInfo.hidden=FALSE;
    NSString* s = [NSString stringWithFormat:@"Value (Brightness): %0.2f",self.sliderValue.value];
    [self.lblInfo setText:s ];

}

- (IBAction)sliderBrightnessReleased:(UISlider *)sender forEvent:(UIEvent *)event
{
    [UIView transitionWithView:self.lblInfo
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    
    self.lblInfo.hidden = YES;
   
    
}

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


@end
