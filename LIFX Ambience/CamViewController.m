//
//  CamViewController.m
//  LIFX Ambience
//
//  Created by alnaumf on 6/18/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import "CamViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "AVCamPreviewView.h"
#import <LIFXKit/LIFXKit.h>
#import "UIImageAverageColorAddition.h"
#import <MediaPlayer/MediaPlayer.h>


#import "SCAudioMeter.h"
#import <QuartzCore/QuartzCore.h>
#import "JDFTooltips.h"




static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * RecordingContext = &RecordingContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;


@interface CamViewController () <AVCaptureFileOutputRecordingDelegate>


// For use in the storyboards.
@property (nonatomic, weak) IBOutlet AVCamPreviewView *previewView;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, weak) IBOutlet UIButton *cameraButton;
@property (nonatomic, weak) IBOutlet UIButton *stillButton;
@property (nonatomic,weak) IBOutlet UILabel* myLabel;
@property (nonatomic, strong) JDFTooltipManager *tooltipManager;

@property (nonatomic, strong) UISlider *volumeSlider;

- (IBAction)toggleMovieRecording:(id)sender;
- (IBAction)changeCamera:(id)sender;
- (IBAction)snapStillImage:(id)sender;
- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;



// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;


@property (nonatomic, strong) SCAudioMeter *audioMeter;

@end

@implementation CamViewController



AVAudioRecorder* recorder;
NSTimer *camTimer;
//UIImage *gImage;
UIColor *gcamColor ;
UIColor* gcamAverageColor;
CGFloat red, green, blue;
CGFloat hue, saturation, brightness, alpha;
LFXHSBKColor *gcamLifxColor;
//BOOL runOnce;

//LFXHSBKColor *gColor;

-(void) camTick:(NSTimer *)timer
{
#if !(TARGET_IPHONE_SIMULATOR)
    //take screenshot
    [self snapStillImage:self.view];
#endif
    
}

BOOL gMicEnabled = false;
BOOL gLockEnabled = false; //used to lock colour
BOOL gCropEnabled = false;
CGRect cropDimension; // globals are retained between view controllers. I was unable to retain this variable when used as ainstance variable or property.

- (BOOL)isSessionRunningAndDeviceAuthorized
{
    return [[self session] isRunning] && [self isDeviceAuthorized];
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
    return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}

- (void)checkDeviceAuthorizationStatus
{
    NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (granted)
        {
            //Granted access to mediaType
            [self setDeviceAuthorized:YES];
        }
        else
        {
            //Not granted access to mediaType
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"AVCam!"
                                            message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                [self setDeviceAuthorized:NO];
            });
        }
    }];
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
     NSLog(@"***viewDidLoad***");
    //[self.btnCrop setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    //self.viewCropSquare.layer.borderColor = [UIColor redColor].CGColor;
    //self.viewCropSquare.layer.borderWidth = 3.0f;
    
