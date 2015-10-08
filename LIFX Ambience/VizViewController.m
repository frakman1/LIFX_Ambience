//
//  VizViewController.m
//  LIFX Ambience
//
//  Created by alnaumf on 6/23/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import "VizViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "VisualizerView.h"
#import <LIFXKit/LIFXKit.h>
#import "UIAlertView+NSCookbook.h"
#import <UIKit/UIKit.h>
#import "TableViewController.h"
#import "MarqueeLabel.h"
#import "ANPopoverSlider.h"
#import "JDFTooltips.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@interface SystemVolumeView : MPVolumeView

@end

@implementation SystemVolumeView

- (CGRect)volumeSliderRectForBounds:(CGRect)bounds {
    CGRect newBounds=[super volumeSliderRectForBounds:bounds];
    
    newBounds.origin.y=bounds.origin.y;
    newBounds.size.height=bounds.size.height;
    
    return newBounds;
}

- (CGRect) routeButtonRectForBounds:(CGRect)bounds {
    CGRect newBounds=[super routeButtonRectForBounds:bounds];
    
    newBounds.origin.y=bounds.origin.y;
    newBounds.size.height=bounds.size.height;
    
    return newBounds;
}

@end

@interface VizViewController () </*UITableViewDataSource, UITableViewDelegate,*/ AVAudioPlayerDelegate,UIAlertViewDelegate,UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UIToolbar *toolBar;
@property (strong, nonatomic) NSArray *playItems;
@property (strong, nonatomic) NSArray *pauseItems;
@property (strong, nonatomic) UIBarButtonItem *playBBI;
@property (strong, nonatomic) UIBarButtonItem *pauseBBI;

@property (nonatomic, retain) MPMediaItemCollection*    playlist;
@property (nonatomic, retain) MPMediaItemCollection*    limboPlaylist;

@property (nonatomic, strong) JDFTooltipManager *tooltipManager1;
@property (nonatomic, strong) JDFTooltipManager *tooltipManager;


// Add properties here
//@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) VisualizerView *visualizer;

//FRAK Audio Player
@property (nonatomic, strong) FSAudioPlayer *myaudioPlayer;
@property NSTimer *timer;
@property NSTimer *tickerTimer;

@end

@implementation VizViewController
{
    //BOOL _isBarHide;
    //BOOL _isPlaying;
    float gSavedVolume;
    int gcurrenSong;
    UISlider *myslider_threshold;
    UISlider *myslider_scale;
    UIImageView *imgExpo;
    UIImageView *imgOffset;
    UILabel *lblOffset;
    UILabel *lblExpo;
    BOOL firstTime;
    CGFloat gLockedHue;
}
@synthesize playlist,limboPlaylist,toolbar,powerLevel;

BOOL gRepeatEnabled = false;

- (void) myTick:(NSTimer *)timer
{
    //NSLog(@"myTick");
 //   dispatch_async(dispatch_get_main_queue(),
   //    ^{
           self.powerLevel.value = self.visualizer.LevelValue;
           self.powerLevel.leftChannelLevel = self.visualizer.LevelValue;
           //self.powerLevel.rightChannelLevel = self.visualizer.LevelValue;
     //  });
    

}

- (void) startPlaying
{
    NSLog(@"startPlaying() gcurrentSong:%d",gcurrenSong);
    
    [self.imgBox.layer removeAllAnimations];

    
    MPMediaItem *item = [[playlist items] objectAtIndex:gcurrenSong];
    NSURL *myurl = [item valueForProperty:MPMediaItemPropertyAssetURL];
    NSLog(@"url:%@",myurl);
    NSLog(@"self.isPaused:%d",self.isPaused);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:gcurrenSong forKey:@"mySong"];
    [defaults synchronize];

    
    
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle ];
    
    if (!myurl)
    {
        /*
         * !!!: When MPMediaItemPropertyAssetURL is nil, it typically means the file
         * in question is protected by DRM. (old m4p files)
         */
        NSLog(@" *** ERROR *** %@ has DRM  *** ERROR *** ",title);
    }
    
    
    //if (title.length>25) title = [title substringToIndex:25];
    //[title  appendString: [item valueForProperty:MPMediaItemPropertyTitle] ];
    //title = [title substringToIndex:27];
    //NSString *newtitle = [NSString stringWithFormat:@"~~~~~~~~~~ %@ ~~~~~~~~~~",title];NSLog(@"%@",newtitle);
    NSString *newtitle = [NSString stringWithFormat:@"%@.",title];NSLog(@"%@",newtitle);
    self.mlblSongTitle.text = newtitle;
    //[self.mlblSongTitle sizeToFit];
    
    
    NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];
    self.mlblSongArtist.text = artist;

    
    if (self.myaudioPlayer.audioPlayer.isPlaying)
    {
        [self.myaudioPlayer stopAudio];
    }
    [self myplayURL:myurl];
    
}

- (BOOL) prefersStatusBarHidden {return YES;}





- (void)viewDidAppear:(BOOL)animated {
    NSLog (@"***viewDidAppear***");
    [super viewDidAppear:animated];
    
    if (!self.tickerTimer.isValid)
    {
        NSLog(@"creating ticker timer");
        self.tickerTimer = [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector:@selector(myTick:) userInfo: nil repeats:YES];
    }
    else
    {
        NSLog(@"no need for new timer");
    }
    //NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
    //[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    CGFloat tooltipWidth = 100.0f;
    self.tooltipManager1 = [[JDFTooltipManager alloc] initWithHostView:self.view];
    
    [self.tooltipManager1 addTooltipWithTargetView:self.btnMixer hostView:self.view tooltipText:@"Tweak Sensitivity" arrowDirection:JDFTooltipViewArrowDirectionDown width:tooltipWidth+20];
    
    [self.tooltipManager1 addTooltipWithTargetView:self.btnRepeat hostView:self.view tooltipText:@"Repeat Song" arrowDirection:JDFTooltipViewArrowDirectionDown width:tooltipWidth];
    
    //CGRectMake(30, CGRectGetMaxY(label1.frame) + 100.0f, labelWidth, labelHeight)
    
    //[self.tooltipManager addTooltipWithTargetPoint:CGPointMake( CGRectGetMaxX(self.toolbar.frame) , self.toolbar.frame.origin.y  )  tooltipText:@"Playlist" arrowDirection:JDFTooltipViewArrowDirectionRight hostView:self.toolbar width:100];
    
    [self.tooltipManager1 addTooltipWithTargetView:self.btnPlaylist hostView:self.view tooltipText:@"Playlist" arrowDirection:JDFTooltipViewArrowDirectionDown width:tooltipWidth];
    
    self.tooltipManager = [[JDFTooltipManager alloc] initWithHostView:[self.navigationController view]];
    
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnHelp2.center.x, self.btnHelp2.center.y+25) tooltipText:@"Tap to dismiss" arrowDirection:JDFTooltipViewArrowDirectionUp hostView:[self.navigationController view] width:180];
    
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnAddMusic.center.x, self.btnAddMusic.center.y) tooltipText:@"Add Songs" arrowDirection:JDFTooltipViewArrowDirectionRight hostView:[self.navigationController view] width:80];
    
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake((self.view.bounds.size.width / 2.0), (self.view.bounds.size.height / 2.0) + 20 ) tooltipText:@"Tap and Swipe here\n\n↑: Volume Up.\n↓: Volume Down.\n← : Next Song.\n→ : Previous Song.\nDouble Tap : Toggle Play/Pause." arrowDirection:JDFTooltipViewArrowDirectionDown hostView:[self.navigationController view] width:300];
    
}

