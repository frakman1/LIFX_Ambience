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
#import "AppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CoreMotion/CoreMotion.h>
#import "VizViewController.h"
#import "CamViewController.h"
#import "YouTubeTVC.h"
#import "Flurry/Flurry.h"

#import <sys/utsname.h> // import it in your header or implementation file.
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "FlurryAdBanner.h"
#import "FlurryAdBannerDelegate.h"
#import "FlurryAdInterstitial.h"
#import "FlurryAdInterstitialDelegate.h"

#import "FlurryAds.h"
#import "AwesomeMenu.h"
#import "SDImageCache.h"
#import "MBProgressHUD.h"

#define NSLog(__FORMAT__, ...) NSLog((@"%s [Line %d] " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)


typedef NS_ENUM(NSInteger, TableSection) {
    TableSectionLights = 0,
    //TableSectionTags = 1,
};

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate,LFXNetworkContextObserver, LFXLightCollectionObserver, LFXLightObserver, FlurryAdBannerDelegate,AwesomeMenuDelegate, MWPhotoBrowserDelegate,MBProgressHUDDelegate>
{
    UIBarButtonItem *tempButton;
    UIBarButtonItem *tempButton2;
    NSMutableArray *yourItemsArray;
    AVAudioPlayer *mysoundaudioPlayer;
    AwesomeMenu *menu;
     NSMutableArray *_selections;
    MBProgressHUD *hud ;

}

@property (nonatomic) LFXNetworkContext *lifxNetworkContext;


@property (nonatomic) UIView *connectionStatusView;
@property (nonatomic) NSArray *lights;
@property (nonatomic) NSArray *taggedLightCollections;
@property (weak, nonatomic) IBOutlet UITableView * tableView;
@property (weak, nonatomic) IBOutlet UIButton *btnMusic;
@property (weak, nonatomic) IBOutlet UIButton *btnCam;
@property (weak, nonatomic) IBOutlet UIButton *btnYT;

@property (strong,nonatomic) IBOutlet UIButton *someButton;
@property (strong,nonatomic) IBOutlet UIButton *someButton2;
@property (nonatomic, retain) UIBarButtonItem *tempButton;
@property (nonatomic, retain) UIBarButtonItem *tempButton2;

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSOperationQueue *deviceQueue;
@property (nonatomic) NSMutableArray *selectedIndexes;
@property (nonatomic) NSMutableArray *mainSelectedLights;



@end



@implementation MainViewController



@synthesize tempButton;
@synthesize tempButton2;

UIImage* offImg;
UIImage* onImg;

NSTimer *timer;
BOOL gShaken=NO;
CGFloat prevBrightness;

NSString *adSpaceName = @"BottomBannerAd";
FlurryAdBanner* adBanner = nil;

-(void)myTick:(NSTimer *)timer
{
   // static int count = 0;
   // NSLog(@"myTick..count:%d\n\n",count);
    //NSLog(@"SelectedIndexes:%@",self.selectedIndexes);
    [self updateLights];
    [self updateNavBar];
    [self.tableView reloadData];
    //[self updateTags];
    //count++;
    //if (count >=6) count = 0;
    
    
}

- (void)toggleLightList:(id)sender
{
    
    if (self.btnMotion.selected) return;
    if (gShaken) return;
    
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
    NSLog(@"***mainVC_initWithCoder()***");
    if ((self = [super initWithCoder:aDecoder]))
    {
        self.lifxNetworkContext = [LFXClient sharedClient].localNetworkContext;
        [self.lifxNetworkContext addNetworkContextObserver:self];
        [self.lifxNetworkContext.allLightsCollection addLightCollectionObserver:self];
        
        // Clear cache for testing
        [[SDImageCache sharedImageCache] clearDisk];
        [[SDImageCache sharedImageCache] clearMemory];
        [self loadAssets];
        
    }
    return self;
}



- (BOOL) prefersStatusBarHidden {return YES;}


- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"***viewDidLoad()***");

    AppDelegate *appdel=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *id=appdel.udid;
    NSLog(@"UDID: %@",id);
    
    gShaken = NO;
    
    
    self.selectedIndexes = [[NSMutableArray alloc] init];
    self.mainSelectedLights = [[NSMutableArray alloc] init];
    
    
    //setup motion detector
    self.deviceQueue = [[NSOperationQueue alloc] init];
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 5.0 / 60.0;
    self.motionManager.gyroUpdateInterval = 0.1;
    
    
    //audio controls
    [self MainConfigureAudioSession];
    NSString *path = [NSString stringWithFormat:@"%@/alarm.mp3",[[NSBundle mainBundle] resourcePath]];
    NSURL *soundUrl = [NSURL fileURLWithPath:path];
    NSLog(@"path:%@  soundUrl:%@",path,soundUrl);
    mysoundaudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
        

    
   
    [self.sliderHue setMaximumTrackImage:[[UIImage imageNamed:@"huescale2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch]  forState:UIControlStateNormal];
    [self.sliderHue setMinimumTrackImage:[[UIImage imageNamed:@"huescale2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeTile]  forState:UIControlStateNormal];

    [self.sliderBrightness setMaximumTrackImage:[[UIImage imageNamed:@"whitebrightscale"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch]  forState:UIControlStateNormal];
    [self.sliderBrightness setMinimumTrackImage:[[UIImage imageNamed:@"whitebrightscale"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeTile]  forState:UIControlStateNormal];

    
    
    [self.sliderBrightness setThumbImage: [UIImage imageNamed:@"bright"] forState:UIControlStateNormal];
    [self.sliderHue setThumbImage: [UIImage imageNamed:@"hue"] forState:UIControlStateNormal];


    
    [self.sliderSaturation setThumbImage: [UIImage imageNamed:@"sat"] forState:UIControlStateNormal];
    [self.sliderValue setThumbImage: [UIImage imageNamed:@"value"] forState:UIControlStateNormal];
  
  
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
      tempButton = [[UIBarButtonItem alloc] initWithCustomView:self.someButton];
    tempButton2 = [[UIBarButtonItem alloc] initWithCustomView:self.someButton2];
    self.navigationItem.leftBarButtonItem=tempButton;
    
                    
    //create header subview for table
    CGFloat headerHeight = 20.0f;//self.tableView.tableHeaderView.frame.size.height;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, headerHeight)];
    UIView *headerContentView = [[UIView alloc] initWithFrame:headerView.bounds];
    headerContentView.backgroundColor = [UIColor grayColor];
    headerContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [headerView addSubview:headerContentView];
    self.tableView.tableHeaderView = headerView;

    
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    self.tableView.allowsMultipleSelection = YES;
    [self.tableView setAllowsSelection:YES];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.hidden = YES;
    
    CALayer *layer = self.tableView.layer;
    [layer setMasksToBounds:YES];
    [layer setCornerRadius: 10.0];
    [layer setBorderWidth:3.0];
    [layer setBorderColor:[[UIColor colorWithRed:0.27f green:0.5f blue:0.7f alpha:0.1f] CGColor]];
    //self.tableView.bounces = NO;
    
    [[self.lblInfo layer] setCornerRadius:10];
    self.lblInfo.clipsToBounds = YES;
    self.lblInfo.layer.masksToBounds = YES;
    UIFont* boldFont = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
    [self.lblInfo setFont:boldFont];
    
    //yourItemsArray = [[NSMutableArray alloc] initWithObjects:@"item 01", @"item 02", @"item 03",@"item 04",@"item 05",@"item 01", @"item 02", @"item 03",@"item 04",@"item 05",nil];
    
    //self.navigationController.navigationBar.topItem.title = @"";
    
    //set up Badge for number of lights detected
    self.badgeOne = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(self.someButton2.frame.size.width - 12, -10, 44, 40)];
    [self.someButton2 addSubview:self.badgeOne];
    
    // Delay execution of block for 1 seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSLog(@"delayed launch myTick...");
        
        timer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector:@selector(myTick:) userInfo: nil repeats:YES];
        
    });
    
    [self addChooseButton];
}

- (void)addChooseButton {
    
    UIImage *storyMenuItemImage        = [UIImage imageNamed:@"bg-menuitem.png"];
    UIImage *storyMenuItemImagePressed = [UIImage imageNamed:@"bg-menuitem-highlighted.png"];
    UIImage *starImage                 = [UIImage imageNamed:@"icon-star.png"];
    
    AwesomeMenuItem *starMenuItem1 = [[AwesomeMenuItem alloc] initWithImage:[UIImage imageNamed:@"music_sm"]
                                                           highlightedImage:[UIImage imageNamed:@"music_smh"]
                                                               ContentImage:nil
                                                    highlightedContentImage:nil];
    AwesomeMenuItem *starMenuItem2 = [[AwesomeMenuItem alloc] initWithImage:[UIImage imageNamed:@"yt_sm"]
                                                           highlightedImage:[UIImage imageNamed:@"yt_smh"]
                                                               ContentImage:nil
                                                    highlightedContentImage:nil];
    AwesomeMenuItem *starMenuItem3 = [[AwesomeMenuItem alloc] initWithImage:[UIImage imageNamed:@"cam_sm"]
                                                           highlightedImage:[UIImage imageNamed:@"camb_smh"]
                                                               ContentImage:nil
                                                    highlightedContentImage:nil];
    AwesomeMenuItem *starMenuItem4 = [[AwesomeMenuItem alloc] initWithImage:[UIImage imageNamed:@"motion_sm"]
                                                           highlightedImage:[UIImage imageNamed:@"motion_smh"]
                                                               ContentImage:nil
                                                    highlightedContentImage:nil];
    AwesomeMenuItem *starMenuItem5 = [[AwesomeMenuItem alloc] initWithImage:[UIImage imageNamed:@"siren_sm"]
                                                           highlightedImage:[UIImage imageNamed:@"siren_smh"]
                                                               ContentImage:nil
                                                    highlightedContentImage:nil];

    AwesomeMenuItem *starMenuItem6 = [[AwesomeMenuItem alloc] initWithImage:[UIImage imageNamed:@"album_sm"]
                                                           highlightedImage:[UIImage imageNamed:@"album_smh"]
                                                               ContentImage:nil
                                                    highlightedContentImage:nil];
   
    NSArray *menus = [NSArray arrayWithObjects:starMenuItem1, starMenuItem2, starMenuItem3, starMenuItem4, starMenuItem5,starMenuItem6, nil];
   // AwesomeMenu *menu = [[AwesomeMenu alloc] initWithFrame:self.view.bounds startItem:starMenuItem1 menuItems:menus];
    menu = [[AwesomeMenu alloc] initWithFrame:self.view.bounds menus:menus];

    menu.rotateAngle    = -M_PI_2;    //to set the rotate angle:
    menu.delegate       = self;
    menu.menuWholeAngle = 2*M_PI;   //to set the whole menu angle:
    menu.endRadius      = 100.0f;   //to set the distance between the "Add" button and Menu Items:
    menu.farRadius      = 110.0f;   //to adjust the bounce animation:
    menu.nearRadius     = 90.0f;    //to adjust the bounce animation:
    //menu.timeOffset = 0.036f;    //to set the delay of every menu flying out animation:
    
    menu.startPoint     = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);

    
    [self.view addSubview:menu];
    
}

- (void)loadMusicPlayer
{
    [self.btnMusic sendActionsForControlEvents: UIControlEventTouchUpInside];
}


- (void)AwesomeMenu:(AwesomeMenu *)menu didSelectIndex:(NSInteger)idx
{
     NSLog(@"AwesomeMenu didSelectIndex");

    switch (idx) {
        case 0:
        {
         
            /*
            hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.labelText = @"Doing stuff...";
            hud.detailsLabelText = @"Just relax";
            hud.delegate=self;
            [hud show:YES];
            */
            
            //[hud showWhileExecuting:@selector(loadMusicPlayer) onTarget:self withObject:nil animated:YES];
            //[self loadMusicPlayer];
            
            
            /*
            dispatch_async(dispatch_get_main_queue(),
            ^{
                //hud = [MBProgressHUD showHUDAddedTo:self.wait animated:YES];
                //hud.labelText = @"Loading...";
                
                hud = [[MBProgressHUD alloc] initWithView:self.wait];
                [self.wait addSubview:hud];
                [[hud superview] bringSubviewToFront:hud];
                hud.delegate = self;
                hud.labelText = @"Authorizing...";
                [hud show:YES];
            });//main queue
             */

            //[self performSegueWithIdentifier:@"toMusic" sender:nil];
            
            [self.btnMusic sendActionsForControlEvents: UIControlEventTouchUpInside];
            
          

        }
            break;
            
        case 1:
        {

            //[self performSegueWithIdentifier:@"toYouTube" sender:nil];
            [self.btnYT sendActionsForControlEvents: UIControlEventTouchUpInside];
           // NSLog(@"case 1().");
            
        }
            break;

        case 2:
        {

            //[self performSegueWithIdentifier:@"toCamera" sender:nil];
            [self.btnCam sendActionsForControlEvents: UIControlEventTouchUpInside];
            //NSLog(@"case 2().");

        }
            break;
            
        case 3:
        {
            [self.btnMotion sendActionsForControlEvents: UIControlEventTouchUpInside];
           // NSLog(@"case 3().");
            
        }
            break;
            
        case 4:
        {
            [self.btnSiren sendActionsForControlEvents: UIControlEventTouchUpInside];
           // NSLog(@"case 4().");
            
        }
            break;
            
        case 5:
        {
            
            
            [self logIt:@"AlbumBrowser"];
            [self saveLightState];
            


            // Browser
            NSMutableArray *photos = [[NSMutableArray alloc] init];
            NSMutableArray *thumbs = [[NSMutableArray alloc] init];
           
            BOOL displayActionButton = YES;
            BOOL displaySelectionButtons = NO;
            BOOL displayNavArrows = YES;
            BOOL enableGrid = YES;
            BOOL startOnGrid = YES;
            BOOL autoPlayOnAppear = NO;

            //[self.btnSiren sendActionsForControlEvents: UIControlEventTouchUpInside];
            //NSLog(@"case 5().");
            
            @synchronized(_assets)
            {
                NSMutableArray *copy = [_assets copy];
                if (NSClassFromString(@"PHAsset"))
                {
                    // Photos library
                    UIScreen *screen = [UIScreen mainScreen];
                    CGFloat scale = screen.scale;
                    // Sizing is very rough... more thought required in a real implementation
                    CGFloat imageSize = MAX(screen.bounds.size.width, screen.bounds.size.height) * 1.5;
                    CGSize imageTargetSize = CGSizeMake(imageSize * scale, imageSize * scale);
                    CGSize thumbTargetSize = CGSizeMake(imageSize / 3.0 * scale, imageSize / 3.0 * scale);
                    for (PHAsset *asset in copy)
                    {
                        [photos addObject:[MWPhoto photoWithAsset:asset targetSize:imageTargetSize]];
                        [thumbs addObject:[MWPhoto photoWithAsset:asset targetSize:thumbTargetSize]];
                    }
                }
                else
                {
                    // Assets library
                    for (ALAsset *asset in copy)
                    {
                        MWPhoto *photo = [MWPhoto photoWithURL:asset.defaultRepresentation.url];
                        [photos addObject:photo];
                        MWPhoto *thumb = [MWPhoto photoWithImage:[UIImage imageWithCGImage:asset.thumbnail]];
                        [thumbs addObject:thumb];
                        if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo)
                        {
                            photo.videoURL = asset.defaultRepresentation.url;
                            thumb.isVideo = true;
                        }
                    }
                }
            }
            
            self.photos = photos; NSLog(@"self.photos :%d",[self.photos count]);
            self.thumbs = thumbs; NSLog(@"self.photos :%d",[self.photos count]);
            
            // Create browser
            MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
            browser.displayActionButton = displayActionButton;
            browser.displayNavArrows = displayNavArrows;
            browser.displaySelectionButtons = displaySelectionButtons;
            browser.alwaysShowControls = displaySelectionButtons;
            browser.zoomPhotosToFill = YES;
            browser.enableGrid = enableGrid;
            browser.startOnGrid = startOnGrid;
            browser.enableSwipeToDismiss = NO;
            browser.autoPlayOnAppear = autoPlayOnAppear;
            [browser setCurrentPhotoIndex:0];
            browser.mwbInputLights = self.selectedIndexes;
            
            // Reset selections
            if (displaySelectionButtons)
            {
                _selections = [NSMutableArray new];
                for (int i = 0; i < photos.count; i++)
                {
                    [_selections addObject:[NSNumber numberWithBool:NO]];
                }
            }
            
             [self.navigationController pushViewController:browser animated:YES];
            
            
            
        }
            break;
            
        default:
            break;
    }
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

-(void) mute
{
    MPVolumeView* volumeView;
    volumeView = [[MPVolumeView alloc] init];
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews])
    {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"])
        {
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    [volumeViewSlider setValue:0.0f animated:NO];
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    
}

-(void) setVolume:(CGFloat)volume
{
    MPVolumeView* volumeView;
    volumeView = [[MPVolumeView alloc] init];
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews])
    {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"])
        {
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    [volumeViewSlider setValue:volume animated:NO];
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    
}

-(CGFloat) getVolume
{
    MPVolumeView* volumeView;
    volumeView = [[MPVolumeView alloc] init];
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews])
    {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"])
        {
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    return volumeViewSlider.value;
    
}


- (void)viewWillDisappear:(BOOL)animated
{
    
    [self resignFirstResponder];
    NSLog(@"***viewWillDisappear().");
    //[MBProgressHUD hideHUDForView:self.wait animated:YES];

    if (self.btnMotion.selected)
    {
        //[self.motionManager stopDeviceMotionUpdates];
        //[self.btnMotion setSelected:NO];
        //[self.btnMotion setImage: [UIImage imageNamed:@"motion"] forState:UIControlStateNormal] ;
         [self.btnMotion sendActionsForControlEvents:UIControlEventTouchUpInside];
        
    }
    
    [self.tooltipManager hideAllTooltipsAnimated:NO];
    //[self.btnHelp setSelected:NO];
    //[self.btnHelp setImage: [UIImage imageNamed:@"help"] forState:UIControlStateNormal] ;
    
    [super viewWillDisappear:animated];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"***viewWillAppear().");
    [UIView setAnimationsEnabled:YES];
    
    //[self mute];
    gShaken = NO;
    
    
    NSLog(@"***Overriding orientation.");
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    //[self updateNavBar];
    //[self updateLights];
    //[self updateTags];
    
    
}


- (void)viewDidAppear:(BOOL)animated
{//test
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    NSLog(@"***viewDidAppear().");
    
    /*
    adBanner = [[FlurryAdBanner alloc] initWithSpace:adSpaceName];
    adBanner.adDelegate = self;
    [adBanner fetchAndDisplayAdInView:self.view viewControllerForPresentation:self];
    [FlurryAds fetchAndDisplayAdForSpace:@"BottomBannerAd" view:self.view viewController:self size:BANNER_BOTTOM];
     */

    

    [self.btnMusic.imageView startGlowingWithColor:[UIColor greenColor] intensity:1];
    [self.btnCam.imageView startGlowingWithColor:[UIColor blueColor] intensity:1];
    [self.btnYT.imageView startGlowingWithColor:[UIColor redColor] intensity:1];
    [self.btnMotion.imageView startGlowingWithColor:[UIColor cyanColor] intensity:1];
    [self.btnSiren.imageView startGlowingWithColor:[UIColor redColor] intensity:1];
    
    
    self.tooltipManager = [[JDFTooltipManager alloc] initWithHostView:self.view];
    
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(30,40)  tooltipText:@"Toggle Light List and Controls.\nIcon will be green when lights are detected." arrowDirection:JDFTooltipViewArrowDirectionUp hostView:[self.navigationController view] width:250];
    
    
    //[self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnHelp.center.x, self.btnHelp.center.y) tooltipText:@"Tap to dismiss all, or tap each one individually" arrowDirection:JDFTooltipViewArrowDirectionRight hostView:[self.navigationController view] width:150];
    
     [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnInfo.center.x, self.btnInfo.center.y) tooltipText:@"Info Page" arrowDirection:JDFTooltipViewArrowDirectionRight hostView:[self.navigationController view] width:100];
    
    [self.tooltipManager addTooltipWithTargetView:self.btnMusic  hostView:self.view tooltipText:@"Music Player.\nPulse your lights in time to the music." arrowDirection:JDFTooltipViewArrowDirectionUp  width:280];
    
    
    [self.tooltipManager addTooltipWithTargetView:self.btnCam  hostView:self.view tooltipText:@"Camera Viewer.\nPoint the Camera at anything and instantly match the bulb colour to it." arrowDirection:JDFTooltipViewArrowDirectionDown  width:210];
    
    //[self.tooltipManager addTooltipWithTargetView:self.btnMotion  hostView:self.view tooltipText:@"Gyroscopic Motion Controller.\nMove your phone along its 3 axis to control Hue, Saturation and Brightness " arrowDirection:JDFTooltipViewArrowDirectionRight  width:310];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* hw = [NSString stringWithCString:systemInfo.machine
                                      encoding:NSUTF8StringEncoding];
    NSLog(@"Hardware: %@",hw);
    if ( ([hw isEqualToString:@"iPhone4,1"]) || ([hw isEqualToString:@"iPhone3,1"]) )
    {
        NSLog(@"Running on iPhone 4/4S");
        
        [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnMotion.center.x, self.btnMotion.center.y) tooltipText:@"Gyroscopic Motion Controller.\nMove your phone along its 3 axes to control Hue, Saturation and Brightness " arrowDirection:JDFTooltipViewArrowDirectionUp hostView:self.view width:310];
        
    }
    else
    {
         NSLog(@"NOT Running on iPhone 4/4S");
        [self.tooltipManager addTooltipWithTargetView:self.btnMotion  hostView:self.view tooltipText:@"Gyroscopic Motion Controller.\nMove your phone along its 3 axes to control Hue, Saturation and Brightness " arrowDirection:JDFTooltipViewArrowDirectionRight  width:200];
        
    }
        
    [self restoreLightState];
        
    
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
    self.badgeOne.value = self.lights.count;
    //[self.tableView reloadData];
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
    [self.selectedIndexes addObject:light.deviceID];
    [self.mainSelectedLights addObject:light];
    [light addLightObserver:self];
    [self updateLights];
    [self updateNavBar];
    
}

