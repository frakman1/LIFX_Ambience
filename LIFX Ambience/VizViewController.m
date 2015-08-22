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

@interface VizViewController () </*UITableViewDataSource, UITableViewDelegate,*/ AVAudioPlayerDelegate,UIAlertViewDelegate,UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UIToolbar *toolBar;
@property (strong, nonatomic) NSArray *playItems;
@property (strong, nonatomic) NSArray *pauseItems;
@property (strong, nonatomic) UIBarButtonItem *playBBI;
@property (strong, nonatomic) UIBarButtonItem *pauseBBI;

@property (nonatomic, retain) MPMediaItemCollection*    playlist;
@property (nonatomic, retain) MPMediaItemCollection*    limboPlaylist;


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
    int gcurrenSong;
    UISlider *myslider_threshold;
    UISlider *myslider_scale;
    UIImageView *imgExpo;
    UIImageView *imgOffset;
    UILabel *lblOffset;
    UILabel *lblExpo;
    BOOL firstTime;
}
@synthesize playlist,limboPlaylist,toolbar,powerLevel;

BOOL gRepeatEnabled = false;

- (void) myTick:(NSTimer *)timer
{
    //NSLog(@"myTick");
    self.powerLevel.value = self.visualizer.LevelValue;
}

- (void) startPlaying
{
    NSLog(@"startPlaying() gcurrentSong:%d",gcurrenSong);
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

- (IBAction)btnpreviousPressed:(UIButton *)sender
{
    
    NSLog(@"\n\nbtnpreviousPressed. gcurrentSong:%d",gcurrenSong);
    
    int index = 0;
    for (MPMediaItem *item in playlist.items)
    {
        NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
    }

    
    
    gcurrenSong--;
    NSLog(@" next gcurrentSong:%d . playlist length:%d",gcurrenSong, [playlist count]);
    if (gcurrenSong < 0)
    {
        gcurrenSong = 0 ;
        NSLog(@"gcurrentSong reset to %d",gcurrenSong);
        
    }
    
    [self startPlaying];
   
    
}

- (IBAction)barbtnMixerPressed:(UIBarButtonItem *)sender
{
    myslider_threshold.hidden = !myslider_threshold.hidden;
    myslider_scale.hidden = !myslider_scale.hidden;
    self.powerLevel.hidden = !self.powerLevel.hidden;
    imgExpo.hidden = !imgExpo.hidden;
    //imgOffset.hidden = !imgOffset.hidden;
    lblOffset.hidden = !lblOffset.hidden;
    lblExpo.hidden = !lblExpo.hidden;
}
- (IBAction)btnMixerPressed:(UIButton *)sender
{
    myslider_threshold.hidden = !myslider_threshold.hidden;
    myslider_scale.hidden = !myslider_scale.hidden;
    self.powerLevel.hidden = !self.powerLevel.hidden;
    //imgExpo.hidden = !imgExpo.hidden;
    //imgOffset.hidden = !imgOffset.hidden;
    lblOffset.hidden = !lblOffset.hidden;
    lblExpo.hidden = !lblExpo.hidden;
}


- (IBAction)btnnextPressed:(UIButton *)sender
{
    NSLog(@"\n\nbtnnextPressed. gcurrentSong:%d",gcurrenSong);
    
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

- (BOOL) prefersStatusBarHidden {return YES;}



//This function gets called AFTER autolayout/contraint has finished and BEFORE viewWillAppear
- (void)viewDidLayoutSubviews
{
    
    [super viewDidLayoutSubviews];

    
}

- (void) viewWillAppear:(BOOL)animated
{
    CGRect frame = self.view.frame;
   
    //NSLog (@"1");
    self.audioPlayerBackgroundLayer.frame = CGRectMake(self.audioPlayerBackgroundLayer.frame.origin.x, self.audioPlayerBackgroundLayer.frame.origin.y, frame.size.width, self.audioPlayerBackgroundLayer.frame.size.height);
    //NSLog (@"2. %@", NSStringfromCGRect(self.audioPlayerBackgroundLayer.frame));
    //NSLog (@"2.audioPlayerBackgroundLayer x:%f y:%f width:%f height:%f",self.audioPlayerBackgroundLayer.frame.origin.x,self.audioPlayerBackgroundLayer.frame.origin.y,self.audioPlayerBackgroundLayer.frame.size.width,self.audioPlayerBackgroundLayer.frame.size.height);
    
    //self.lbltitleBackground.frame = CGRectMake(self.lbltitleBackground.frame.origin.x, self.lbltitleBackground.frame.origin.y, frame.size.width ,self.lbltitleBackground.frame.size.height);
    //NSLog (@"3. %@",NSStringfromCGRect(self.lbltitleBackground.frame));
   // NSLog (@"3.lbltitleBackground x:%f y:%f width:%f height:%f",self.lbltitleBackground.frame.origin.x,self.lbltitleBackground.frame.origin.y,self.lbltitleBackground.frame.size.width,self.lbltitleBackground.frame.size.height);
    
    self.mlblSongTitle.frame = CGRectMake(self.btnprevious.frame.size.width,  self.mlblSongTitle.frame.origin.y, frame.size.width - self.btnnext.frame.size.width - self.btnprevious.frame.size.width ,self.mlblSongTitle.frame.size.height);
   // NSLog (@"4.mlblSongTitle x:%f y:%f width:%f height:%f",self.mlblSongTitle.frame.origin.x,self.mlblSongTitle.frame.origin.y,self.mlblSongTitle.frame.size.width,self.mlblSongTitle.frame.size.height);
    //NSLog (@"4. %@",NSStringfromCGRect(self.mlblSongTitle.frame));
    
    
    self.mlblSongArtist.frame = CGRectMake(self.mlblSongArtist.frame.origin.x, self.mlblSongArtist.frame.origin.y, frame.size.width ,self.mlblSongArtist.frame.size.height);
    //NSLog (@"5.lblSongArtist x:%f y:%f width:%f height:%f",self.lblSongArtist.frame.origin.x,self.lblSongArtist.frame.origin.y,self.lblSongArtist.frame.size.width,self.lblSongArtist.frame.size.height);
    
    //self.currentTimeSlider.center = self.audioPlayerBackgroundLayer.center;
   // CGPoint mypoint;
  //  mypoint.x = (self.currentTimeSlider.frame.origin.x + self.currentTimeSlider.frame.size.width)+50 ;
   // mypoint.y = self.currentTimeSlider.center.y;
   // self.duration.frame = CGRectMake(CGRectGetMaxX(self.currentTimeSlider.frame)+150 ,self.currentTimeSlider.center.y,self.duration.frame.size.width,self.duration.frame.size.height);
    //self.duration.center = mypoint;
   // NSLog (@"6.currentTimeSlider x:%f y:%f width:%f height:%f",self.currentTimeSlider.frame.origin.x,self.currentTimeSlider.frame.origin.y,self.currentTimeSlider.frame.size.width,self.currentTimeSlider.frame.size.height);

   // NSLog (@"7.duration x:%f y:%f width:%f height:%f",self.duration.frame.origin.x,self.duration.frame.origin.y,self.duration.frame.size.width,self.duration.frame.size.height);
   // NSLog(@"8. MAX X of slider:%f",CGRectGetMaxX(self.currentTimeSlider.frame));
    
    //self.playButton.frame = CGRectMake(self.playButton.frame.origin.x-10,self.playButton.frame.origin.y,self.playButton.frame.size.width,self.playButton.frame.size.height);
    //self.timeElapsed.frame = CGRectMake(self.timeElapsed.frame.origin.x+10,self.timeElapsed.frame.origin.y,self.timeElapsed.frame.size.width,self.timeElapsed.frame.size.height);
    
    //mypoint.x = (self.mlblSongTitle.frame.origin.x + self.mlblSongTitle.frame.size.width)-30;
    //mypoint.y = self.mlblSongTitle.center.y;
    //self.btnnext.center = mypoint;
    
    //self.currentTimeSlider.frame = CGRectMake(self.timeElapsed.frame.origin.x+self.timeElapsed.frame.size.width+10,self.timeElapsed.frame.origin.y,frame.size.width - (self.timeElapsed.frame.origin.x)*2,self.currentTimeSlider.frame.size.height);
    
    
    //self.lblSongTitle.adjustsFontSizeToFitWidth = YES;
    

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
        
        
        LFXHSBKColor* tmpColor = [LFXHSBKColor whiteColorWithBrightness:1  kelvin:3500];
        LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
        [localNetworkContext.allLightsCollection setColor:tmpColor];
   
    }
}


-(void) viewWillDisappear:(BOOL)animated
{
    NSLog (@"***viewWillDisappear***");

    [self resignFirstResponder];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog (@"****viewDidLoad****");
    
    
    [self configureBars];
    
    [self configureAudioSession];
    
   // self.visualizer = [[VisualizerView alloc] initWithFrame:self.view.frame];
    self.visualizer = [[VisualizerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    NSLog (@"***width:%f  height:%f ***",self.view.frame.size.width,self.view.frame.size.height);
    [_visualizer setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [_backgroundView addSubview:_visualizer];
    //[_backgroundView sendSubviewToBack:_visualizer];
    //[self.view sendSubviewToBack:_visualizer];
    [[self.audioPlayerBackgroundLayer superview] bringSubviewToFront:self.audioPlayerBackgroundLayer];
    [[self.currentTimeSlider superview] bringSubviewToFront:self.currentTimeSlider];
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
    //[self.imgBox setImage:[UIImage imageNamed:@"play2"]];
   // UIImage *repeatOn = [UIImage imageNamed:@"repeat_on"];
    //UIImage *repeat   = [UIImage imageNamed:@"repeat"];
    //[self.btnRepeat setImage:repeatOn   forState:UIControlStateSelected];
    //[self.btnRepeat setImage:repeat     forState:UIControlStateNormal];
    
    
    [self configuremyAudioPlayer];
    
    // Setup Main soundtrack player
    
    //NSString *filename = [self.gameSelection stringByAppendingString:@".mp3"];
    //NSLog(@"crafed filename: %@",filename);
    //[self.currentTimeSlider setThumbImage: [UIImage imageNamed:@"knob2.png"] forState:UIControlStateNormal];
    
    
    // Setup MArquee as Continuous Type
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
    myslider_threshold = [[ANPopoverSlider alloc] initWithFrame:CGRectMake(self.view.frame.origin.x-20, 270, 160, 30)];
    myslider_threshold.value=0.2; _visualizer.sliderThresholdValue = myslider_threshold.value;
    myslider_threshold.transform = CGAffineTransformRotate(myslider_threshold.transform, -0.5*M_PI);
    [self.view addSubview:myslider_threshold];
    [myslider_threshold addTarget:self action:@selector(updateslider_threshold:) forControlEvents:UIControlEventValueChanged];
    myslider_threshold.hidden = TRUE;
    
    imgOffset = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"offset"]];
    //imgOffset.frame=CGRectMake(myslider_threshold.center.x-50, myslider_threshold.frame.origin.y+myslider_threshold.frame.size.height+10, 101,62);
    //imgOffset.frame=CGRectMake(100,100 ,35,29);
    
    lblOffset = [[UILabel alloc] init];
    lblOffset.textColor = [UIColor whiteColor];
    lblOffset.font=[lblOffset.font fontWithSize:15];
    lblOffset.numberOfLines = 0;
    [lblOffset sizeToFit];
    lblOffset.textAlignment = NSTextAlignmentCenter;
    //lblOffset.lineBreakMode= NSLineBreakByWordWrapping ;
    lblOffset.text = @"Brightness \n Threshold";
    lblOffset.frame = CGRectMake(myslider_threshold.center.x-50,
                             myslider_threshold.frame.origin.y+myslider_threshold.frame.size.height-50,
                             90,
                             180);
    
    
    imgOffset.hidden = TRUE;
    lblOffset.hidden = TRUE;
    //[self.view addSubview:imgOffset];
    [self.view addSubview:lblOffset];
    

    
    
    //create vertical slider - Scaler
    myslider_scale = [[ANPopoverSlider alloc] initWithFrame:CGRectMake(self.view.frame.size.width-130, 270, 160, 30)];
    myslider_scale.maximumValue = 10;
    myslider_scale.minimumValue = 1;
    myslider_scale.value=1;  _visualizer.sliderScaleValue =  myslider_scale.value;
    myslider_scale.transform = CGAffineTransformRotate(myslider_scale.transform, -0.5*M_PI);
    [self.view addSubview:myslider_scale];
    [myslider_scale addTarget:self action:@selector(updateslider_scale:) forControlEvents:UIControlEventValueChanged];
    myslider_scale.hidden = TRUE;
    
    NSLog (@"myslider_scale x:%f y:%f width:%f height:%f",myslider_scale.frame.origin.x,myslider_scale.frame.origin.y,myslider_scale.frame.size.width,myslider_scale.frame.size.height);
    
    imgExpo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"expo"]];
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
    
    //load saved slider Values
    myslider_threshold.value = [defaults floatForKey:@"myThreshold"];
    NSLog(@"Saved Threshold: %f",myslider_threshold.value);
    if (myslider_threshold.value == 0.0)
    {
        NSLog(@" Threshold Invalid");
        myslider_threshold.value = 0.2;
    }
    
    //load saved slider Values
    myslider_scale.value = [defaults floatForKey:@"myScaler"];
    NSLog(@"Saved Scaler: %f",myslider_scale.value);
    if (myslider_scale.value == 0.0)
    {
        NSLog(@" Scaler Invalid");
        myslider_scale.value = 3;
    }

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
     NSLog(@"handleTap ");
    
    if (!self.isPaused)
    {
        //playaudio
        [self.imgBox setImage:[UIImage imageNamed:@"play2"]];
        
    }
    else
    {
        //pause
        [self.imgBox setImage:[UIImage imageNamed:@"pause2"]];
        
    }
    
    [self startFade];
    
    [self.playButton setHighlighted:YES]; [self.playButton sendActionsForControlEvents:UIControlEventTouchUpInside]; [self.playButton setHighlighted:NO];

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
    
    [self startFade];
   
}