//This function gets called AFTER autolayout/contraint has finished and BEFORE viewWillAppear
- (void)viewDidLayoutSubviews
{
    
    [super viewDidLayoutSubviews];

    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear()");
    NSLog(@"***Overriding orientation.");
    [UIView setAnimationsEnabled:YES];
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    
     _visualizer.sliderThresholdValue = myslider_threshold.value;
    _visualizer.vizInputLights  = self.inputLights;
    _visualizer.vizInputLights2 = self.inputLights2;
    

    
    NSLog(@"Received input lights list: %@",self.inputLights);
    NSLog(@"Received input lights2 list: %@",self.inputLights2);


    
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    NSLog(@"%@",parent.title );
    if (![parent isEqual:self.parentViewController])
    {
        NSLog(@"Back pressed");
        
        if ([self.myaudioPlayer isPlaying])
        {
            NSLog (@"Stopping audio");
            //[_audioPlayer stop];
            [self.myaudioPlayer stopAudio];
        }
        
        if(self.timer)
        {
            [self.timer invalidate];
            self.timer = nil;
        }
        if(self.tickerTimer)
        {
            [self.tickerTimer invalidate];
            self.tickerTimer = nil;
       }
        
        //[self.myaudioPlayer stopAudio];
        
        
        
        
        [self.visualizer vizStop];
        [self.visualizer removeFromSuperview];
        

        NSArray *viewsToRemove = [self.view subviews];
        for (UIView *v in viewsToRemove)
        {
            NSLog(@"removing view  %@", v);
            [v removeFromSuperview];
        }
        
        /*
        LFXHSBKColor* tmpColor = [LFXHSBKColor whiteColorWithBrightness:1  kelvin:3500];
        LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
        //[localNetworkContext.allLightsCollection setColor:tmpColor];
        NSLog(@"self.inputLights:%@",self.inputLights);
        for (NSString *aDevID in self.inputLights)
        {
            LFXLight *aLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
            [aLight setColor:tmpColor];
        }
        */
         //NSLog(@"Received input lights2 list: %@",self.inputLights2);

   
    }
}