- (void)lightCollection:(LFXLightCollection *)lightCollection didRemoveLight:(LFXLight *)light
{
    NSLog(@"Light Collection: %@ Did Remove Light: %@", lightCollection, light);
    [self.selectedIndexes removeObject:light.deviceID];
    [self.mainSelectedLights removeObject:light];
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
    //NSLog(@"titleForHeaderInSection :%d",section);

    //switch ((TableSection)section)
    {
        //case TableSectionLights:	return @"Lights";
        //case TableSectionTags:		return @"Tags";
    }
    BOOL isConnected = (self.lifxNetworkContext.connectionState == LFXConnectionStateConnected);

    
    UIView *headerContentView = self.tableView.tableHeaderView.subviews[0];
    
    if (isConnected)
    {
        headerContentView.backgroundColor = [UIColor greenColor];
        //[headerContentView startGlowingWithColor:[UIColor greenColor] intensity:1];
        
        
    }
    else
    {
        self.lights=nil;
        headerContentView.backgroundColor = [UIColor grayColor];
        //[headerContentView stopGlowing ] ;
    }
   

    return @"";
}

//Note: UITableView is a subclass of UIScrollView, so we
//      can use UIScrollViewDelegate methods.

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetY = scrollView.contentOffset.y;
    UIView *headerContentView = self.tableView.tableHeaderView.subviews[0];
    headerContentView.transform = CGAffineTransformMakeTranslation(0, MIN(offsetY, 0));
}

