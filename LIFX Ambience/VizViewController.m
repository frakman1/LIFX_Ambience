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


@interface VizViewController () </*UITableViewDataSource, UITableViewDelegate,*/ AVAudioPlayerDelegate,UIAlertViewDelegate>

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

@end

@implementation VizViewController
{
    //BOOL _isBarHide;
    //BOOL _isPlaying;
    int gcurrenSong;
}
@synthesize playlist,limboPlaylist;



- (void) startPlaying
{
    MPMediaItem *item = [[playlist items] objectAtIndex:gcurrenSong];
    NSURL *myurl = [item valueForProperty:MPMediaItemPropertyAssetURL];
    NSLog(@"url:%@",myurl);
    NSLog(@"self.isPaused:%d",self.isPaused);
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    self.lblSongTitle.text = title;
    NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];
    self.lblSongArtist.text = artist;

    
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

#if 0
NSTimer *timer;
-(void)myTick:(NSTimer *)timer
{
    //NSLog(@"myTick..");
    //take screenshot
    
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
    
    
}

#endif

//This function gets called AFTER autolayout/contraint has finished and BEFORE viewWillAppear
- (void)viewDidLayoutSubviews
{
    
    [super viewDidLayoutSubviews];
    CGRect frame = self.view.frame;

    self.audioPlayerBackgroundLayer.frame = CGRectMake(self.audioPlayerBackgroundLayer.frame.origin.x, self.audioPlayerBackgroundLayer.frame.origin.y,
                                                       frame.size.width ,self.audioPlayerBackgroundLayer.frame.size.height);
    self.lblSongTitle.frame = CGRectMake(self.lblSongTitle.frame.origin.x, self.lblSongTitle.frame.origin.y, frame.size.width ,self.lblSongTitle.frame.size.height);
    self.lblSongArtist.frame = CGRectMake(self.lblSongArtist.frame.origin.x, self.lblSongArtist.frame.origin.y, frame.size.width ,self.lblSongArtist.frame.size.height);
    
    
    self.currentTimeSlider.center = self.audioPlayerBackgroundLayer.center;
    CGPoint mypoint;
    mypoint.x = (self.audioPlayerBackgroundLayer.frame.origin.x + self.audioPlayerBackgroundLayer.frame.size.width)-50;
    mypoint.y = self.audioPlayerBackgroundLayer.center.y;
    self.duration.center = mypoint;
    
    mypoint.x = (self.lblSongTitle.frame.origin.x + self.lblSongTitle.frame.size.width)-30;
    mypoint.y = self.lblSongTitle.center.y;
    self.btnnext.center = mypoint;
    
    //self.currentTimeSlider.frame = CGRectMake(self.timeElapsed.frame.origin.x+self.timeElapsed.frame.size.width+10,self.timeElapsed.frame.origin.y,frame.size.width - (self.timeElapsed.frame.origin.x)*2,self.currentTimeSlider.frame.size.height);
   
    [[self.btnnext superview] bringSubviewToFront:self.btnnext];
    [[self.btnprevious superview] bringSubviewToFront:self.btnprevious];

    
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
    [[self.playButton superview] bringSubviewToFront:self.playButton];
    [[self.currentTimeSlider superview] bringSubviewToFront:self.currentTimeSlider];
    [[self.duration superview] bringSubviewToFront:self.duration];
    [[self.timeElapsed superview] bringSubviewToFront:self.timeElapsed];
    [[self.lblSongTitle superview] bringSubviewToFront:self.lblSongTitle];
    [[self.lblSongArtist superview] bringSubviewToFront:self.lblSongArtist];

    
    [self configuremyAudioPlayer];
    
    // Setup Main soundtrack player
    
    //NSString *filename = [self.gameSelection stringByAppendingString:@".mp3"];
    //NSLog(@"crafed filename: %@",filename);
    [self.currentTimeSlider setThumbImage: [UIImage imageNamed:@"knob2.png"] forState:UIControlStateNormal];

}