-(void) viewWillDisappear:(BOOL)animated
{
    NSLog (@"***viewWillDisappear***");
    [self.tooltipManager hideAllTooltipsAnimated:FALSE];
    [self.tooltipManager1 hideAllTooltipsAnimated:FALSE];
    
    
    MPVolumeView* volumeView = [[MPVolumeView alloc] init];
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    gSavedVolume = volumeViewSlider.value ;
    NSLog (@"Saving gSavedVolume value :%f",gSavedVolume);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:gSavedVolume forKey:@"myVolume"];
    [defaults synchronize];

    [self resignFirstResponder];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog (@"****viewDidLoad****");
    
    //[self setCustomSlider];
    
    [self configureBars];
    
    [self configureAudioSession];
    
   // self.tickerTimer=nil;[self.tickerTimer invalidate];
    NSLog(@"creating ticker timer");
    self.tickerTimer = [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector:@selector(myTick:) userInfo: nil repeats:YES];
    
   // self.visualizer = [[VisualizerView alloc] initWithFrame:self.view.frame];
    self.visualizer = [[VisualizerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    NSLog (@"***width:%f  height:%f ***",self.view.frame.size.width,self.view.frame.size.height);
    [_visualizer setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [_backgroundView addSubview:_visualizer];
    //[_backgroundView sendSubviewToBack:_visualizer];
    //[self.view sendSubviewToBack:_visualizer];
    [[self.audioPlayerBackgroundLayer superview] bringSubviewToFront:self.audioPlayerBackgroundLayer];
    [[self.currentTimeSlider superview] bringSubviewToFront:self.currentTimeSlider];
    [[self.duration superview] bringSubviewToFront:self.duration];
    [[self.timeElapsed superview] bringSubviewToFront:self.timeElapsed];
    
    [[self.mlblSongArtist superview] bringSubviewToFront:self.mlblSongArtist];
    [[self.playButton superview] bringSubviewToFront:self.playButton];
    [[self.toolbar superview] bringSubviewToFront:self.toolbar];
    [[self.lbltitleBackground superview] bringSubviewToFront:self.lbltitleBackground];
    [[self.mlblSongTitle superview] bringSubviewToFront:self.mlblSongTitle];
    [[self.btnnext superview] bringSubviewToFront:self.btnnext];
    [[self.btnprevious superview] bringSubviewToFront:self.btnprevious];

    [self.playButton setShowsTouchWhenHighlighted:YES];
    [[self.powerLevel superview] bringSubviewToFront:self.powerLevel];
    [[self.imgBox superview] bringSubviewToFront:self.imgBox];
    
    [self.viewVolumeView setShowsVolumeSlider:YES];
    [self.viewVolumeView setShowsRouteButton:YES];
    [self.viewVolumeView sizeToFit];
    [self.viewVolumeView setVolumeThumbImage: [UIImage imageNamed:@"vknob2"] forState:UIControlStateNormal];
    [[self.viewVolumeView superview] bringSubviewToFront:self.viewVolumeView];
    [[self.colourSlider superview] bringSubviewToFront:self.colourSlider];
    
    
    //[self.imgBox setImage:[UIImage imageNamed:@"play2"]];
   // UIImage *repeatOn = [UIImage imageNamed:@"repeat_on"];
    //UIImage *repeat   = [UIImage imageNamed:@"repeat"];
    //[self.btnRepeat setImage:repeatOn   forState:UIControlStateSelected];
    //[self.btnRepeat setImage:repeat     forState:UIControlStateNormal];
    
    
    [self configuremyAudioPlayer];
    
    // Setup Main soundtrack player
    
    //NSString *filename = [self.gameSelection stringByAppendingString:@".mp3"];
    //NSLog(@"crafed filename: %@",filename);
    [self.currentTimeSlider setThumbImage: [UIImage imageNamed:@"metalknob"] forState:UIControlStateNormal];
    [self.currentTimeSlider setMaximumTrackImage:[UIImage imageNamed:@"whitetrack"]   forState:UIControlStateNormal];
    [self.currentTimeSlider setMinimumTrackImage:[[UIImage imageNamed:@"bluetrack"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)]   forState:UIControlStateNormal];
    
    [self.colourSlider setThumbImage: [UIImage imageNamed:@"metalknob"] forState:UIControlStateNormal];
    //[self.colourSlider setMaximumTrackImage:[UIImage imageNamed:@"colourtrack"] forState:UIControlStateNormal];
    [self.colourSlider setMaximumTrackImage:[[UIImage imageNamed:@"colourtracklong"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch]  forState:UIControlStateNormal];
    [self.colourSlider setMinimumTrackImage:[[UIImage imageNamed:@"colourtracklong"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeTile]  forState:UIControlStateNormal];


    
    //self.powerLevel setThumbImage: [UIImage imageNamed:@"metalknob2"] forState:UIControlStateNormal];
    //[self.powerLevel setMaximumTrackImage:[UIImage imageNamed:@"whitetrack"]   forState:UIControlStateNormal];
    //[self.powerLevel setMinimumTrackImage:[[UIImage imageNamed:@"purpletrack"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4) resizingMode:UIImageResizingModeTile]  forState:UIControlStateNormal];
    
    //[self.powerLevel setThumbImage: [UIImage imageNamed:@"slider-knob"] forState:UIControlStateNormal];
    [self.powerLevel setThumbImage: [UIImage new] forState:UIControlStateNormal];

    [self.powerLevel setMaximumTrackImage:[UIImage imageNamed:@"nil"]   forState:UIControlStateNormal];
    [self.powerLevel setMinimumTrackImage:[[UIImage imageNamed:@"nil"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4) resizingMode:UIImageResizingModeTile]  forState:UIControlStateNormal];

    
    
    
    // Setup Marquee as Continuous Type
    self.mlblSongTitle.tag = 101;
    self.mlblSongTitle.marqueeType = MLContinuous;
    self.mlblSongTitle.scrollDuration = 6.0;
    self.mlblSongTitle.animationCurve = UIViewAnimationOptionCurveLinear;
    self.mlblSongTitle.fadeLength = 0.0f;
    self.mlblSongTitle.leadingBuffer = 10.0f;
    self.mlblSongTitle.trailingBuffer = 10.0f;
    // Text string for this label is set via Interface Builder!
    self.mlblSongArtist.tag = 102;
    self.mlblSongArtist.marqueeType = MLContinuousReverse;
    self.mlblSongArtist.scrollDuration = 6.0;
    self.mlblSongArtist.animationCurve = UIViewAnimationOptionCurveLinear;
    self.mlblSongArtist.fadeLength = 0.0f;
    self.mlblSongArtist.leadingBuffer = 10.0f;
    self.mlblSongArtist.trailingBuffer = 10.0f;
    
    
    //create vertical slider - Threshold (DC Offset)
    myslider_threshold = [[ANPopoverSlider alloc] initWithFrame:CGRectMake(self.view.frame.origin.x-70, 240, 200, 30)];
    myslider_threshold.value=0.2; _visualizer.sliderThresholdValue = myslider_threshold.value;
    myslider_threshold.transform = CGAffineTransformRotate(myslider_threshold.transform, -0.5*M_PI);
    [self.view addSubview:myslider_threshold];
    [myslider_threshold addTarget:self action:@selector(updateslider_threshold:) forControlEvents:UIControlEventValueChanged];
    [myslider_threshold setThumbImage: [UIImage imageNamed:@"metalknob"] forState:UIControlStateNormal];
    [myslider_threshold setMaximumTrackImage:[UIImage imageNamed:@"whitetrack"]   forState:UIControlStateNormal];
    [myslider_threshold setMinimumTrackImage:[[UIImage imageNamed:@"greentrack"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)]   forState:UIControlStateNormal];

    myslider_threshold.hidden = TRUE;
    
    //imgOffset = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"offset"]];
    //imgOffset.frame=CGRectMake(myslider_threshold.center.x-50, myslider_threshold.frame.origin.y+myslider_threshold.frame.size.height+10, 101,62);
    //imgOffset.frame=CGRectMake(100,100 ,35,29);
    
    lblOffset = [[UILabel alloc] init];
    lblOffset.textColor = [UIColor whiteColor];
    lblOffset.font=[lblOffset.font fontWithSize:15];
    lblOffset.numberOfLines = 0;
    [lblOffset sizeToFit];
    lblOffset.textAlignment = NSTextAlignmentCenter;
    //lblOffset.lineBreakMode= NSLineBreakByWordWrapping ;
    lblOffset.text = @"Brightness \nThreshold";
    lblOffset.frame = CGRectMake(myslider_threshold.center.x-30,
                             myslider_threshold.frame.origin.y+myslider_threshold.frame.size.height-60,
                             90,
                             180);
    
    
    imgOffset.hidden = TRUE;
    lblOffset.hidden = TRUE;
    //[self.view addSubview:imgOffset];
    [self.view addSubview:lblOffset];
    

    
    
    //create vertical slider - Scaler
    myslider_scale = [[ANPopoverSlider alloc] initWithFrame:CGRectMake(self.view.frame.size.width-130, 240, 200, 30)];
    myslider_scale.maximumValue = 10;
    myslider_scale.minimumValue = 1;
    myslider_scale.value=1;  _visualizer.sliderScaleValue =  myslider_scale.value;
    myslider_scale.transform = CGAffineTransformRotate(myslider_scale.transform, -0.5*M_PI);
    [self.view addSubview:myslider_scale];
    [myslider_scale addTarget:self action:@selector(updateslider_scale:) forControlEvents:UIControlEventValueChanged];
    [myslider_scale setThumbImage: [UIImage imageNamed:@"metalknob"] forState:UIControlStateNormal];
    [myslider_scale setMaximumTrackImage:[UIImage imageNamed:@"whitetrack"]   forState:UIControlStateNormal];
    [myslider_scale setMinimumTrackImage:[[UIImage imageNamed:@"greentrack"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)]    forState:UIControlStateNormal];

    myslider_scale.hidden = TRUE;
    
    NSLog (@"myslider_scale x:%f y:%f width:%f height:%f",myslider_scale.frame.origin.x,myslider_scale.frame.origin.y,myslider_scale.frame.size.width,myslider_scale.frame.size.height);
    
    //imgExpo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"expo"]];
    //imgExpo.frame=CGRectMake(myslider_scale.center.x-50, myslider_scale.frame.origin.y+myslider_scale.frame.size.height+10, 101, 62);
    
    
    lblExpo = [[UILabel alloc] init];
    lblExpo.textColor = [UIColor whiteColor];
    lblExpo.font=[lblExpo.font fontWithSize:15];
    lblExpo.numberOfLines = 0;
    [lblExpo sizeToFit];
    lblExpo.textAlignment = NSTextAlignmentCenter;
    //lblExpo.lineBreakMode= NSLineBreakByWordWrapping ;
    lblExpo.text = @"Sensitivity";
    lblExpo.frame = CGRectMake(myslider_scale.center.x-50, lblOffset.frame.origin.y, 90, 180);
    lblExpo.hidden = TRUE;
    
    
    //[self.view addSubview:imgExpo];
    [self.view addSubview:lblExpo];
    

    NSLog (@"myslider_threshold x:%f y:%f width:%f height:%f",myslider_threshold.frame.origin.x,myslider_threshold.frame.origin.y,myslider_threshold.frame.size.width,myslider_threshold.frame.size.height);
    
    //UIBarButtonItem *item = (UIBarButtonItem *)self.navigationItem.rightBarButtonItem;
    //UIBarButtonItem *item = self.navigationController.navigationBar.topItem.rightBarButtonItem;
    //UIButton *myBtn = (UIButton *)item.customView;
    //[myBtn setShowsTouchWhenHighlighted:YES];

    // add tap gesture handlers
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 2;
    tapGesture.delegate = self;
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
    
    UISwipeGestureRecognizer *recognizer;
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [[self view] addGestureRecognizer:recognizer];
    
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [[self view] addGestureRecognizer:recognizer];
    
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [[self view] addGestureRecognizer:recognizer];
    
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [[self view] addGestureRecognizer:recognizer];

    firstTime = TRUE;
    
    //load saved playlist, if any
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:@"myplaylist"];
    MPMediaItemCollection *mymediaItemCollection = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    //load saved Threshold slider Value
    myslider_threshold.value = [defaults floatForKey:@"myThreshold"];
    NSLog(@"Saved Threshold: %f",myslider_threshold.value);
    if (myslider_threshold.value == 0.0)
    {
        NSLog(@" Threshold Invalid");
        myslider_threshold.value = 0.3;
    }
     _visualizer.sliderThresholdValue = myslider_threshold.value;
    
    //load saved Scale slider Value
    myslider_scale.value = [defaults floatForKey:@"myScaler"];
    NSLog(@"Saved Scaler: %f",myslider_scale.value);
    if (myslider_scale.value == 0.0)
    {
        NSLog(@" Scaler Invalid");
        myslider_scale.value = 5;
    }
    _visualizer.sliderScaleValue = myslider_scale.value;
    
    int index = 0;
    for (MPMediaItem *item in mymediaItemCollection.items)
    {
        NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
    }
    NSLog(@"index: %d",index);
    if (index>0)
    {
        playlist = mymediaItemCollection;
        self.btnnext.hidden=NO;
        self.btnprevious.hidden=NO;
        [[self.btnnext superview] bringSubviewToFront:self.btnnext];
        [[self.btnprevious superview] bringSubviewToFront:self.btnprevious];
        
        [self.btnnext setShowsTouchWhenHighlighted:YES];
        [self.btnprevious setShowsTouchWhenHighlighted:YES];
        
        gcurrenSong = [defaults integerForKey:@"mySong"];
        NSLog(@"Saved Song: %d: ",gcurrenSong);
        if ( (gcurrenSong == -1 ) || (gcurrenSong > mymediaItemCollection.items.count) )
        {
            NSLog(@"Song Invalid");
            gcurrenSong = 0;
        }

        
        firstTime = FALSE;
        [self startPlaying];

    }
    
    //load saved volume
    gSavedVolume = [defaults floatForKey:@"myVolume"];
    NSLog(@"Saved Volume: %f: ",gSavedVolume);
    if (gSavedVolume==0.0)
    {
        NSLog(@" Saved Volume Invalid");
        gSavedVolume = 0.1;
    }
    //restore volume
    MPVolumeView* volumeView = [[MPVolumeView alloc] init];
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    [volumeViewSlider setValue:gSavedVolume animated:YES];
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];

    //restore colour lock if any
    self.btnLock.layer.cornerRadius = 10;
    self.btnLock.clipsToBounds = YES;
    self.btnLock.selected = [defaults boolForKey:@"HueLock"];
    NSLog(@"HueLock: %d: ",self.btnLock.selected);
    if (self.btnLock.selected)
    {
        self.colourSlider.userInteractionEnabled = NO;
        self.colourSlider.alpha = 0.5;
        [self.colourSlider setThumbImage: [UIImage imageNamed:@"lifxlockon_redsm"] forState:UIControlStateNormal];

        [self.btnLock setSelected:YES];
        [self.btnLock setImage: [UIImage imageNamed:@"lifxlockon_red"] forState:UIControlStateNormal] ;
        //gLockedHue = (self.currentTimeSlider.value * 360)/(self.currentTimeSlider.maximumValue);
        gLockedHue = [defaults floatForKey:@"myHue"];
        self.btnLock.backgroundColor = [UIColor colorWithHue:gLockedHue/360 saturation:1 brightness:1 alpha:1];
        self.colourSlider.value = gLockedHue/360;
        _visualizer.hue = gLockedHue;
        NSLog(@"Restored gLockedHue:%f",gLockedHue);
       
    }
    else
    {
        self.colourSlider.userInteractionEnabled = YES;
        self.colourSlider.alpha = 1;
        [self.colourSlider setThumbImage: [UIImage imageNamed:@"metalknob"] forState:UIControlStateNormal];

        [self.btnLock setSelected:NO];
        [self.btnLock setImage: [UIImage imageNamed:@"lifxlockoff"] forState:UIControlStateNormal] ;
        self.btnLock.backgroundColor = [UIColor clearColor];
        
    }

    
    NSLog(@"***Finished viewDidLoad:");
    
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    
    if ( /*([touch.view isKindOfClass:[UIButton class]]) ||
         ([touch.view isKindOfClass:[UIBarButtonItem class]]) ||
         ([touch.view isKindOfClass:[UIToolbar class]]) ||
        ([touch.view respondsToSelector:@selector(btnRepeatPressed:)])*/
        ([touch.view isKindOfClass:[UIControl class]]) )
    {
        NSLog(@"Ignoring gesture");
        return NO;
    }
    NSLog(@"Processing gesture");
    return YES;
}

- (void)handleTap:(UITapGestureRecognizer *)sender
{
     NSLog(@"handleTap (doubletap actually) ");
    
    if (!self.isPaused)
    {
        //playaudio
        NSLog(@"play");
        [self.imgBox setImage:[UIImage imageNamed:@"play2"]];
        self.imgBox.tag = 0;
        
    }
    else
    {
        //pause
        NSLog(@"pause");
        [self.imgBox setImage:[UIImage imageNamed:@"pause2"]];
         self.imgBox.tag = 1;
    }
    
        [self.playButton setHighlighted:YES]; [self.playButton sendActionsForControlEvents:UIControlEventTouchUpInside]; [self.playButton setHighlighted:NO];
    
    [self startFade];
    


    //self.imgBox.hidden = !self.imgBox.hidden;
    //self.imgBox.alpha=1;
}


- (void)handleSwipeUp:(UITapGestureRecognizer *)sender
{
     NSLog(@"handleSwipeUp ");
    //self.myaudioPlayer.audioPlayer.volume += 0.1;
    MPVolumeView* volumeView = [[MPVolumeView alloc] init];
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    
    [volumeViewSlider setValue:volumeViewSlider.value+0.2 animated:YES];
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    [self.imgBox setImage:[UIImage imageNamed:@"volumeUp"]];
    
    self.imgBox.tag = 0;
    [self startFade];

}

- (void)handleSwipeDown:(UITapGestureRecognizer *)sender
{
     NSLog(@"handleSwipeDown ");
    MPVolumeView* volumeView = [[MPVolumeView alloc] init];
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    
    [volumeViewSlider setValue:volumeViewSlider.value-0.2 animated:YES];
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    [self.imgBox setImage:[UIImage imageNamed:@"volumeDown"]];
    self.imgBox.tag = 0;
    [self startFade];
   
}

- (void)handleSwipeLeft:(UITapGestureRecognizer *)sender
{
    if (firstTime) return;
    
    [self.btnnext setHighlighted:YES]; [self.btnnext sendActionsForControlEvents:UIControlEventTouchUpInside]; [self.btnnext setHighlighted:NO];
  //[self btnnextPressed:nil];
    [self.imgBox setImage:[UIImage imageNamed:@"right2"]];
    self.imgBox.tag = 0;
    [self startFade];
    
}

- (void)handleSwipeRight:(UITapGestureRecognizer *)sender
{
    if (firstTime) return;
    
    [self.btnprevious setHighlighted:YES]; [self.btnprevious sendActionsForControlEvents:UIControlEventTouchUpInside]; [self.btnprevious setHighlighted:NO];
  //[self btnpreviousPressed:nil];
    [self.imgBox setImage:[UIImage imageNamed:@"left2"]];
    self.imgBox.tag = 0;
    [self startFade];

    
}



- (void)configureBars {
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    CGRect frame = self.view.frame;
    
    self.backgroundView = [[UIView alloc] initWithFrame:frame];
    [_backgroundView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    [_backgroundView setBackgroundColor:[UIColor blackColor]];
    
    [self.view addSubview:_backgroundView];
    

}

//update slider scale
-(IBAction)updateslider_scale:(id)sender
{
    UISlider * slider = (UISlider*)sender;
    NSLog(@"Scale Slider Value: %.2f", [slider value]);
    _visualizer.sliderScaleValue = [slider value];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:[slider value] forKey:@"myScaler"];
    [defaults synchronize];

}


//update slider threshold
-(IBAction)updateslider_threshold:(id)sender
{
    UISlider * slider = (UISlider*)sender;
    NSLog(@"Threshold Slider Value: %.2f", [slider value]);
    _visualizer.sliderThresholdValue = [slider value];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:[slider value] forKey:@"myThreshold"];
    [defaults synchronize];

}

#pragma mark - Music control

- (void)myplayURL:(NSURL *)url {
    NSLog(@"myplayURL() ");
    // Add audioPlayer configurations here
    [self setupAudioPlayer:url];
    
    [self.myaudioPlayer.audioPlayer setMeteringEnabled:YES];
    [_visualizer setAudioPlayer:self.myaudioPlayer.audioPlayer];
    
    if (![self.myaudioPlayer isPlaying])
    {
        self.isPaused = FALSE;
        //sending self start
        NSLog(@"sending self start ");
        [self playAudioPressed:self.view];
    }

    
}

#pragma mark - Media Picker

- (IBAction)btnSearchPressed:(UIButton *)sender
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    picker.prompt = @"Add songs to play";
    [picker setDelegate:self];
    [picker setAllowsPickingMultipleItems: YES];
    [picker setShowsCloudItems:NO];
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [self presentViewController:picker animated:YES completion:nil];
    });
    
    //[picker setAllowsPickingMultipleItems:YES];
    
    //[self presentModalViewController:picker animated: YES];
    
    
}