/*
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    //NSLog(@"willDisplayHeaderView :%@  forsection :%d",view, section);
    // Background color
    //gColor = [UIColor colorWithRed:0.27f green:0.5f blue:0.7f alpha:1.0f] ;
    //view.tintColor = [UIColor colorWithRed:0.27f green:0.5f blue:0.7f alpha:0.3f] ;
    
    // Text Color
    //UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    //[header.textLabel setTextColor:[UIColor grayColor]];
    
    // Another way to set the background color
    // Note: does not preserve gradient effect of original header
    // header.contentView.backgroundColor = [UIColor blackColor];

}
*/
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
    
    //return self.tableView.tableHeaderView.subviews[0];

    
    
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath()  indexPath.row:%ld",(long)indexPath.row);
    //if (self.btnMotion.selected) {return;}
    
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ([selectedCell accessoryType] == UITableViewCellAccessoryNone)
    {
        NSLog(@"UITableViewCellAccessoryNone: ");
        [selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [self.selectedIndexes addObject: selectedCell.detailTextLabel.text];
        
        {   NSLog(@"Updating sliders");
            LFXLight *light = self.lights[indexPath.row];
            [self.mainSelectedLights addObject:light];
            self.sliderBrightness.value = light.color.brightness;
            self.sliderSaturation.value = light.color.saturation;
            self.sliderHue.value = light.color.hue/360;
            self.sliderValue.value = light.color.brightness;
            
        }
        
    } else
    {
        NSLog(@"else: ");
        [selectedCell setAccessoryType:UITableViewCellAccessoryNone];
        [self.selectedIndexes removeObject:selectedCell.detailTextLabel.text];
        LFXLight *light = self.lights[indexPath.row];
        [self.mainSelectedLights removeObject:light];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}
/*
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"editingStyleForRowAtIndexPath()  indexPath.row:%ld",(long)indexPath.row);
    return 3; // Undocumented constant
}
*/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    switch ((TableSection)indexPath.section)
    {
        case TableSectionLights:
        {
            //NSLog(@"indexPath.row=%d",indexPath.row);
            if ([self.selectedIndexes containsObject:cell.textLabel.text])
            {
                NSLog(@"cellForRowAtIndexPath() ...saved...");
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            }
            LFXLight *light = self.lights[indexPath.row];
            //@synchronized (self){
                if ((light.powerState==LFXPowerStateOff) && (!gShaken))
                {
                    NSLog(@"Bulb is Connected but in OFF State.Turning On...");
                    [light setPowerState:LFXPowerStateOn];
                }
            //}
            //cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = light.label;
            cell.detailTextLabel.text = light.deviceID;
            //NSLog(@"color:%ld",(long)indexPath.row);
            cell.textLabel.textColor = [UIColor colorWithHue:light.color.hue/360 saturation:light.color.saturation brightness:light.color.brightness alpha:1];
        
            //cell.textLabel.text = [NSString stringWithFormat:[yourItemsArray objectAtIndex:indexPath.row]];
            
            //update sliders. just do it once instead of on every row
           /* 
            if ( (indexPath.row==0) && (!self.btnMotion.selected) )
            {   NSLog(@"Updating sliders");
                self.sliderBrightness.value = light.color.brightness;
                self.sliderSaturation.value = light.color.saturation;
                self.sliderHue.value = light.color.hue/360;
                self.sliderValue.value = light.color.brightness;
            }
            */
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
    //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    //cell.accessoryType = UITableViewCellAccessoryNone;
    cell.tintColor = [UIColor greenColor];
    cell.detailTextLabel.textColor = [UIColor grayColor];


    
    return cell;
}
/*
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if(cell.selectionStyle == UITableViewCellSelectionStyleNone)
    {
        NSLog(@"willSelectRowAtIndexPath 1");
        return nil;
    }
     NSLog(@"willSelectRowAtIndexPath 2");
    return indexPath;
}
 */
#pragma mark - LFXLightObserver

- (void)light:(LFXLight *)light didChangeLabel:(NSString *)label
{
    NSLog(@"Light: %@ Did Change Label: %@", light, label);
    NSUInteger rowIndex = [self.lights indexOfObject:light];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:rowIndex inSection:TableSectionLights]] withRowAnimation:UITableViewRowAnimationFade];
}



-(NSString *) tagToText:(NSInteger)tag
{
    NSString* tagName= [[NSString alloc]init];

    NSLog(@" tagToText() input tag:%ld ",(long)tag);
    switch (tag)
    {
            
        case 0:
        {
            
            tagName=@"Info";
            NSLog(@"tag=%ld tagName:%@",(long)tag,tagName);
            //[Flurry logEvent:@"Info" withParameters:@{id:@"userID"} timed:YES];
            break;
        }
        case 1:
        {
            
            tagName=@"MusicPlayer";
            NSLog(@"tag=%ld tagName:%@",(long)tag,tagName);
            //[Flurry logEvent:@"MusicPlayer" withParameters:@{id:@"userID"} timed:YES];
            break;
        }
        case 2:
        {
            
            tagName=@"YouTubePlayer";
            NSLog(@"tag=%ld tagName:%@",(long)tag,tagName);
            //[Flurry logEvent:@"YouTubePlayer" withParameters:@{id:@"userID"} timed:YES];
            break;
        }
        case 3:
        {
            
            tagName=@"CameraViewer";
            NSLog(@"tag=%ld tagName:%@",(long)tag,tagName);
            //[Flurry logEvent:@"CameraViewer" withParameters:@{id:@"userID"} timed:YES];
            break;
        }
        case 4:
        {
            
            tagName=@"Gyro";
            NSLog(@"tag=%ld tagName:%@",(long)tag,tagName);
            //[Flurry logEvent:@"Gyro" withParameters:@{id:@"userID"} timed:YES];
            break;
        }
        case 5:
        {
            
            tagName=@"Email";
            NSLog(@"tag=%ld tagName:%@",(long)tag,tagName);
            //[Flurry logEvent:@"Email" withParameters:@{id:@"userID"} timed:YES];
            break;
        }
            
        case 6:
        {
            
            tagName=@"Donate";
            NSLog(@"tag=%ld tagName:%@",(long)tag,tagName);
            //[Flurry logEvent:@"Donate" withParameters:@{id:@"userID"} timed:YES];
            break;
        }
            
        case 7:
        {
            
            tagName=@"Info";
            NSLog(@"tag=%ld tagName:%@",(long)tag,tagName);
            //[Flurry logEvent:@"Donate" withParameters:@{id:@"userID"} timed:YES];
            break;
        }
            
        case 8:
        {
            
            tagName=@"Siren";
            NSLog(@"tag=%ld tagName:%@",(long)tag,tagName);
            //[Flurry logEvent:@"Donate" withParameters:@{id:@"userID"} timed:YES];
            break;
        }

        
        default:
        {
            NSLog(@"unknown tag");
            tagName=@"UnknownTag";
            //[Flurry logEvent:@"Unknown" withParameters:@{id:@"userID"} timed:YES];
            break;
        }
            
            
    }
    
    return tagName;
}


//Flurry Event Logger