- (void)viewDidAppear:(BOOL)animated {
    NSLog (@"***viewDidAppear***");
    [super viewDidAppear:animated];
    //[self toggleBars];
    //[self.visualizer vizStart];
    //spawn average colour effect thread
    //timer = [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector:@selector(myTick:) userInfo: nil repeats:YES];
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
    
    // NavBar
    //self.navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, -30, frame.size.width, 30)];
    //[_navBar setBarStyle:UIBarStyleBlackTranslucent];
    //[_navBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    //UINavigationItem *navTitleItem = [[UINavigationItem alloc] initWithTitle:@"Music Visualizer"];
    //[_navBar pushNavigationItem:navTitleItem animated:NO];
    
    //[self.view addSubview:_navBar];
    
    // ToolBar
    //self.toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, frame.size.height-30, frame.size.width, 30)];
    //[_toolBar setBarStyle:UIBarStyleBlackTranslucent];
    //[_toolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    //UIBarButtonItem *pickBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(pickSong)];
    
//    self.playBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playPause)];
    
//    self.pauseBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(playPause)];
    
   // UIBarButtonItem *leftFlexBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    //UIBarButtonItem *rightFlexBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    //self.playItems = [NSArray arrayWithObjects:pickBBI, leftFlexBBI,  rightFlexBBI, nil];
    //self.pauseItems = [NSArray arrayWithObjects:pickBBI, leftFlexBBI, rightFlexBBI, nil];
    
    //[_toolBar setItems:_playItems];
    
    //[self.view addSubview:_toolBar];
    
    //_isBarHide = YES;
    //_isPlaying = NO;
    
//    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHandler:)];
  //  [_backgroundView addGestureRecognizer:tapGR];
}
#if 0
- (void)toggleBars {
    //CGFloat navBarDis = -30;
    CGFloat toolBarDis = 44;
    if (_isBarHide ) {
        //navBarDis = -navBarDis;
        toolBarDis = -toolBarDis;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        //CGPoint navBarCenter = _navBar.center;
        //navBarCenter.y += navBarDis;
        //[_navBar setCenter:navBarCenter];
        
        CGPoint toolBarCenter = _toolBar.center;
        toolBarCenter.y += toolBarDis;
        [_toolBar setCenter:toolBarCenter];
    }];
    
    _isBarHide = !_isBarHide;
}

- (void)tapGestureHandler:(UITapGestureRecognizer *)tapGR {
    [self toggleBars];
}
#endif


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
- (IBAction)barbtnSearchPressed:(UIBarButtonItem *)sender
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
            int index = 0;
            for (MPMediaItem *item in playlist.items)
            {
                NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
            }
            
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
        playlist = collection;

        int index = 0;
        for (MPMediaItem *item in playlist.items)
        {
            NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
        }
        
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



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSLog(@"segueing...");
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
       
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"audioplayer_pause.png"]
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
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"audioplayer_play.png"]
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
    }
    self.timeElapsed.text = [NSString stringWithFormat:@"%@",
                             [self.myaudioPlayer timeFormat:[self.myaudioPlayer getCurrentAudioTime]]];
    
    self.duration.text = [NSString stringWithFormat:@"-%@",
                          [self.myaudioPlayer timeFormat:[self.myaudioPlayer getAudioDuration] - [self.myaudioPlayer getCurrentAudioTime]]];
    
    //When resetted/ended reset the playButton
    if (![self.myaudioPlayer isPlaying])
    {
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"audioplayer_play.png"]
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

    
    gcurrenSong++;
    NSLog(@"next gcurrentSong:%d . playlist length:%d",gcurrenSong, [playlist count]);
    if (gcurrenSong > ([playlist count] - 1))
    {
        gcurrenSong =0 ;
        NSLog(@"gcurrentSong reset to %d ",gcurrenSong);
    }
    
    [self startPlaying];

}


@end