/*
    CGRect imageRect = self.viewCropSquare.frame;
    
    imageRect.origin.x=20;
    imageRect.origin.y=1510;
    self.viewCropSquare.frame = imageRect;
    [[self.viewCropSquare superview] bringSubviewToFront:self.viewCropSquare];
*/
    
    
/*
    
    if (runOnce==FALSE)
    {
        runOnce=TRUE;
        
        paintView=[[UIView alloc]initWithFrame:CGRectMake(50, 100, 100, 200)];
        //NSLog(@"******************cropDimension: %f ,%f ,%f, %f",cropDimension.origin.x, cropDimension.origin.y, cropDimension.size.width, cropDimension.size.height);
        //paintView=[[UIView alloc]initWithFrame:CGRectMake(cropDimension.origin.x, cropDimension.origin.y, cropDimension.size.width, cropDimension.size.height)];
        
        [paintView setBackgroundColor:[UIColor clearColor]];
        paintView.layer.borderColor = [UIColor redColor].CGColor;
        paintView.layer.borderWidth = 3.0f;
        [[self view] addSubview:paintView];
        
        //[self drawRect:rect];
        
    }
*/
    

    
    
    
    
    //CGPoint superCenter = CGPointMake(CGRectGetMidX([self.previewView bounds]), CGRectGetMidY([self.previewView bounds]));
    //[self.viewCropSquare setCenter:superCenter];
    
    //[[self previewView]addSubview:self.viewCropSquare];
    //[self.viewCropSquare setFrame:CGRectMake(38,1510,1030,400)];
    //paintView=[[UIView alloc]initWithFrame:CGRectMake(38,1510,1030,400)];
    //[paintView setBackgroundColor:[UIColor yellowColor]];
    //[self.previewView.layer addSublayer:paintView.layer];
    //[[paintView superview] bringSubviewToFront:paintView];
    
 
    // Create the AVCaptureSession
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [self setSession:session];
    
    // Setup the preview view
    [[self previewView] setSession:session];
     //NSLog(@"****************** previewView: %f ,%f ,%f, %f",self.previewView.layer.frame.origin.x, self.previewView.layer.frame.origin.y, self.previewView.layer.frame.size.width, self.previewView.layer.frame.size.height);
    
    
    // Check for device authorization
    [self checkDeviceAuthorizationStatus];
    
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
    
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:sessionQueue];
    
    dispatch_async(sessionQueue, ^{
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [CamViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if (error)
        {
            NSLog(@"%@", error);
        }
        
        if ([session canAddInput:videoDeviceInput])
        {
            [session addInput:videoDeviceInput];
            [self setVideoDeviceInput:videoDeviceInput];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Why are we dispatching this to the main queue?
                // Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
                // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                
                [[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
            });
        }
        
        AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        if (error)
        {
            NSLog(@"%@", error);
        }
        
        if ([session canAddInput:audioDeviceInput])
        {
            [session addInput:audioDeviceInput];
        }
        
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ([session canAddOutput:movieFileOutput])
        {
            [session addOutput:movieFileOutput];
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([connection isVideoStabilizationSupported])
                [connection setEnablesVideoStabilizationWhenAvailable:YES];
            [self setMovieFileOutput:movieFileOutput];
        }
        
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ([session canAddOutput:stillImageOutput])
        {
            [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
            [session addOutput:stillImageOutput];
            [self setStillImageOutput:stillImageOutput];
        }
    });
    
 /*
    NSDictionary* recorderSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kAudioFormatAppleIMA4],AVFormatIDKey,
                                      [NSNumber numberWithInt:44100],AVSampleRateKey,
                                      [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                                      [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                      [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                      [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                      nil];
    NSError* error = nil;
    recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.caf"]]  settings:recorderSettings error:&error];
    [recorder prepareToRecord];
    recorder.meteringEnabled = YES;
    //[recorder setDelegate:self];
    [recorder record];
    NSError *recorderror;
    [[AVAudioSession sharedInstance]
     setCategory:AVAudioSessionCategoryPlayAndRecord error:&recorderror];
    
    if (recorderror) {
        NSLog(@"Error setting category: %@", [recorderror description]);
    }

    //gImage = [[UIImage alloc] initWithCGImage: gImage.CGImage];
    gcamColor = [UIColor greenColor] ;
*/
    self.audioMeter = [[SCAudioMeter alloc] initWithSamplePeriod:0.05];
    [self.btnMic setTitle: @"Mic Off" forState: UIControlStateNormal];
    [self.btnMic setTitle: @"Mic On" forState: UIControlStateSelected];
    
    [self.btnCrop setTitle: @"Crop" forState: UIControlStateNormal];
    [self.btnCrop setTitle: @"Cropping" forState: UIControlStateSelected];
    // [self showButtonPressed:nil];
    /*
    CGFloat tooltipWidth = 100.0f;
    
    self.tooltipManager = [[JDFTooltipManager alloc] initWithHostView:self.view];
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnLock.center.x,self.btnLock.center.y+15)  tooltipText:@"Lock Bulb Colour" arrowDirection:JDFTooltipViewArrowDirectionDown hostView:[self previewView] width:tooltipWidth];
  
    
    //self.tooltipManager = [[JDFTooltipManager alloc] initWithHostView:self.view];
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnMic.center.x,self.btnMic.center.y+15)  tooltipText:@"Vary Brightness with Audio Level " arrowDirection:JDFTooltipViewArrowDirectionDown hostView:[self previewView] width:tooltipWidth+50];
    
    
    //self.tooltipManager = [[JDFTooltipManager alloc] initWithHostView:self.view];
   // [self.tooltipManager addTooltipWithTargetView:self.btnCrop hostView:self.view tooltipText:@"Limit Colour Calculation to a Crop-Box" arrowDirection:JDFTooltipViewArrowDirectionDown width:tooltipWidth+100];

     [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnCrop.center.x,self.btnCrop.center.y-20)  tooltipText:@"Limit Colour Calculation to Crop-Box Contents" arrowDirection:JDFTooltipViewArrowDirectionDown hostView:[self previewView] width:200];
    
    
    //[self.tooltipManager addTooltipWithTargetBarButtonItem:self.barbtnHelp hostView:[self previewView] tooltipText:@"Tap to dismiss all" arrowDirection:JDFTooltipViewArrowDirectionUp width:tooltipWidth];
    
      [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnHelp.center.x, self.btnHelp.center.y+20) tooltipText:@"Tap to dismiss all, or tap each one individually" arrowDirection:JDFTooltipViewArrowDirectionUp hostView:self.navigationItem.rightBarButtonItem.customView width:200];
    
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.previewView.center.x,self.previewView.center.y+60)  tooltipText:@"Point your camera at a TV for best results" arrowDirection:JDFTooltipViewArrowDirectionDown hostView:[self previewView] width:200];
    */

}


- (void)MicReadOnSeparateThread
{
    NSLog(@"MicReadOnSeparateThread");
   
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"***viewDidAppear***");
    
   // CGFloat tooltipWidth = 100.0f;
    
    self.tooltipManager = [[JDFTooltipManager alloc] initWithHostView:self.view];
    [self.tooltipManager addTooltipWithTargetView:self.btnLock  hostView:self.view tooltipText:@"Lock Bulb Colour" arrowDirection:JDFTooltipViewArrowDirectionDown  width:100];
    
    
    [self.tooltipManager addTooltipWithTargetView:self.btnMic  hostView:self.view tooltipText:@"Vary Brightness with Audio Level" arrowDirection:JDFTooltipViewArrowDirectionDown  width:150];
    
    [self.tooltipManager addTooltipWithTargetView:self.btnCrop  hostView:self.view tooltipText:@"Limit Colour Calculation to Crop-Box Contents" arrowDirection:JDFTooltipViewArrowDirectionDown  width:200];
    
    
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnHelp.center.x, self.btnHelp.center.y+20) tooltipText:@"Tap to dismiss all, or tap each one individually" arrowDirection:JDFTooltipViewArrowDirectionUp hostView:[self.navigationController view] width:200];
    
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.previewView.center.x,self.previewView.center.y+60)  tooltipText:@"Point your camera at a TV for best results" arrowDirection:JDFTooltipViewArrowDirectionDown hostView:[self previewView] width:200];
    

   
    
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"***viewWillAppear***");
     NSLog(@"%@", self);

    dispatch_async([self sessionQueue], ^{
        [self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
        [self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
        [self addObserver:self forKeyPath:@"movieFileOutput.recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
        
        __weak CamViewController *weakSelf = self;
        [self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
            CamViewController *strongSelf = weakSelf;
            dispatch_async([strongSelf sessionQueue], ^{
                // Manually restarting the session since it must have been stopped due to an error.
                [[strongSelf session] startRunning];
                [[strongSelf recordButton] setTitle:NSLocalizedString(@"Record", @"Recording button record title") forState:UIControlStateNormal];
            });
        }]];
        [[self session] startRunning];
    });
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    if (gLockEnabled)
    {
        [self.btnLock setSelected:YES];
    }
    else
    {
        [self.btnLock setSelected:NO];
    }

    if (gMicEnabled)
    {
        [self.btnMic setSelected:YES];
    }
    else
    {
        [self.btnMic setSelected:NO];
    }

    if (gCropEnabled)
    {
        [self.btnCrop setSelected:YES];
    }
    else
    {
        [self.btnCrop setSelected:NO];
    }

    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    //spawn average colour effect thread
    camTimer = [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector:@selector(camTick:) userInfo: nil repeats:YES];
    //NSLog(@"Launching MicReadOnSeparateThread");



    //[NSThread detachNewThreadSelector: @selector(MicReadOnSeparateThread) toTarget: self withObject:nil];
    [self.audioMeter beginAudioMeteringWithCallback:^(double value) {
        double dBValue = 10 * log10(value);
        double sanval = fabs(dBValue);
        double myval = (value+0.1) * 5; if (myval > 1) myval =1;
        //NSLog(@"Value: %0.2f   dBValue:%0.2f  sanval:%0.2f  myval:%0.2f", value,dBValue,sanval,myval);
        //NSLog(@"gMicEnabled:%d",gMicEnabled);
        //gcamLifxColor = [LFXHSBKColor colorWithHue:gcamLifxColor.hue saturation:gcamLifxColor.saturation brightness:myval];
        gcamLifxColor = [gcamLifxColor colorWithBrightness:myval];
        LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
        if (gMicEnabled)  [localNetworkContext.allLightsCollection setColor:gcamLifxColor];
        
    }];
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    

}