#pragma mark - UIAlertView Delegate

-(void)alertView:(UIAlertView*)alertview didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"clicked button at index %i", buttonIndex);
    if (buttonIndex == 0) //Add To Current Playlist
    {
        
        //this may not be necessary, but for some reason stepping through the arrays one at a time made this work, the MPMediaItem objects and collections aren't as flexible as their NS counterparts
        NSMutableArray*newPlaylist = [[NSMutableArray alloc]init];
        
        //add the old items one by one, then the new
        for (int i = 0; i < [playlist.items count]; i++)
        {
            [newPlaylist addObject:[playlist.items objectAtIndex:i]];
        }
        for (int j = 0; j < [limboPlaylist.items count]; j++)
        {
            [newPlaylist addObject:[limboPlaylist.items objectAtIndex:j]];
        }
        playlist = [MPMediaItemCollection collectionWithItems:newPlaylist];
        //[musicPlayer setQueueWithItemCollection:playlist];
    }
    else //overwrite existing playlist
    {
        playlist = limboPlaylist;
        //[musicPlayer setQueueWithItemCollection:playlist];
    }
}


#pragma mark - Media Picker Delegate

/*
 * This method is called when the user chooses something from the media picker screen. It dismisses the media picker screen
 * and plays the selected song.
 */