- (void)logIt:(NSString*) event withTag:(NSString*)tagName
{
    AppDelegate *appdel=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *id=appdel.udid;
    NSLog(@"Logging Event:%@ withTag:%@ for UDID: %@",event,tagName,id);

   [Flurry logEvent:event withParameters:@{id:@"userID",tagName:@"withTag"} timed:YES];

    
}


- (void)logIt:(NSString*) event
{
    AppDelegate *appdel=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *id=appdel.udid;
    NSLog(@"Logging Event:%@  for UDID: %@",event,id);
    
    [Flurry logEvent:event withParameters:@{id:@"userID"} timed:YES];
    
    
}

// Make sure at least one bulb is selected
-(BOOL) checkIfSelected:(NSString*)buttonName
{
    NSLog(@"checkIfSelected()");
    BOOL isConnected = (self.lifxNetworkContext.connectionState == LFXConnectionStateConnected);
    //NSString *buttonName = [NSString alloc];
    //buttonName = [self tagToText:tag];
    NSLog(@"buttonName:%@",buttonName);
    //[self logIt:buttonName ];
    
    if ( (isConnected) && (self.selectedIndexes.count==0))
    {
        NSLog(@"No can do, compadré");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Bulbs Selected" message:@"Please select at least one bulb" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        
        alert.tag = 0;
        
        [alert show];
        
        [self logIt:@"NoLightsSelectedTransitionAttempt" withTag:buttonName];
        
        return NO;
    }
    else
    {
        [self logIt:buttonName];
        return YES;
    }

    
}

#pragma mark - Navigation
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    NSLog(@"shouldPerformSegueWithIdentifier()");
    UIButton *btn = (UIButton*)sender;
    NSString *btnName = [NSString alloc];
    btnName = [self tagToText:btn.tag]; NSLog(@"btnName:%@",btnName);

    // if any of the mini-App buttons got pressed, check for light selection.
    if ( (btn.tag == 1) || (btn.tag == 2) || (btn.tag == 3) )
    {
        return [self checkIfSelected:btnName];
    }
    else //currently the only other segue is the info button
    {
       if (gShaken) return NO;
       if (self.btnMotion.selected) return NO;
        
       [self logIt:btnName];
       return YES;
    }
}

-(void) saveLightState
{
    AppDelegate *appdel=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    for (LFXLight *aLight in localNetworkContext.allLightsCollection)
    {
        [appdel.backupLights setObject:aLight.color forKey:aLight.deviceID];
    }
    NSLog(@"Saving light state: %@", appdel.backupLights);
}

-(void) restoreLightState
{
    NSLog(@"restoreLightState()");
    // Delay execution of block for x seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(),
    ^{
        NSLog(@"delayed operation...");
        
        AppDelegate *appdel=(AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSLog(@"***restoredLights:%@",appdel.backupLights);
        LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
        
        for (NSString *aDevID in [appdel.backupLights allKeys])
        {
            NSLog(@"aDevID:%@",aDevID);
            LFXLight *aSelLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
            //if ([aLight.deviceID isEqualToString:aDevID])
            {
                NSLog(@"appdel.backupLights objectForKey:aDevID: %@",[appdel.backupLights objectForKey:aDevID]);
                [aSelLight setColor:[appdel.backupLights objectForKey:aDevID] overDuration:2];
            }
        }
       
    });//end blaock
    
    
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    AppDelegate *appdel=(AppDelegate *)[[UIApplication sharedApplication] delegate];

    
    UIButton *btn = (UIButton*)sender;
    NSLog(@"prepareForSegue. tag number:%ld",(long)[(UIButton *)sender tag]);
    
    [self saveLightState];
    
    
    if (btn.tag == 3)
    {
        NSLog(@"going to cam player");
        CamViewController *destination = segue.destinationViewController;
        destination.inputLights = self.selectedIndexes;
    }
    else if (btn.tag == 1)
    {
        NSLog(@"going to music player");
        VizViewController *vizDestination = segue.destinationViewController;
        vizDestination.inputLights = self.selectedIndexes;
        vizDestination.inputLights2= self.mainSelectedLights;
        
        
    }
    else if (btn.tag==2)
    {
        NSLog(@"going to youtube player");
        YouTubeTVC *ytDestination = segue.destinationViewController;
        ytDestination.ytInputLights = self.selectedIndexes;
        
    }


}


//This function gets called AFTER autolayout/contraint has finished and BEFORE viewWillAppear
- (void)viewDidLayoutSubviews
{
    
    [super viewDidLayoutSubviews];
    CGRect frame = self.view.frame;
    
    

}

-(void) updateLblInfo
{
    NSLog(@"updateLblInfo()");
    self.lblInfo.alpha=1;
    self.lblInfo.hidden=NO;
    // change test lblInfo background colour to indicate change on device screen
    self.lblInfo.backgroundColor = [UIColor colorWithHue:(self.sliderHue.value) saturation:self.sliderSaturation.value brightness:self.sliderValue.value alpha:1];

    
}

-(void) turnOnLights
{
    NSLog(@"turnOnLights()");
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    for (LFXLight *aLight in localNetworkContext.allLightsCollection)
    {
        [aLight setPowerState:LFXPowerStateOn];
        
    }// end for

}


- (IBAction)brightnessOrKelvinChanged:(UISlider *)sender
{
    NSLog(@"brightnessOrKelvinChanged()");
    //self.lblInfo.backgroundColor = [UIColor clearColor];
    LFXHSBKColor* tmpColor = [LFXHSBKColor whiteColorWithBrightness:self.sliderBrightness.value  kelvin:3500];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    //[localNetworkContext.allLightsCollection setColor:tmpColor];
    for (NSString *aDevID in self.selectedIndexes)
    {
        LFXLight *aLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
        [aLight setColor:tmpColor overDuration:0.5];
    }

    
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
    

    
    NSString* s = [NSString stringWithFormat:@"White Brightness: %0.2f",self.sliderBrightness.value];
    [self.lblInfo setText:s ];
    [self updateLblInfo];
    [self turnOnLights];
}