- (void)viewWillDisappear:(BOOL)animated {
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
    NSLog(@"***viewWillDisappear***");
    //[self.audioMeter.microphone stopFetchingAudio];
    [self.audioMeter endAudioMetering];
    [camTimer invalidate];
    camTimer = nil;
    [NSThread sleepForTimeInterval:1];
    
    LFXHSBKColor* tmpColor = [LFXHSBKColor whiteColorWithBrightness:1  kelvin:3500];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    [localNetworkContext.allLightsCollection setColor:tmpColor];
    
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
    
    [volumeViewSlider setValue:0.5f animated:YES];
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    


}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    dispatch_async([self sessionQueue], ^{
        [[self session] stopRunning];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
        [[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
        
        [self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
        [self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
        [self removeObserver:self forKeyPath:@"movieFileOutput.recording" context:RecordingContext];
    });
}
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    // Disable autorotation of the interface when recording is in progress.
    return ![self lockInterfaceRotation];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)runStillImageCaptureAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[self previewView] layer] setOpacity:0.0];
        [UIView animateWithDuration:.25 animations:^{
            [[[self previewView] layer] setOpacity:1.0];
        }];
    });
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == CapturingStillImageContext)
    {   /*
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        
        if (isCapturingStillImage)
        {
            [self runStillImageCaptureAnimation];
        }
         */
        
        //if (gCropEnabled) [self drawRect:cropDimension];
    }
    else if (context == RecordingContext)
    {
        BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isRecording)
            {
                [[self cameraButton] setEnabled:NO];
                [[self recordButton] setTitle:NSLocalizedString(@"Stop", @"Recording button stop title") forState:UIControlStateNormal];
                [[self recordButton] setEnabled:YES];
            }
            else
            {
                [[self cameraButton] setEnabled:YES];
                [[self recordButton] setTitle:NSLocalizedString(@"Record", @"Recording button record title") forState:UIControlStateNormal];
                [[self recordButton] setEnabled:YES];
            }
        });
    }
    else if (context == SessionRunningAndDeviceAuthorizedContext)
    {
        BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isRunning)
            {
                [[self cameraButton] setEnabled:YES];
                [[self recordButton] setEnabled:YES];
                [[self stillButton] setEnabled:YES];
            }
            else
            {
                [[self cameraButton] setEnabled:NO];
                [[self recordButton] setEnabled:NO];
                [[self stillButton] setEnabled:NO];
            }
        });
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark UI