- (void)mediaPicker:(MPMediaPickerController *) mediaPicker didPickMediaItems:(MPMediaItemCollection *) collection {
    
    // remove the media picker screen
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    self.btnnext.hidden=NO;
    self.btnprevious.hidden=NO;
    [[self.btnnext superview] bringSubviewToFront:self.btnnext];
    [[self.btnprevious superview] bringSubviewToFront:self.btnprevious];
    
    [self.btnnext setShowsTouchWhenHighlighted:YES];
    [self.btnprevious setShowsTouchWhenHighlighted:YES];
    
    firstTime = FALSE;
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    limboPlaylist = collection;//this stores the new playlist until it is decided how if it will be added to or overwrite the current playlist
    
    //if there are both new and old playlists, ask what to do
    if ([playlist count] > 0 && [collection count] > 0)
    {
        //button events handled in the UIAlertView Delegate (below)
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"New Playlist Created" message:@"Add songs to current playlist or create new playlist?" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Add To Current", @"Create New", nil];
        //[alert show];
        //return;
        
        [alert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex)
        {
            NSLog(@"clicked button at index %i", buttonIndex);
            if (buttonIndex == 0) //Add To Current Playlist
            {
                
                //this may not be necessary, but for some reason stepping through the arrays one at a time made this work, the MPMediaItem objects and collections aren't as flexible as their NS counterparts
                NSMutableArray*newPlaylist = [[NSMutableArray alloc]init];
                
                //add the old items one by one, then the new
                for (int i = 0; i < [playlist.items count]; i++)
                {
                    [newPlaylist addObject:[playlist.items objectAtIndex:i]];
                }
                for (int j = 0; j < [limboPlaylist.items count]; j++)
                {
                    [newPlaylist addObject:[limboPlaylist.items objectAtIndex:j]];
                }
                playlist = [MPMediaItemCollection collectionWithItems:newPlaylist];
                //[musicPlayer setQueueWithItemCollection:playlist];
            }
            else //NEW PLAYLIST .overwrite existing playlist
            {
                playlist = limboPlaylist;gcurrenSong=-1;
                //[musicPlayer setQueueWithItemCollection:playlist];
            }
            NSLog(@"\n***INSIDE ALERT***");
            NSLog(@"***Saving Playlist ***");
            int index = 0;
            for (MPMediaItem *item in playlist.items)
            {
                NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
            }
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:playlist];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:data forKey:@"myplaylist"];
            [defaults synchronize];
            
            //MPMediaItem *item = [[playlist items] objectAtIndex:0];
            //NSURL *myurl = [item valueForProperty:MPMediaItemPropertyAssetURL];
            //NSLog(@"url:%@",myurl);
            //NSLog(@"self.isPaused:%d",self.isPaused);
            //NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
            //self.lblSongTitle.text = title;
            //if (self.myaudioPlayer.audioPlayer.isPlaying)
           // {
           //     [self.myaudioPlayer stopAudio];
           // }
            //[self myplayURL:myurl];
            

        }];
    }
    else
    {
        NSLog(@"\n***First Time ***");
        NSLog(@"***Saving Playlist ***");
        playlist = collection;

        int index = 0;
        for (MPMediaItem *item in playlist.items)
        {
            NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
        }
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:playlist];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:data forKey:@"myplaylist"];
        [defaults synchronize];
        
        [self startPlaying];
        /*
        MPMediaItem *item = [[playlist items] objectAtIndex:0];  gcurrenSong = 0;
        NSURL *myurl = [item valueForProperty:MPMediaItemPropertyAssetURL];
        NSLog(@"url:%@",myurl);
        NSLog(@"self.isPaused:%d",self.isPaused);
        NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
        self.lblSongTitle.text = title;
        if (self.myaudioPlayer.audioPlayer.isPlaying)
        {
            [self.myaudioPlayer stopAudio];
        }
        [self myplayURL:myurl];
        
         */
        
    }
    
    //[musicPlayer setQueueWithItemCollection:mediaItemCollection];
    //playlist = collection;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////

 // not working ??