- (void)handleSwipeLeft:(UITapGestureRecognizer *)sender
{
    if (firstTime) return;
    
    [self.btnnext setHighlighted:YES]; [self.btnnext sendActionsForControlEvents:UIControlEventTouchUpInside]; [self.btnnext setHighlighted:NO];
  //[self btnnextPressed:nil];
    [self.imgBox setImage:[UIImage imageNamed:@"right2"]];
    
    [self startFade];
    
}

- (void)handleSwipeRight:(UITapGestureRecognizer *)sender
{
    if (firstTime) return;
    
    [self.btnprevious setHighlighted:YES]; [self.btnprevious sendActionsForControlEvents:UIControlEventTouchUpInside]; [self.btnprevious setHighlighted:NO];
  //[self btnpreviousPressed:nil];
    [self.imgBox setImage:[UIImage imageNamed:@"left2"]];
    
    [self startFade];

    
}

/*
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        // handling code
        NSLog(@"double tap detected");
        //[self pause:self];
        if ([self isPlaying])
        {
            [self pause:self];
        }
        else
        {
            [self play:self];
        }
        
    }
}
*/

- (void)viewDidAppear:(BOOL)animated {
    NSLog (@"***viewDidAppear***");
    [super viewDidAppear:animated];
    //[self toggleBars];
    //[self.visualizer vizStart];
    //spawn average colour effect thread
    self.tickerTimer = [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector:@selector(myTick:) userInfo: nil repeats:YES];
    //NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
    //[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
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
    [picker setShowsCloudItems:YES];
    [self presentViewController:picker animated:YES completion:nil];
    
    //[picker setAllowsPickingMultipleItems:YES];
    
    //[self presentModalViewController:picker animated: YES];
    
    
}