#pragma mark Actions

- (IBAction)toggleMovieRecording:(id)sender
{
    [[self recordButton] setEnabled:NO];
    
    dispatch_async([self sessionQueue], ^{
        if (![[self movieFileOutput] isRecording])
        {
            [self setLockInterfaceRotation:YES];
            
            if ([[UIDevice currentDevice] isMultitaskingSupported])
            {
                // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
                [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
            }
            
            // Update the orientation on the movie file output video connection before starting recording.
            [[[self movieFileOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation]];
            
            // Turning OFF flash for video recording
            [CamViewController setFlashMode:AVCaptureFlashModeOff forDevice:[[self videoDeviceInput] device]];
            
            // Start recording to a temporary file.
            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[@"movie" stringByAppendingPathExtension:@"mov"]];
            [[self movieFileOutput] startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
        }
        else
        {
            [[self movieFileOutput] stopRecording];
        }
    });
}

- (IBAction)changeCamera:(id)sender
{
    [[self cameraButton] setEnabled:NO];
    [[self recordButton] setEnabled:NO];
    [[self stillButton] setEnabled:NO];
    
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
        
        switch (currentPosition)
        {
            case AVCaptureDevicePositionUnspecified:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                break;
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
        }
        
        AVCaptureDevice *videoDevice = [CamViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        
        [[self session] beginConfiguration];
        
        [[self session] removeInput:[self videoDeviceInput]];
        if ([[self session] canAddInput:videoDeviceInput])
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
            
            [CamViewController setFlashMode:AVCaptureFlashModeAuto forDevice:videoDevice];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
            
            [[self session] addInput:videoDeviceInput];
            [self setVideoDeviceInput:videoDeviceInput];
        }
        else
        {
            [[self session] addInput:[self videoDeviceInput]];
        }
        
        [[self session] commitConfiguration];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self cameraButton] setEnabled:YES];
            [[self recordButton] setEnabled:YES];
            [[self stillButton] setEnabled:YES];
        });
    });
}


- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *device = [[self videoDeviceInput] device];
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
            {
                [device setFocusMode:focusMode];
                [device setFocusPointOfInterest:point];
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
            {
                [device setExposureMode:exposureMode];
                [device setExposurePointOfInterest:point];
            }
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    });
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ([device hasFlash] && [device isFlashModeSupported:flashMode])
    {
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            [device setFlashMode:flashMode];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    }
}


- (IBAction)snapStillImage:(id)sender
{
    MPVolumeView* volumeView = [[MPVolumeView alloc] init];
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    
    [volumeViewSlider setValue:0.0f animated:YES];
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    dispatch_async([self sessionQueue], ^{
        // Update the orientation on the still image output video connection before capturing.
        [[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation]];
        
        // Flash set to Auto for Still Capture..AVCaptureFlashModeOff AVCaptureFlashModeAuto
        //[CamViewController setFlashMode:AVCaptureFlashModeOff forDevice:[[self videoDeviceInput] device]];
       
       
        // Capture a still image.
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            
            if (imageDataSampleBuffer)
            {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                //UIImage *image = [[UIImage alloc] initWithData:imageData];
                
                myimage = [UIImage imageWithData:imageData];

                //cropImage = image;
               // NSLog(@"original image size:%@",NSStringFromCGSize(image.size));
 /*
                if (runOnce==FALSE)
                {
                    runOnce=TRUE;
                    CGRect rect = self.previewView.bounds;
                    NSLog(@"****************** rect: %f ,%f ,%f, %f",rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
                    //paintView=[[UIView alloc]initWithFrame:CGRectMake(50, 100, 100, 200)];
                    //NSLog(@"******************cropDimension: %f ,%f ,%f, %f",cropDimension.origin.x, cropDimension.origin.y, cropDimension.size.width, cropDimension.size.height);
                    //paintView=[[UIView alloc]initWithFrame:CGRectMake(cropDimension.origin.x, cropDimension.origin.y, cropDimension.size.width, cropDimension.size.height)];
                    
                    //[paintView setBackgroundColor:[UIColor clearColor]];
                    //paintView.layer.borderColor = [UIColor redColor].CGColor;
                    //paintView.layer.borderWidth = 3.0f;
                    //[[self view] addSubview:paintView];
                    
                    //[self drawRect:rect];
                    
                }
*/
                
                
                //******* process image
                //NSLog(@"Process Image");
                if (gCropEnabled)
                {

                   // NSLog(@"cropDimension:%@",NSStringFromCGRect(cropDimension));
                    
                    if (cropDimension.size.width==0) {NSLog(@"no cropping dimensions set");return;}
                    //NSLog(@"****************** viewCropSquare: %f ,%f ,%f, %f",self.viewCropSquare.frame.origin.x, self.viewCropSquare.frame.origin.y, self.viewCropSquare.frame.size.width, self.viewCropSquare.frame.size.height);
                    //NSLog(@"cropDimension: %@",NSStringFromCGRect(cropDimension));

                    
                    //UIImage *cropped = [self UIImageCrop:image rect:cropDimension];
                    myimage = [self UIImageCrop:myimage rect:cropDimension];
                    
                    
                    
                    //NSLog(@"cropped image size:%@",NSStringFromCGSize(cropped.size));
                    //image = cropped;
                    //NSLog(@"image size:%@",NSStringFromCGSize(image.size));
                    //[self drawRect:cropDimension];
                    

                }
                
               // NSLog(@"****************** image : %f ,%f ",myimage.size.width, myimage.size.height);
                
                self.myLabel.backgroundColor=[myimage mergedColor];
                [self.myLabel.backgroundColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
                LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
                gcamLifxColor = [LFXHSBKColor colorWithHue:(hue*360) saturation:saturation brightness:brightness];
                if (!gLockEnabled)[localNetworkContext.allLightsCollection setColor:gcamLifxColor overDuration:0.5];
                //********
              
                //[[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];
            }
        }];
    });
}
/*
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGPathRef path = CGPathCreateWithRect(rect, NULL);
    [[UIColor redColor] setFill];
    [[UIColor greenColor] setStroke];
    CGContextAddPath(context, path);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGPathRelease(path);
}
*/
/*
inline double rad(double deg)
{
    return deg / 180.0 * M_PI;
}
*/
- (UIImage*) UIImageCrop:(UIImage*)img  rect:(CGRect)rect
{
    CGAffineTransform rectTransform;
    switch (img.imageOrientation)
    {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation( M_PI_2), 0, -img.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI_2), -img.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI), -img.size.width, -img.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    rectTransform = CGAffineTransformScale(rectTransform, img.scale, img.scale);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], CGRectApplyAffineTransform(rect, rectTransform));
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:img.scale orientation:img.imageOrientation];


    
    
    CGImageRelease(imageRef);
    return result;
}

- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[[self previewView] layer] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

#pragma mark File Output Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error)
        NSLog(@"%@", error);
    
    [self setLockInterfaceRotation:NO];
    
    // Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
    UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
    [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
    
    [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error)
            NSLog(@"%@", error);
        
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        
        if (backgroundRecordingID != UIBackgroundTaskInvalid)
            [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
    }];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnLockPressed:(id)sender {
    gLockEnabled = !gLockEnabled;
    if (gLockEnabled)
    {
        [self.btnLock setSelected:YES];
    }
    else
    {
        [self.btnLock setSelected:NO];
    }
    
    
    //overlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play2"]];
    //[overlayImageView setFrame:CGRectMake(30, 100, 75, 75)];
    //[[self view] addSubview:overlayImageView];
    
    //[[paintView superview] bringSubviewToFront:paintView];
    //if (cropDimension.size.width==0) return;
 
   


    
}


- (IBAction)btnMicPressed:(id)sender
{
    gMicEnabled = !gMicEnabled;
    if (gMicEnabled)
    {
        [self.btnMic setSelected:YES];
    }
    else
    {
        [self.btnMic setSelected:NO];
    }
}

- (IBAction)btnHelpPressed:(id)sender
{
    self.btnHelp.selected = !self.btnHelp.selected;
    

    
    if (self.btnHelp.selected)
    {
        //JDFTooltipView *tooltip = [self.tooltipManager.tooltips lastObject];
        //[tooltip show];
        [self.tooltipManager showAllTooltips];
        [self.btnHelp setSelected:YES];
        [self.btnHelp setImage: [UIImage imageNamed:@"help_on"] forState:UIControlStateNormal] ;
        
    }
    else
    {
        //JDFTooltipView *tooltip = [self.tooltipManager.tooltips lastObject];
        //[tooltip hideAnimated:TRUE];
        [self.tooltipManager hideAllTooltipsAnimated:TRUE];
        [self.btnHelp setSelected:NO];
        [self.btnHelp setImage: [UIImage imageNamed:@"help"] forState:UIControlStateNormal] ;
        
    }
    
}
#if (CROP==1)