/*
  int index = 0;
  for (MPMediaItem *item in playlist.items)
  {
  NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
  }
*/
 /*   
  //playlist = newPlaylist;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:playlist];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:data forKey:@"myplaylist"];
    [defaults synchronize];
    
*/

    
}

/*
 * This method is called when the user cancels out of the media picker. It just dismisses the media picker screen.
 */
- (void)mediaPickerDidCancel:(MPMediaPickerController *) mediaPicker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)configuremyAudioPlayer {
    if ([self.myaudioPlayer isPlaying]) { return;}
    self.myaudioPlayer = [[FSAudioPlayer alloc] init];
    //self.myaudioPlayer.audioPlayer.delegate = self;
    NSURL *audioFileLocationURL = [[NSBundle mainBundle] URLForResource:@"DemoSong" withExtension:@".m4a"];
    //NSURL *audioFileLocationURL = [[NSBundle mainBundle] URLForResource:@"dragon" withExtension:@".mp3"];
    [self setupAudioPlayer:audioFileLocationURL];
    
    [_myaudioPlayer.audioPlayer setNumberOfLoops:-1];
    [_myaudioPlayer.audioPlayer setMeteringEnabled:YES];
    [_visualizer setAudioPlayer:self.myaudioPlayer.audioPlayer];
}


- (void)configureAudioSession {
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
}




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Music Player

/*
 * Setup the AudioPlayer with
 * Filename and FileExtension like mp3
 * Loading audioFile and sets the time Labels
 */
//- (void)setupAudioPlayer:(NSString*)fileName
- (void)setupAudioPlayer:(NSURL*)fileURL

{
    NSError *error;
    //insert Filename & FileExtension
    NSLog(@"setupAudioPlayer()");
    
    //init the Player to get file properties to set the time labels
    //[self.audioPlayer initPlayer:fileName fileExtension:fileExtension];
    self.myaudioPlayer.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    self.currentTimeSlider.maximumValue = [self.myaudioPlayer getAudioDuration];
    //NSLog(@"self.currentTimeSlider.maximumValue:%f",self.currentTimeSlider.maximumValue);
    
    //init the current timedisplay and the labels. if a current time was stored
    //for this player then take it and update the time display
    self.timeElapsed.text = @"0:00";
    
    self.duration.text = [NSString stringWithFormat:@"-%@",
                          [self.myaudioPlayer timeFormat:[self.myaudioPlayer getAudioDuration]]];
    self.myaudioPlayer.audioPlayer.delegate=self;
}
/*
//volume slider on the right side
-(IBAction)updateslider:(id)sender
{
    UISlider * slider = (UISlider*)sender;
    NSLog(@"Slider Value: %.1f", [slider value]);
    self.myaudioPlayer.audioPlayer.volume=[slider value];
}
*/
/*
 * PlayButton is pressed
 * plays or pauses the audio and sets
 * the play/pause Text of the Button
 */