- (IBAction)HueChanged:(UISlider *)sender
{
    NSLog(@"HueChanged");
    //self.lblInfo.backgroundColor = [UIColor clearColor];
    
    LFXHSBKColor* tmpColor = [LFXHSBKColor colorWithHue:self.sliderHue.value * 360 saturation:self.sliderSaturation.value brightness:self.sliderValue.value];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    //[localNetworkContext.allLightsCollection setColor:tmpColor];
    for (NSString *aDevID in self.selectedIndexes)
    {
        LFXLight *aLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
        [aLight setColor:tmpColor overDuration:0.5];
    }

    //NSLog(@"hue:%f sat:%f val:%f",self.sliderHue.value,self.sliderSaturation.value,self.sliderValue.value);
    //[self.sliderHue setTintColor:[UIColor colorWithHue:self.sliderHue.value  saturation:self.sliderSaturation.value brightness:self.sliderValue.value alpha:1.0]];
    
    
    [UIView transitionWithView:self.lblInfo
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    

    
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
    [self updateLblInfo];
    [self turnOnLights];
    
    

    
 }

- (IBAction)SaturationChanged:(UISlider *)sender
{
    NSLog(@"SaturationChanged");
    //self.lblInfo.backgroundColor = [UIColor clearColor];
    
    LFXHSBKColor* tmpColor = [LFXHSBKColor colorWithHue:self.sliderHue.value * 360 saturation:self.sliderSaturation.value brightness:self.sliderValue.value];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    //[localNetworkContext.allLightsCollection setColor:tmpColor];
    for (NSString *aDevID in self.selectedIndexes)
    {
        LFXLight *aLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
        [aLight setColor:tmpColor overDuration:0.5];
    }

    
    [UIView transitionWithView:self.lblInfo
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    

    
    NSString* s = [NSString stringWithFormat:@"Saturation (Intensity): %0.2f",self.sliderSaturation.value];
    [self.lblInfo setText:s ];
    [self updateLblInfo];
    [self turnOnLights];
    

    
}

- (IBAction)ValueChanged:(UISlider *)sender
{
    NSLog(@"ValueChanged");
    //self.lblInfo.backgroundColor = [UIColor clearColor];
    
    LFXHSBKColor* tmpColor = [LFXHSBKColor colorWithHue:self.sliderHue.value * 360 saturation:self.sliderSaturation.value brightness:self.sliderValue.value];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    //[localNetworkContext.allLightsCollection setColor:tmpColor];
    for (NSString *aDevID in self.selectedIndexes)
    {
        LFXLight *aLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
        [aLight setColor:tmpColor overDuration:0.5];
    }

    
    [UIView transitionWithView:self.lblInfo
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    

    
    NSString* s = [NSString stringWithFormat:@"Value (Brightness): %0.2f",self.sliderValue.value];
    [self.lblInfo setText:s ];
    
    [self updateLblInfo];
    [self turnOnLights];

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
/*
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
        [self.tooltipManager hideAllTooltipsAnimated:YES];
        [self.btnHelp setSelected:NO];
        [self.btnHelp setImage: [UIImage imageNamed:@"help"] forState:UIControlStateNormal] ;
        [sender removeFromSuperview];
        sender = nil;

    }
    
}
*/
- (BOOL) shouldAutorotate
{
    return NO;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)MainConfigureAudioSession {
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}



- (IBAction)motionButtonPressed:(id)sender
{
    NSLog(@"Motion Pressed");
    UIButton *btn = (UIButton*)sender;
    NSString *BtnName = [NSString alloc];
    BtnName = [self tagToText:btn.tag]; NSLog(@"BtnName:%@",BtnName);

    //[self.someButton setHighlighted:YES]; [self.someButton sendActionsForControlEvents:UIControlEventTouchUpInside]; [self.someButton setHighlighted:NO];
    //check if any light bulbs are selected first
    if (![self checkIfSelected:BtnName]) return;
    
        
    //////////////toggle button effect
    //UIButton *btn = (UIButton*) sender;
    btn.alpha = 0;
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1];
    [UIView setAnimationDelegate:[UIApplication sharedApplication]];
    [UIView setAnimationDidStopSelector:@selector(endIgnoringInteractionEvents)];
    btn.alpha = 1;
    [UIView commitAnimations];
    //////////////////
    
    self.btnMotion.selected = !self.btnMotion.selected;
    
    if (self.btnMotion.selected)
    {
        [self saveLightState];
        
        // dont allow table interaction
        self.tableView.allowsSelection = NO;
        
        // show sliders,table etc
        //[self myfade:NO];
        [self fadeView:self.tableView Out:NO];
        [self fadeView:self.sliderBrightness Out:YES];
        [self fadeView:self.sliderHue Out:NO];
        [self fadeView:self.sliderSaturation Out:NO];
        [self fadeView:self.sliderValue Out:NO];
        [self fadeView:self.lblInfo Out:NO];
        [self fadeView:self.btnCam Out:YES];
        [self fadeView:self.btnMusic Out:YES];
        [self fadeView:self.btnYT Out:YES];
        [self fadeView:self.btnSiren Out:YES];
        NSString* s = [NSString stringWithFormat:@"X-axis (Roll) : Brightness\nY-axis (Yaw) : Hue\nZ-axis (Pitch) : Saturation"];
        [self.lblInfo setText:s ];

        
        [self.btnMotion setSelected:YES];
        [self.btnMotion setImage: [UIImage imageNamed:@"motion_on"] forState:UIControlStateNormal] ;
        self.btnMotion.alpha = 1 ;
        NSLog(@"DOING MOTION UPDATES");
        self.sliderHue.minimumValue = 0.0f;
        self.sliderHue.maximumValue = 360.0f;
        self.sliderHue.userInteractionEnabled = NO;
        self.sliderSaturation.minimumValue = 0.0f;
        self.sliderSaturation.maximumValue = 1.0f;
        self.sliderSaturation.userInteractionEnabled = NO;
        self.sliderValue.minimumValue = -180.0f;
        self.sliderValue.maximumValue = 180.0f;
        self.sliderValue.userInteractionEnabled = NO;
        self.sliderBrightness.minimumValue = -90.0f;
        self.sliderBrightness.maximumValue = 90.0f;
        self.sliderBrightness.userInteractionEnabled = NO;
        menu.hidden=YES;
        

        
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical
                                                                toQueue:self.deviceQueue
                                                            withHandler:^(CMDeviceMotion *motion, NSError *error)
         {
             [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                 
                 CGFloat brightness;
                 CGFloat hue;
                 CGFloat saturation;
                 
                 if (motion.userAcceleration.x < -2.0f)
                 {
                     NSLog(@"***********************************OUCH!");
                 }
                 
                 
                 
                 CGFloat Roll =  motion.attitude.roll  * 180 / M_PI;
                 CGFloat Pitch = motion.attitude.pitch * 180 / M_PI;
                 CGFloat Yaw =   motion.attitude.yaw * 180 / M_PI;    //if (Yaw>90)Yaw=90;
                 
                 //NSLog(@"Pitch %f ",motion.attitude.pitch * 180 / M_PI);
                 //NSLog(@"***********************************");
                 //NSLog(@"Roll  %f ",Roll);
                 NSLog(@"\nPitch %f \n",Pitch);
                 CGFloat Yaw360 = Yaw;
                 //NSLog(@"Yaw %f ",Yaw);
                 if (Yaw<0) Yaw360=360+Yaw;
                 //NSLog(@"Yaw360 %f ",Yaw360);
                 
                 Pitch  = fabsf(Pitch); if (Pitch > 90.0) Pitch = 90;
                 NSLog(@"\n normalised Pitch %f \n",Pitch);
                 self.sliderBrightness.value = Roll;
                 self.sliderValue.value = Roll;
                 self.sliderHue.value = Yaw360;
                 
                 
                 
                 
                 
                 brightness= (Roll+90.0)/180.0;/*NSLog(@"unfiltered brightness:%f",brightness); */   if (brightness>1) brightness=1;if (brightness<0) brightness=0;
                 brightness= (Roll+180.0)/360.0; if (brightness>1) brightness=1;if (brightness<0) brightness=0;

                 hue = Yaw360 ;               //if (hue>360) hue=360;if (hue<0) hue=0;
                 
                 saturation = 1-(Pitch/90.0); if (saturation>1) saturation=1;if (saturation<0) saturation=0;
                 self.sliderSaturation.value = saturation;
                 NSLog(@"\n saturation  %f \n",saturation);
                
                 //NSLog(@"before check prevBrightness:%f",prevBrightness);
                 if (
                     ( (brightness < 0.1) && (prevBrightness>0.9) ) ||
                     ( (brightness > 0.9) && (prevBrightness<0.1) )
                     )
                 {
                     //NSLog(@"****Saving brightness");
                     brightness = prevBrightness;
                 }
                 //NSLog(@"brightness:%f",brightness);NSLog(@"prevBrightness:%f",prevBrightness);
                 prevBrightness = brightness;
                 //NSLog(@"hue:%f",hue);
                 //NSLog(@"saturation:%f",saturation);
                 
                 LFXHSBKColor *colour = [LFXHSBKColor colorWithHue:hue saturation:saturation brightness:brightness];
                 
                 LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
                 //[localNetworkContext.allLightsCollection setColor:colour];
                 /*for (NSString *aDevID in self.selectedIndexes)
                 {
                     LFXLight *aLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
                     [aLight setColor:colour overDuration:0.5];
                 }
                  */
                 for (LFXLight *aLight in self.mainSelectedLights)
                  {
                  [aLight setColor:colour overDuration:0.5];
                  }
                  

                 
                 // change test lblInfo background colour to indicate change on device screen
                 self.lblInfo.backgroundColor = [UIColor colorWithHue:(hue/360.0) saturation:saturation brightness:brightness alpha:1];
                 
                 
                 
             }];
         }];

    }
    else
    {
        self.tableView.allowsSelection = YES;
        //[self myfade:YES];
        [self fadeView:self.tableView Out:YES];
        [self fadeView:self.sliderBrightness Out:YES];
        [self fadeView:self.sliderHue Out:YES];
        [self fadeView:self.sliderSaturation Out:YES];
        [self fadeView:self.sliderValue Out:YES];
        [self fadeView:self.lblInfo Out:YES];
        [self fadeView:self.btnCam Out:NO];
        [self fadeView:self.btnMusic Out:NO];
        [self fadeView:self.btnYT Out:NO];
        [self fadeView:self.btnSiren Out:NO];
        NSString* s = [NSString stringWithFormat:@""];
        [self.lblInfo setText:s ];

        
        [self.btnMotion setSelected:NO];
        [self.motionManager stopDeviceMotionUpdates];
        NSLog(@"STOPPING MOTION UPDATES");
        self.sliderHue.minimumValue = 0.0f;
        self.sliderHue.maximumValue = 1.0f;
        self.sliderHue.userInteractionEnabled = YES;
        self.sliderSaturation.minimumValue = 0.0f;
        self.sliderSaturation.maximumValue = 1.0f;
        self.sliderSaturation.userInteractionEnabled = YES;
        self.sliderValue.minimumValue = 0.0f;
        self.sliderValue.maximumValue = 1.0f;
        self.sliderValue.userInteractionEnabled = YES;
        self.sliderBrightness.minimumValue = 0.0f;
        self.sliderBrightness.maximumValue = 1.0f;
        self.sliderBrightness.userInteractionEnabled = YES;

        //self.lblInfo.backgroundColor = [UIColor clearColor];

        [self.btnMotion setImage: [UIImage imageNamed:@"motion"] forState:UIControlStateNormal] ;
        self.btnMotion.alpha = 0;

         menu.hidden=NO;
        
        [self restoreLightState];
    }
    
    
    
}

// used to fade views in and out.
- (void) fadeView:(UIView *)myView Out:(BOOL)Out
{
    
    [UIView transitionWithView:myView
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    
    myView.hidden = Out;
    

}


//ShakeToToggle animation
-(void) animateOn
{
    NSLog(@"***animating ***");
    
    self.lblInfo.backgroundColor = [UIColor redColor];
    self.lblInfo.textColor = [UIColor whiteColor];
   

    NSString* s = [NSString stringWithFormat:@"Shake to Toggle Lights Activated\n(Shake again to turn them back on)"];
    [self.lblInfo setText:s ];
    self.lblInfo.hidden = NO;
    [self.lblInfo setAlpha:1.f];
    
    //////////////toggle lblInfo effect
    [UIView animateWithDuration:0.5f
                          delay:0.5f
                        options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                     animations:^{
                          //[UIView setAnimationRepeatCount:4.5];
                         //NSLog(@"in animation alpha:%f",self.imgBox.alpha);
                         [self.lblInfo setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         if (finished) NSLog(@"done");
                         //[self.imgBox setAlpha:0.f];
                     }];
    

     //////////////////

    
}

-(void) toggleLights
{
    static BOOL saved_tableView;
    static BOOL saved_sliderBrightness;
    static BOOL saved_sliderHue;
    static BOOL saved_sliderSaturation;
    static BOOL saved_sliderValue;
    static BOOL saved_lblInfo;
    //static BOOL saved_tableView;
    //static BOOL saved_tableView;
    
    NSLog(@"***SHAKE SHAKE SHAKE***gShaken:%d",gShaken); gShaken = !gShaken;
    if (!gShaken)
    {
        //stop the flashing red alert
        [self.lblInfo.layer removeAllAnimations];
        [self fadeView:self.tableView Out:saved_tableView];
        [self fadeView:self.sliderBrightness Out:saved_sliderBrightness];
        [self fadeView:self.sliderHue Out:saved_sliderHue];
        [self fadeView:self.sliderSaturation Out:saved_sliderSaturation];
        [self fadeView:self.sliderValue Out:saved_sliderValue];
        [self fadeView:self.lblInfo Out:NO];
        
        [self fadeView:self.btnCam Out:NO];
        [self fadeView:self.btnMusic Out:NO];
        [self fadeView:self.btnYT Out:NO];
        [self fadeView:self.btnMotion Out:NO];
        [self fadeView:self.btnSiren Out:NO];
        
        
    }
    else
    {
        // start flashing red animation
        [self animateOn];
        
        saved_tableView = self.tableView.hidden;
        saved_sliderBrightness = self.sliderBrightness.hidden;
        saved_sliderHue = self.sliderHue.hidden;
        saved_sliderSaturation = self.sliderSaturation.hidden;
        saved_sliderValue = self.sliderValue.hidden;

        
        [self fadeView:self.tableView Out:YES];
        [self fadeView:self.sliderBrightness Out:YES];
        [self fadeView:self.sliderHue Out:YES];
        [self fadeView:self.sliderSaturation Out:YES];
        [self fadeView:self.sliderValue Out:YES];
        [self fadeView:self.btnCam Out:YES];
        [self fadeView:self.btnMusic Out:YES];
        [self fadeView:self.btnYT Out:YES];
        [self fadeView:self.btnMotion Out:YES];
        [self fadeView:self.btnSiren Out:YES];

        
    }
    
    
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    for (LFXLight *aLight in localNetworkContext.allLightsCollection)
    {
        for (NSString *aDevID in self.selectedIndexes)
        {
            //LFXLight *aSelLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
            if ([aLight.deviceID isEqualToString:aDevID])
            {
                aLight.powerState  = !aLight.powerState;
            }
            
        }
    }// end for
}


- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    NSLog(@"**motionEnded()");
    if (self.btnMotion.selected) return;

    if (motion == UIEventSubtypeMotionShake)
    {
        [self toggleLights];
       
        [self logIt:@"ShakeToToggle"];
    }
    
}

- (IBAction)btnSirenPressed:(UIButton *)sender
{
    NSLog(@"***btnSirenPressed()");
    CGFloat savedVolume=0;
    
    UIButton *btn = (UIButton*)sender;
    NSString *btnName = [NSString alloc];
    btnName = [self tagToText:btn.tag]; NSLog(@"btnName:%@",btnName);
    [self logIt:btnName];
    /*
    //////////////toggle button effect
    sender.alpha = 0;
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1];
    [UIView setAnimationDelegate:[UIApplication sharedApplication]];
    [UIView setAnimationDidStopSelector:@selector(endIgnoringInteractionEvents)];
    sender.alpha = 1;
    [UIView commitAnimations];
    //////////////////
    */
    savedVolume = [self getVolume];
    [self saveLightState];
    
   [self setVolume:1.0f];
     NSLog(@"current Playing volume:%f",[self getVolume]);
    mysoundaudioPlayer.currentTime = 0;
    [mysoundaudioPlayer play];
    
    //[self setVolume:savedVolume];
    
    
    [NSThread detachNewThreadSelector: @selector(FlashLightOnSeparateThread:) toTarget: self withObject:[NSNumber numberWithFloat:savedVolume]];
    
    /*
    self.btnSiren.selected = !self.btnSiren.selected;
    if (self.btnSiren.selected)
    {
        
        [self.btnSiren setSelected:YES];
        
    }
    else
    {
        
        [self.btnSiren setSelected:NO];
        
    }
    */

    
}
- (void)FlashLightOnSeparateThread: (NSNumber *) restoreVolume
//- (void)FlashLightOnSeparateThread
{
    NSLog (@"Flashing... ");
    
    //CGFloat hue, saturation, brightness, alpha;
    
  
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    [localNetworkContext.allLightsCollection setPowerState:LFXPowerStateOn];
    
    LFXHSBKColor *color = localNetworkContext.allLightsCollection.color;
    color.hue = 1;
    color.brightness = 1;
    color.saturation = 1;
    [localNetworkContext.allLightsCollection setColor:color];
    
    sleep(1);
    //color.hue = 0.1;
    color.brightness = 0.1;
    //color.saturation = 0.1;
    [localNetworkContext.allLightsCollection setColor:color] ;
    
    sleep(1);
    color.hue = 1;
    color.brightness = 1;
    color.saturation = 1;
    [localNetworkContext.allLightsCollection setColor:color];
    
    sleep(1);
    [localNetworkContext.allLightsCollection setColor:color];

    [self restoreLightState];
    [self setVolume:[restoreVolume floatValue] ];
    
   
    
}



-(void) viewDidDisappear:(BOOL)animated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud hide:YES];
    });
    
    [super viewDidDisappear:animated];
   
    // Do not set ad delegate to nil and
    // Do not remove ad in the viewWillDisappear or viewDidDisappear method
    
}