- (IBAction)cropBarButtonClick:(id)sender
{
    gCropEnabled = !gCropEnabled;
    if (gCropEnabled)
    {
        [self.btnCrop setSelected:YES];
        
        //self.viewCropSquare.hidden=FALSE;
        
        //self.previewView.layer.frame = self.viewCropSquare.frame;
        //self.previewView.layer.frame.origin.y, self.previewView.layer.frame.size.width, self.previewView.layer.frame.size.height
        
        if(myimage != nil)
        {
            ImageCropViewController *controller = [[ImageCropViewController alloc] initWithImage:myimage];
            controller.delegate = self;
            controller.blurredBackground = YES;
            [[self navigationController] pushViewController:controller animated:YES];
        }

    }
    else
    {
        [self.btnCrop setSelected:NO];
        //self.viewCropSquare.hidden=TRUE ;
        //return;
    }
    //NSLog(@"****************** viewCropSquare: %f ,%f ,%f, %f",self.viewCropSquare.frame.origin.x, self.viewCropSquare.frame.origin.y, self.viewCropSquare.frame.size.width, self.viewCropSquare.frame.size.height);

    
    
}




- (void)ImageCropViewController:(ImageCropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage withDimension:(CGRect)dimension
{
    //gCroppedImage = croppedImage;
    //imageView.image = croppedImage;
    NSLog(@"dimension: %@",NSStringFromCGRect(dimension));
    cropDimension = dimension;
    /////

    /////
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)ImageCropViewControllerDidCancel:(ImageCropViewController *)controller
{
    //imageView.image = cropImage;
    [[self navigationController] popViewControllerAnimated:YES];
}
#endif

@end


/*
 
 

- (IBAction)done:(id)sender
{
    
    if ([self.delegate respondsToSelector:@selector(ImageCropViewController:didFinishCroppingImage:)])
    {
        UIImage *cropped;
        if (self.image != nil){
            CGRect CropRect = self.cropView.cropAreaInImage;
            CGImageRef imageRef = CGImageCreateWithImageInRect([self.image CGImage], CropRect) ;
            cropped = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
        [self.delegate ImageCropViewController:self didFinishCroppingImage:cropped];
    }
    
}


 
 

CGFloat kResizeThumbSize = 30.0f;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    touchStart = [[touches anyObject] locationInView:self.viewCropSquare];
    isResizingLR = (self.viewCropSquare.bounds.size.width - touchStart.x < kResizeThumbSize && self.viewCropSquare.bounds.size.height - touchStart.y < kResizeThumbSize);
    isResizingUL = (touchStart.x <kResizeThumbSize && touchStart.y <kResizeThumbSize);
    isResizingUR = (self.viewCropSquare.bounds.size.width-touchStart.x < kResizeThumbSize && touchStart.y<kResizeThumbSize);
    isResizingLL = (touchStart.x <kResizeThumbSize && self.viewCropSquare.bounds.size.height -touchStart.y <kResizeThumbSize);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint touchPoint = [[touches anyObject] locationInView:self.viewCropSquare];
    CGPoint previous = [[touches anyObject] previousLocationInView:self.viewCropSquare];
    
    CGFloat deltaWidth = touchPoint.x - previous.x;
    CGFloat deltaHeight = touchPoint.y - previous.y;
    
    // get the frame values so we can calculate changes below
    CGFloat x = self.viewCropSquare.frame.origin.x;
    CGFloat y = self.viewCropSquare.frame.origin.y;
    CGFloat width = self.viewCropSquare.frame.size.width;
    CGFloat height = self.viewCropSquare.frame.size.height;
    
    if (isResizingLR) {
        self.viewCropSquare.frame = CGRectMake(x, y, touchPoint.x+deltaWidth, touchPoint.y+deltaWidth);
    } else if (isResizingUL) {
        self.viewCropSquare.frame = CGRectMake(x+deltaWidth, y+deltaHeight, width-deltaWidth, height-deltaHeight);
    } else if (isResizingUR) {
        self.viewCropSquare.frame = CGRectMake(x, y+deltaHeight, width+deltaWidth, height-deltaHeight);
    } else if (isResizingLL) {
        self.viewCropSquare.frame = CGRectMake(x+deltaWidth, y, width-deltaWidth, height+deltaHeight);
    } else {
        // not dragging from a corner -- move the view
        self.viewCropSquare.center = CGPointMake(self.viewCropSquare.center.x + touchPoint.x - touchStart.x,
                                                 self.viewCropSquare.center.y + touchPoint.y - touchStart.y);
    }
}


+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize;
{
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

*/