- (IBAction)playAudioPressed:(id)playButton
{
    NSLog(@"Entering %s()",__FUNCTION__);
   

    
    //NSLog(@"BEFORE:_isPlaying=%d",_isPlaying);
    [self.timer invalidate];
    //play audio for the first time or if pause was pressed
    if (!self.isPaused) {
         [self.imgBox.layer removeAllAnimations];
       
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"pause"]
                                   forState:UIControlStateNormal];
        
        //start a timer to update the time label display
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self
                                                    selector:@selector(updateTime:)
                                                    userInfo:nil
                                                     repeats:YES];
        
        [self.myaudioPlayer playAudio];
        self.isPaused = TRUE;
    } else {
        NSLog(@"in else of if (!self.isPaused)");
        //player is paused and Button is pressed again
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"play"]
                                   forState:UIControlStateNormal];
        
        [self.myaudioPlayer pauseAudio];
        self.isPaused = FALSE;
    }
     //_isPlaying = !_isPlaying;
     //NSLog(@"AFTER: _isPlaying=%d",_isPlaying);


}

/*
 * Updates the time label display and
 * the current value of the slider
 * while audio is playing
 */
- (void)updateTime:(NSTimer *)timer
{
    //to don't update every second. When scrubber is mouseDown the the slider will not set
    if (!self.scrubbing)
    {
        self.currentTimeSlider.value = [self.myaudioPlayer getCurrentAudioTime];
        
        if (!self.colourizing)
        {
            // lock the colour by sending the same hue to the visualizer
            if (self.btnLock.selected)
            {
                _visualizer.hue = gLockedHue;
            }
            else
            {
                // update slider to indicate present colour
                 //NSLog(@"updateTime() : _visualizer.hue:%f",_visualizer.hue);
                self.colourSlider.value = _visualizer.hue/360.0;
            }
        }
    }
    self.timeElapsed.text = [NSString stringWithFormat:@"%@",
                             [self.myaudioPlayer timeFormat:[self.myaudioPlayer getCurrentAudioTime]]];
    
    self.duration.text = [NSString stringWithFormat:@"-%@",
                          [self.myaudioPlayer timeFormat:[self.myaudioPlayer getAudioDuration] - [self.myaudioPlayer getCurrentAudioTime]]];
    
    //When resetted/ended reset the playButton
    if (![self.myaudioPlayer isPlaying])
    {
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"play"]
                                   forState:UIControlStateNormal];
        [self.myaudioPlayer pauseAudio];
        self.isPaused = FALSE;
        // auto replay ***FRAK***
        
       // NSLog(@"Sending self play");
       // [self playAudioPressed:self.view];
    }
    
}

/*
 * Sets the current value of the slider/scrubber
 * to the audio file when slider/scrubber is used
 */
- (IBAction)setCurrentTime:(id)scrubber
{
    //if scrubbing update the timestate, call updateTime faster not to wait a second and dont repeat it
    [NSTimer scheduledTimerWithTimeInterval:0.01
                                     target:self
                                   selector:@selector(updateTime:)
                                   userInfo:nil
                                    repeats:NO];
    
    [self.myaudioPlayer setCurrentAudioTime:self.currentTimeSlider.value];
    self.scrubbing = FALSE;
}

/*
 * Sets if the user is scrubbing right now
 * to avoid slider update while dragging the slider
 */
- (IBAction)userIsScrubbing:(id)sender
{
    self.scrubbing = TRUE;
    
}
- (IBAction)colourSelected:(UISlider *)sender
{
   // NSLog(@"colourSelected() self.colourSlider.value:%f",self.colourSlider.value);
    _visualizer.hue = self.colourSlider.value*360;
    //self.btnLock.backgroundColor = [UIColor colorWithHue:(_visualizer.hue/360.0) saturation:0.8 brightness:1 alpha:1];
    if (self.btnLock.selected)
    {
        self.colourSlider.value = gLockedHue/360;
    }
    NSLog(@"_visualizer.hue:%f",_visualizer.hue);
    self.colourizing = FALSE;


}

- (IBAction)colourSelecting:(UISlider *)sender
{
    self.colourizing = TRUE;
    _visualizer.hue = self.colourSlider.value*360;
    NSLog(@"colourSelecting()_visualizer.hue:%f",_visualizer.hue);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Audio Player

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    //
    NSLog(@"\n\n***FRAK*** detected end of song. gcurrentSong:%d",gcurrenSong);
    int index = 0;
    for (MPMediaItem *item in playlist.items)
    {
        NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
    }

    if (self.btnRepeat.selected)
    {
         NSLog(@"Repeating Song. gcurrentSong unchanged ");
    }
    else
    {
        gcurrenSong++;
    }
    
   // NSLog(@"next gcurrentSong:%d . playlist length:%lu",gcurrenSong, (unsigned long)[playlist count]);
    if (gcurrenSong > ([playlist count] - 1))
    {
        gcurrenSong =0 ;
        NSLog(@"gcurrentSong reset to %d ",gcurrenSong);
    }
    
    [self startPlaying];

}



#pragma mark - Segue Methods

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ViewControllerToTableViewControllerSegue"])
    {
        TableViewController* ModalTableViewController = segue.destinationViewController;
        ModalTableViewController.delegate = self;
        ModalTableViewController.playlist = playlist;
    }
}
#pragma mark - TableViewController Delegate Methods
-(void) ModalTableViewDidClickDone:(MPMediaItemCollection*)newPlaylist
{
    NSLog(@"***Saving Playlist ***");
    playlist = newPlaylist;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:playlist];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:data forKey:@"myplaylist"];
    [defaults synchronize];
    
    [self dismissModalViewControllerAnimated:YES];
}

-(void) ModalTableViewDidClickCancel
{
    [self dismissModalViewControllerAnimated:YES];
}

-(void) ModalTableViewDidSelectSong:(MPMediaItemCollection *)newPlaylist withSong:(int)index
{
    playlist = newPlaylist;
    NSLog(@"***Saving Playlist ***");
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:playlist];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:data forKey:@"myplaylist"];
    [defaults synchronize];
    
    NSLog(@"index:%d",index);
    gcurrenSong = (int)index;
    [self startPlaying];
    
    [self dismissModalViewControllerAnimated:YES];

}