#pragma mark - Load Assets

- (void)loadAssets {
    if (NSClassFromString(@"PHAsset")) {
        
        // Check library permissions
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    [self performLoadAssets];
                }
            }];
        } else if (status == PHAuthorizationStatusAuthorized) {
            [self performLoadAssets];
        }
        
    } else {
        
        // Assets library
        [self performLoadAssets];
        
    }
}

- (void)performLoadAssets {
    
    // Initialise
    _assets = [NSMutableArray new];
    
    // Load
    if (NSClassFromString(@"PHAsset")) {
        
        // Photos library iOS >= 8
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            PHFetchOptions *options = [PHFetchOptions new];
            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
            PHFetchResult *fetchResults = [PHAsset fetchAssetsWithOptions:options];
            [fetchResults enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [_assets addObject:obj];
            }];
            if (fetchResults.count > 0) {
                [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            }
        });
        
    } else {
        
        // Assets Library iOS < 8
        _ALAssetsLibrary = [[ALAssetsLibrary alloc] init];
        
        // Run in the background as it takes a while to get all assets from the library
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
            NSMutableArray *assetURLDictionaries = [[NSMutableArray alloc] init];
            
            // Process assets
            void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (result != nil) {
                    NSString *assetType = [result valueForProperty:ALAssetPropertyType];
                    if ([assetType isEqualToString:ALAssetTypePhoto] || [assetType isEqualToString:ALAssetTypeVideo]) {
                        [assetURLDictionaries addObject:[result valueForProperty:ALAssetPropertyURLs]];
                        NSURL *url = result.defaultRepresentation.url;
                        [_ALAssetsLibrary assetForURL:url
                                          resultBlock:^(ALAsset *asset) {
                                              if (asset) {
                                                  @synchronized(_assets) {
                                                      [_assets addObject:asset];
                                                      if (_assets.count == 1) {
                                                          // Added first asset so reload data
                                                          [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                                                      }
                                                  }
                                              }
                                          }
                                         failureBlock:^(NSError *error){
                                             NSLog(@"operation was not successfull!");
                                         }];
                        
                    }
                }
            };
            
            // Process groups
            void (^ assetGroupEnumerator) (ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
                if (group != nil) {
                    [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:assetEnumerator];
                    [assetGroups addObject:group];
                }
            };
            
            // Process!
            [_ALAssetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                            usingBlock:assetGroupEnumerator
                                          failureBlock:^(NSError *error) {
                                              NSLog(@"There is an error");
                                          }];
            
        });
        
    }
    
}