- (IBAction)barbtnSearchPressed:(UIButton *)sender
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    picker.prompt = @"Add songs to play";
    [picker setDelegate:self];
    [picker setAllowsPickingMultipleItems: YES];
    [picker setShowsCloudItems:YES];
    [self presentViewController:picker animated:YES completion:nil];
    
    //[picker setAllowsPickingMultipleItems:YES];
    
    //[self presentModalViewController:picker animated: YES];

}

/*
 * This method is called when the user presses the magnifier button (because this selector was used
 * to create the button in configureBars, defined earlier in this file). It displays a media picker
 * screen to the user configured to show only audio files.
 
- (void)pickSong {
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    [picker setDelegate:self];
    [picker setAllowsPickingMultipleItems: NO];
    [self presentViewController:picker animated:YES completion:NULL];
}
*/

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

    // grab the first selection (media picker is capable of returning more than one selected item,
    // but this app only deals with one song at a time)
    //MPMediaItem *item = [[collection items] objectAtIndex:0];
    //NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    //[_navBar.topItem setTitle:title];
    
    // get a URL reference to the selected item
    //NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
    
    // pass the URL to playURL:, defined earlier in this file
    //[self playURL:url];
    
    
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
    //NSURL *audioFileLocationURL = [[NSBundle mainBundle] URLForResource:@"DemoSong" withExtension:@".m4a"];
    NSURL *audioFileLocationURL = [[NSBundle mainBundle] URLForResource:@"dragon" withExtension:@".mp3"];
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
- (void) startFade
{
    [self.imgBox setAlpha:0.f];
    //NSLog(@"startFade1 alpha:%f",self.imgBox.alpha);
    
    [UIView animateWithDuration:0.5f
                          delay:0.f
                        options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAutoreverse
                     animations:^{
                         //NSLog(@"in animation alpha:%f",self.imgBox.alpha);
                         [self.imgBox setAlpha:1.f];
                     }
                     completion:^(BOOL finished) {[self.imgBox setAlpha:0.f];}];

    //[self.imgBox setAlpha:0.f];

    //NSLog(@"startFade2 alpha:%f",self.imgBox.alpha);
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
         NSLog(@"Repeating Song. gcurrentSong unchanged ",gcurrenSong);
    }
    else
    {
        gcurrenSong++;
    }
    
    NSLog(@"next gcurrentSong:%d . playlist length:%d",gcurrenSong, [playlist count]);
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


@end