// blinky UI box in the middle
- (void) startFade
{
    
    [self.imgBox.layer removeAllAnimations];
    
    [self.imgBox setAlpha:1.f];
    //NSLog(@"startFade1 alpha:%f",self.imgBox.alpha);
    
    [UIView animateWithDuration:0.5f
                          delay:0.5f
                        options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                     animations:^{
                         if (self.imgBox.tag) {}
                         else [UIView setAnimationRepeatCount:1.5];
                         //NSLog(@"in animation alpha:%f",self.imgBox.alpha);
                         [self.imgBox setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         if (finished) {NSLog(@"done");}
                         //[self.imgBox setAlpha:0.f];
                     }];
    
    //[self.imgBox setAlpha:0.f];
    
    //NSLog(@"startFade2 alpha:%f",self.imgBox.alpha);
}


- (IBAction)btnRepeatPressed:(UIButton *)sender
{
    NSLog(@"btnRepeatPressed. self.btnRepeat.selected:%d ",self.btnRepeat.selected);
    self.btnRepeat.selected = !self.btnRepeat.selected;
    if (self.btnRepeat.selected)
    {
        [self.btnRepeat setSelected:YES];
        [self.btnRepeat setImage: [UIImage imageNamed:@"repeat_on"] forState:UIControlStateNormal] ;
    }
    else
    {
        [self.btnRepeat setSelected:NO];
        [self.btnRepeat setImage: [UIImage imageNamed:@"repeat"] forState:UIControlStateNormal] ;
    }
 
    //[self.btnRepeat setImage:[UIImage imageNamed:@"repeat_on"] forState:UIControlStateNormal];
     //NSLog(@"buttonstate:",self.btnRepeat.);
}


- (IBAction)btnMixerPressed:(UIButton *)sender
{
    [UIView transitionWithView:myslider_threshold duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
    [UIView transitionWithView:myslider_scale duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
    [UIView transitionWithView:self.powerLevel duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
    [UIView transitionWithView:lblOffset duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
    [UIView transitionWithView:lblExpo duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
    [UIView transitionWithView:self.viewVolumeView duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
    [UIView transitionWithView:self.colourSlider duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];

    
    myslider_threshold.hidden = !myslider_threshold.hidden;
    myslider_scale.hidden = !myslider_scale.hidden;
    self.powerLevel.hidden = !self.powerLevel.hidden;
    lblOffset.hidden = !lblOffset.hidden;
    lblExpo.hidden = !lblExpo.hidden;
    self.viewVolumeView.hidden = !self.viewVolumeView.hidden;
    self.colourSlider.hidden = !self.colourSlider.hidden;
    
    
    NSLog(@"btnMixerPressed. btnMixer.selected:%d ",self.btnMixer.selected);
    self.btnMixer.selected = !self.btnMixer.selected;
    if (self.btnMixer.selected)
    {
        [self.btnMixer setSelected:YES];
        [self.btnMixer setImage: [UIImage imageNamed:@"mixer_on"] forState:UIControlStateNormal] ;
    }
    else
    {
        [self.btnMixer setSelected:NO];
        [self.btnMixer setImage: [UIImage imageNamed:@"mixer"] forState:UIControlStateNormal] ;
    }

}


- (IBAction)btnnextPressed:(UIButton *)sender
{
    NSLog(@"\n\nbtnnextPressed. gcurrentSong:%d",gcurrenSong);
    [self.imgBox.layer removeAllAnimations];
    int index = 0;
    for (MPMediaItem *item in playlist.items)
    {
        NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
    }
    
    
    gcurrenSong++;
    NSLog(@" next gcurrentSong:%d . playlist length:%d",gcurrenSong, [playlist count]);
    if (gcurrenSong > ([playlist count] - 1))
    {
        gcurrenSong = 0 ;
        NSLog(@"gcurrentSong reset to %d",gcurrenSong);
        
    }
    
    [self startPlaying];
    
    
}

- (IBAction)btnpreviousPressed:(UIButton *)sender
{
    
    NSLog(@"\n\nbtnpreviousPressed. gcurrentSong:%d",gcurrenSong);
    [self.imgBox.layer removeAllAnimations];
    
    int index = 0;
    for (MPMediaItem *item in playlist.items)
    {
        NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
    }
    
    
    
    gcurrenSong--;
    //NSLog(@" next gcurrentSong:%d . playlist length:%lu",gcurrenSong, (unsigned long)[playlist count]);
    if (gcurrenSong < 0)
    {
        gcurrenSong = 0 ;
        NSLog(@"gcurrentSong reset to %d",gcurrenSong);
        
    }
    
    [self startPlaying];
    
    
}
- (IBAction)btnHelpPressed:(UIButton *)sender
{


    self.btnHelp2.selected = !self.btnHelp2.selected;
    if (self.btnHelp2.selected)
    {
        //JDFTooltipView *tooltip = [self.tooltipManager.tooltips lastObject];
        //[tooltip show];
        [self.tooltipManager1 showAllTooltips];[self.tooltipManager showAllTooltips];
        [self.btnHelp2 setSelected:YES];
        [self.btnHelp2 setImage: [UIImage imageNamed:@"help_on"] forState:UIControlStateNormal] ;
    }
    else
    {
        //JDFTooltipView *tooltip = [self.tooltipManager.tooltips lastObject];
        //[tooltip hideAnimated:TRUE];
        [self.tooltipManager1 hideAllTooltipsAnimated:TRUE];[self.tooltipManager hideAllTooltipsAnimated:TRUE];
        [self.btnHelp2 setSelected:NO];
        [self.btnHelp2 setImage: [UIImage imageNamed:@"help"] forState:UIControlStateNormal] ;
        //self.navigationItem.leftBarButtonItem = nil;
        [sender removeFromSuperview];
        sender = nil;
    }

    
}

- (IBAction)btnLockPressed:(UIButton *)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.btnLock.selected = !self.btnLock.selected;
  
    if (self.btnLock.selected)
    {
        self.colourSlider.userInteractionEnabled = NO;
        self.colourSlider.alpha = 0.5;
        [self.colourSlider setThumbImage: [UIImage imageNamed:@"lifxlockon_redsm"] forState:UIControlStateNormal];
        [self.btnLock setSelected:YES]; 
        [self.btnLock setImage: [UIImage imageNamed:@"lifxlockon_red"] forState:UIControlStateNormal] ;
        //gLockedHue = (self.currentTimeSlider.value * 360)/(self.currentTimeSlider.maximumValue);
        gLockedHue = self.colourSlider.value*360;
        self.btnLock.backgroundColor = [UIColor colorWithHue:self.colourSlider.value saturation:1 brightness:1 alpha:1];
        NSLog(@"gLockedHue:%f",gLockedHue);
        [defaults setBool:YES forKey:@"HueLock"];
        [defaults setFloat:gLockedHue forKey:@"myHue"];
        [defaults synchronize];
    }
    else
    {
        self.colourSlider.userInteractionEnabled = YES;
        self.colourSlider.alpha = 1;
        [self.colourSlider setThumbImage: [UIImage imageNamed:@"metalknob"] forState:UIControlStateNormal];
        [self.btnLock setSelected:NO];
        [self.btnLock setImage: [UIImage imageNamed:@"lifxlockoff"] forState:UIControlStateNormal] ;
        self.btnLock.backgroundColor =[UIColor clearColor];
        [defaults setBool:NO forKey:@"HueLock"];
        [defaults synchronize];
    }
}

- (BOOL) shouldAutorotate
{
    return NO;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