#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _thumbs.count)
        return [_thumbs objectAtIndex:index];
    return nil;
}

//- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
//    MWPhoto *photo = [self.photos objectAtIndex:index];
//    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
//    return [captionView autorelease];
//}

//- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
//    NSLog(@"ACTION!");
//}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
    
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return [[_selections objectAtIndex:index] boolValue];
}

//- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
//    return [NSString stringWithFormat:@"Photo %lu", (unsigned long)index+1];
//}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    [_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - FlurryAds


-(IBAction) showAdClickedButton:(id)sender
{
    NSLog(@"showAdClickedButton()");
    
    // Check if ad is ready. If so, display the ad
    
    //if ([adInterstitial ready]) {
    //  NSLog(@"adInterstitial ready");
    //[adInterstitial presentWithViewController:self];
    //} else {
    //   NSLog(@"adInterstitial NOT ready");
    
    //[adInterstitial fetchAd];
    //}
    
    
    //[FlurryAds fetchAndDisplayAdForSpace:@"BottomBannerAd" view:self.view viewController:self size:BANNER_BOTTOM];
    
}

- (void) adInterstitialDidFetchAd:(FlurryAdInterstitial*)interstitialAd
{
    NSLog(@"adInterstitialDidFetchAd()");
    
    // you can choose to present the ad as soon as it is received
    [interstitialAd presentWithViewController:self];
}

//  Invoked when the interstitial ad is rendered.
- (void) adInterstitialDidRender:(FlurryAdInterstitial *)interstitialAd
{
    NSLog(@"adInterstitialDidRender()");
    
}

//Informs the app that a video associated with this ad has finished playing.
//Only present for rewarded & client-side rewarded ad spaces
- (void) adInterstitialVideoDidFinish:(FlurryAdInterstitial *)interstitialAd
{
    NSLog(@"adInterstitialVideoDidFinish()");
    
}

//Informational callback invoked when there is an ad error
- (void) adInterstitial:(FlurryAdInterstitial*)interstitialAd
                adError:(FlurryAdError) adError
       errorDescription:(NSError*) errorDescription
{
    // @param interstitialAd The interstitial ad object associated with the error
    // @param adError an enum that gives the reason for the error.
    // @param errorDescription An error object that gives additional information on the cause of the ad error.
    NSLog(@"adInterstitial errro(): ad:%@ adError:%d   desc:%@",interstitialAd,adError,errorDescription);
    
}

- (void) adBanner:		(FlurryAdBanner *) 	bannerAd
          adError:		(FlurryAdError) 	adError
 errorDescription:		(NSError *) 	errorDescription
{
    NSLog(@"adBanner errro(): ad:%@ adError:%d   desc:%@",bannerAd,adError,errorDescription);
}
- (void) adBannerDidDismissFullscreen:		(FlurryAdBanner *) 	bannerAd
{
    NSLog(@"%s()",__FUNCTION__);
}
- (void) adBannerDidFetchAd:		(FlurryAdBanner *) 	bannerAd
{
    NSLog(@"%s() bannerAd:%@",__FUNCTION__,bannerAd);
    
}
- (void) adBannerDidReceiveClick:		(FlurryAdBanner *) 	bannerAd
{
    NSLog(@"%s()",__FUNCTION__);
    
}
- (void) adBannerDidRender:		(FlurryAdBanner *) 	bannerAd
{
    NSLog(@"%s()",__FUNCTION__);
    
}
- (void) adBannerVideoDidFinish:		(FlurryAdBanner *) 	bannerAd
{
    NSLog(@"%s()",__FUNCTION__);
    
}
- (void) adBannerWillDismissFullscreen:		(FlurryAdBanner *) 	bannerAd
{
    NSLog(@"%s()",__FUNCTION__);
    
}
- (void) adBannerWillLeaveApplication:		(FlurryAdBanner *) 	bannerAd
{
    NSLog(@"%s()",__FUNCTION__);
    
}
- (void) adBannerWillPresentFullscreen:		(FlurryAdBanner *) 	bannerAd
{
    NSLog(@"%s()",__FUNCTION__);
    
}


#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud2 {
    NSLog(@"HIDING MBProgressHUD ");
    // Remove HUD from screen when the HUD was hidded
    [hud2 removeFromSuperview];
    hud2 = nil;
}

@end
