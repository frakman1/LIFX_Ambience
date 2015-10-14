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
#import "ANPopoverSlider.h"




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
{
    ANPopoverSlider *myslider_threshold;
    ANPopoverSlider *myslider_scale;
    UIImageView *imgExpo;
    UIImageView *imgOffset;
    UILabel *lblOffset;
    UILabel *lblExpo;
}

AVAudioRecorder* recorder;
NSTimer *camTimer;
//UIImage *gImage;
UIColor *gcamColor ;
UIColor* gcamAverageColor;
CGFloat red, green, blue;
CGFloat hue, saturation, brightness, alpha;
LFXHSBKColor *gcamLifxColor;
CGFloat gMicBrightness;
BOOL runOnce;

//LFXHSBKColor *gColor;


@synthesize powerLevel;


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

//update slider scale
-(IBAction)updateslider_scale:(id)sender
{
    UISlider * slider = (UISlider*)sender;
    NSLog(@"Scale Slider Value: %.2f", [slider value]);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:[slider value] forKey:@"mymicScaler"];
    [defaults synchronize];
    
}


//update slider threshold
-(IBAction)updateslider_threshold:(id)sender
{
    UISlider * slider = (UISlider*)sender;
    NSLog(@"Threshold Slider Value: %.2f", [slider value]);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:[slider value] forKey:@"mymicThreshold"];
    [defaults synchronize];
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"***viewDidLoad***");
    
    [self.powerLevel setThumbImage: [UIImage new] forState:UIControlStateNormal];
    
    
    //myslider_threshold = [[ANPopoverSlider alloc] initWithFrame:CGRectMake(self.view.frame.origin.x-20, 270, 160, 30)];
    myslider_threshold = [[ANPopoverSlider alloc] init];
    
    myslider_threshold.value=0.2;
    myslider_threshold.transform = CGAffineTransformRotate(myslider_threshold.transform, -0.5*M_PI);
    //myslider_threshold.transform = CGAffineTransformScale(myslider_threshold.transform, 1.0, -1.0);
    [self.view addSubview:myslider_threshold];
    [myslider_threshold addTarget:self action:@selector(updateslider_threshold:) forControlEvents:UIControlEventValueChanged];
    myslider_threshold.hidden = TRUE;
    
    
    lblOffset = [[UILabel alloc] init];
    lblOffset.textColor = [UIColor whiteColor];
    lblOffset.font=[lblOffset.font fontWithSize:15];
    lblOffset.numberOfLines = 0;
    [lblOffset sizeToFit];
    lblOffset.textAlignment = NSTextAlignmentCenter;
    //lblOffset.lineBreakMode= NSLineBreakByWordWrapping ;
    lblOffset.text = @"Brightness \n Threshold";
    //lblOffset.frame = CGRectMake(myslider_threshold.center.x-50, myslider_threshold.frame.origin.y+myslider_threshold.frame.size.height-50, 90, 180);
    
    
    lblOffset.hidden = TRUE;
    [self.view addSubview:lblOffset];
    
    
    //create vertical slider - Scaler
    //myslider_scale = [[ANPopoverSlider alloc] initWithFrame:CGRectMake(self.view.frame.size.width-130, 270, 160, 30)];
    myslider_scale = [[ANPopoverSlider alloc] init];

    myslider_scale.maximumValue = 10;
    myslider_scale.minimumValue = 1;
    myslider_scale.value=1;
    myslider_scale.transform = CGAffineTransformRotate(myslider_scale.transform, -0.5*M_PI);
    [self.view addSubview:myslider_scale];
    [myslider_scale addTarget:self action:@selector(updateslider_scale:) forControlEvents:UIControlEventValueChanged];
    myslider_scale.hidden = TRUE;
    
    NSLog (@"myslider_scale x:%f y:%f width:%f height:%f",myslider_scale.frame.origin.x,myslider_scale.frame.origin.y,myslider_scale.frame.size.width,myslider_scale.frame.size.height);
    
   
    lblExpo = [[UILabel alloc] init];
    lblExpo.textColor = [UIColor whiteColor];
    lblExpo.font=[lblExpo.font fontWithSize:15];
    lblExpo.numberOfLines = 0;
    [lblExpo sizeToFit];
    lblExpo.textAlignment = NSTextAlignmentCenter;
    lblExpo.text = @"Sensitivity";
    //lblExpo.frame = CGRectMake(myslider_scale.center.x-50, lblOffset.frame.origin.y, 90, 180);
    lblExpo.hidden = TRUE;
    
    [self.view addSubview:lblExpo];
    
    
    //load saved slider Values
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    myslider_threshold.value = [defaults floatForKey:@"mymicThreshold"];
    NSLog(@"Saved Threshold: %f",myslider_threshold.value);
    if (myslider_threshold.value == 0.0)
    {
        NSLog(@" Threshold Invalid");
        myslider_threshold.value = 0.2;
    }
    
    //load saved slider Values
    myslider_scale.value = [defaults floatForKey:@"mymicScaler"];
    NSLog(@"Saved Scaler: %f",myslider_scale.value);
    if (myslider_scale.value == 0.0)
    {
        NSLog(@" Scaler Invalid");
        myslider_scale.value = 3;
    }


    
    /*
    NSLog(@"lblExpo  size:%@",NSStringFromCGSize(lblExpo.bounds.size));
    
    myslider_threshold.translatesAutoresizingMaskIntoConstraints = NO;
    myslider_scale.translatesAutoresizingMaskIntoConstraints = NO;

    NSDictionary *viewsDictionary = @{@"threshold":myslider_threshold,@"scale":myslider_scale,
                                      @"tlbl":lblOffset,@"slbl":lblExpo};
    
   
    NSArray *tconstraint_H = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[threshold(30)]"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:viewsDictionary];
    
    NSArray *tconstraint_V = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[threshold(160)]"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:viewsDictionary];
    [myslider_threshold addConstraints:tconstraint_H];
    [myslider_threshold addConstraints:tconstraint_V];
    
    NSArray *sconstraint_H = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[scale(30)]"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:viewsDictionary];
    
    NSArray *sconstraint_V = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[scale(160)]"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:viewsDictionary];
    [myslider_scale addConstraints:sconstraint_H];
    [myslider_scale addConstraints:sconstraint_V];
 
    
    
    
    NSArray *tlblconstraint_H = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[tlbl(180)]"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:viewsDictionary];
    
    NSArray *tlblconstraint_V = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[tlbl(90)]"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:viewsDictionary];
    [lblOffset addConstraints:tlblconstraint_H];
    [lblOffset addConstraints:tlblconstraint_V];
    
    NSArray *slblconstraint_H = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[slbl(180)]"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:viewsDictionary];
    
    NSArray *slblconstraint_V = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[slbl(90)]"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:viewsDictionary];
    [lblExpo addConstraints:slblconstraint_H];
    [lblExpo addConstraints:slblconstraint_V];
    
    
    
    //------------------------------------------------------------------------------------------------
    
    NSArray *tconstraint_POS_V = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[threshold][tlbl]-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:viewsDictionary];
    
    NSArray *sconstraint_POS_V = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[scale][slbl]-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:viewsDictionary];

    
    NSArray *tconstraint_POS_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[threshold]"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:viewsDictionary];
    NSArray *sconstraint_POS_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[scale]|"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:viewsDictionary];

    
    // 3.B ...and try to change the visual format string
    //NSArray *constraint_POS_V = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[redView]-30-|" options:0 metrics:nil views:viewsDictionary];
    //NSArray *constraint_POS_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[redView]" options:0 metrics:nil views:viewsDictionary];
    
    [self.view addConstraints:tconstraint_POS_H];
    [self.view addConstraints:sconstraint_POS_H];

    [self.view addConstraints:tconstraint_POS_V];
    [self.view addConstraints:sconstraint_POS_V];
     */

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
    //[self.btnMic setTitle: @"Mic Off" forState: UIControlStateNormal];
    //[self.btnMic setTitle: @"Mic On" forState: UIControlStateSelected];
    
    [self.btnCrop setTitle: @"Crop" forState: UIControlStateNormal];
    [self.btnCrop setTitle: @"Cropping" forState: UIControlStateSelected];
    // [self showButtonPressed:nil];

    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"***viewDidAppear***");
    
    // CGFloat tooltipWidth = 100.0f;
    
    self.tooltipManager = [[JDFTooltipManager alloc] initWithHostView:self.view];
    [self.tooltipManager addTooltipWithTargetView:self.btnLock  hostView:self.view tooltipText:@"Lock Bulb Colour" arrowDirection:JDFTooltipViewArrowDirectionDown  width:100];
    
    
    [self.tooltipManager addTooltipWithTargetView:self.btnMic  hostView:self.view tooltipText:@"Vary Brightness with Microphone Level" arrowDirection:JDFTooltipViewArrowDirectionDown  width:160];
    
    [self.tooltipManager addTooltipWithTargetView:self.btnCrop  hostView:self.view tooltipText:@"Limit Colour Calculation to Crop-Box Contents" arrowDirection:JDFTooltipViewArrowDirectionDown  width:200];
    
    
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.btnHelp.center.x, self.btnHelp.center.y+20) tooltipText:@"Tap to dismiss" arrowDirection:JDFTooltipViewArrowDirectionUp hostView:[self.navigationController view] width:200];
    
    [self.tooltipManager addTooltipWithTargetPoint:CGPointMake(self.previewView.center.x,self.previewView.center.y+60)  tooltipText:@"Point your camera at a TV for best results.\n\nTap screen to adjust focus" arrowDirection:JDFTooltipViewArrowDirectionDown hostView:[self previewView] width:200];
    
    
    
    
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"***viewWillAppear***");
    [UIView setAnimationsEnabled:NO];
    //NSLog(@"%@", self);
    //NSLog(@"***Overriding orientation.");
    //NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    //[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    NSLog(@"inputLights:%@",self.inputLights);

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
        [self.btnLock setImage: [UIImage imageNamed:@"lifxlockon"] forState:UIControlStateNormal] ;
    }
    else
    {
        [self.btnLock setSelected:NO];
        [self.btnLock setImage: [UIImage imageNamed:@"lifxlockoff"] forState:UIControlStateNormal] ;
    }
    
    if (gMicEnabled)
    {
        [self.btnMic setSelected:YES];
        [self.btnMic setImage: [UIImage imageNamed:@"micon"] forState:UIControlStateNormal] ;
        lblExpo.hidden = FALSE;
        lblOffset.hidden = FALSE;
        myslider_scale.hidden = FALSE;
        myslider_threshold.hidden = FALSE;
        self.powerLevel.hidden = FALSE;
    }
    else
    {
        [self.btnMic setSelected:NO];
        [self.btnMic setImage: [UIImage imageNamed:@"micoff"] forState:UIControlStateNormal] ;
        lblExpo.hidden = TRUE;
        lblOffset.hidden = TRUE;
        myslider_scale.hidden = TRUE;
        myslider_threshold.hidden = TRUE;
        self.powerLevel.hidden = TRUE;

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
    
    
    
    [self.audioMeter beginAudioMeteringWithCallback:^(double value) {
        double dBValue = 10 * log10(value);
        double sanval = fabs(dBValue);
        double myval = (value + myslider_threshold.value) ; if (myval > 1) myval =1;
        myval = powf(myval, myslider_scale.value);
        gMicBrightness = myval;
        //NSLog(@"Value: %0.2f   dBValue:%0.2f  sanval:%0.2f  myval:%0.2f", value,dBValue,sanval,myval);
        //NSLog(@"gMicEnabled:%d",gMicEnabled);
        //gcamLifxColor = [LFXHSBKColor colorWithHue:gcamLifxColor.hue saturation:gcamLifxColor.saturation brightness:myval];
        //gcamLifxColor = [gcamLifxColor colorWithBrightness:myval];
        //LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
        //if (gMicEnabled)  [localNetworkContext.allLightsCollection setColor:gcamLifxColor];
        
    }];
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //////////// constraints ///////////
    
    
    myslider_threshold.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *myslider_thresholdHeight = [NSLayoutConstraint constraintWithItem:myslider_threshold attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:30];
    
    NSLayoutConstraint *myslider_thresholdWidth = [NSLayoutConstraint constraintWithItem:myslider_threshold attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:160];
    
    [myslider_threshold addConstraint:myslider_thresholdHeight]; [myslider_threshold addConstraint:myslider_thresholdWidth];
    
    NSLayoutConstraint *myslider_thresholdLeft = [NSLayoutConstraint constraintWithItem:myslider_threshold attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-30]; [self.view addConstraint:myslider_thresholdLeft];
    
    NSLayoutConstraint *myslider_thresholdBottom = [NSLayoutConstraint constraintWithItem:myslider_threshold attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]; [self.view addConstraint:myslider_thresholdBottom];
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    myslider_scale.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *myslider_scaleHeight = [NSLayoutConstraint constraintWithItem:myslider_scale attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:30];
    
    NSLayoutConstraint *myslider_scaleWidth = [NSLayoutConstraint constraintWithItem:myslider_scale attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:160];
    
    [myslider_scale addConstraint:myslider_scaleHeight]; [myslider_scale addConstraint:myslider_scaleWidth];
    
    NSLayoutConstraint *myslider_scaleRight = [NSLayoutConstraint constraintWithItem:myslider_scale attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:50]; [self.view addConstraint:myslider_scaleRight];
    
    NSLayoutConstraint *myslider_scaleBottom = [NSLayoutConstraint constraintWithItem:myslider_scale attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]; [self.view addConstraint:myslider_scaleBottom];
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    lblOffset.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *lblOffsetHeight = [NSLayoutConstraint constraintWithItem:lblOffset attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:180];
    
    NSLayoutConstraint *lblOffsetWidth = [NSLayoutConstraint constraintWithItem:lblOffset attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:90];
    
    [lblOffset addConstraint:lblOffsetHeight]; [lblOffset addConstraint:lblOffsetWidth];
    
    NSLayoutConstraint *lblOffsetLeft = [NSLayoutConstraint constraintWithItem:lblOffset attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]; [self.view addConstraint:lblOffsetLeft];
    
    NSLayoutConstraint *lblOffsetBottom = [NSLayoutConstraint constraintWithItem:lblOffset attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-40]; [self.view addConstraint:lblOffsetBottom];
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    lblExpo.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *lblExpoHeight = [NSLayoutConstraint constraintWithItem:lblExpo attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:180];
    
    NSLayoutConstraint *lblExpoWidth = [NSLayoutConstraint constraintWithItem:lblExpo attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:90];
    
    [lblExpo addConstraint:lblExpoHeight]; [lblExpo addConstraint:lblExpoWidth];
    
    NSLayoutConstraint *lblExpoRight = [NSLayoutConstraint constraintWithItem:lblExpo attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]; [self.view addConstraint:lblExpoRight];
    
    NSLayoutConstraint *lblExpoBottom = [NSLayoutConstraint constraintWithItem:lblExpo attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-40]; [self.view addConstraint:lblExpoBottom];
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    
    
    
    //////////// end of constraints ///////////
    
}






- (void)viewWillDisappear:(BOOL)animated {
    [self resignFirstResponder];
    
    NSLog(@"***viewWillDisappear***");
    
    
    
    //[self.audioMeter.microphone stopFetchingAudio];
    [self.audioMeter endAudioMetering];
    [camTimer invalidate];
    camTimer = nil;
    //[NSThread sleepForTimeInterval:1];
    
    //reset lights
    //LFXHSBKColor* tmpColor = [LFXHSBKColor whiteColorWithBrightness:1  kelvin:3500];
    //LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    //[localNetworkContext.allLightsCollection setColor:tmpColor];
    
    [self.btnHelp setSelected:NO];
    [self.btnHelp setImage: [UIImage imageNamed:@"help"] forState:UIControlStateNormal] ;
    
    [self.tooltipManager hideAllTooltipsAnimated:FALSE];
    [self mute];
    [super viewWillDisappear:animated];
}



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

- (void)viewDidDisappear:(BOOL)animated
{
    
    
    dispatch_async([self sessionQueue], ^{
        [[self session] stopRunning];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
        [[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
        
        [self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
        [self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
        [self removeObserver:self forKeyPath:@"movieFileOutput.recording" context:RecordingContext];
        
    });
    
    [self mute];
    
    [super viewDidDisappear:animated];
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
    //return UIInterfaceOrientationLandscapeLeft ;
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
/*
- (void)didMoveToParentViewController:(UIViewController *)parent
{
    NSLog(@"%@",parent.title );
    if (![parent isEqual:self.parentViewController])
    {
        NSLog(@"Back pressed");
        [self mute];
        
    }
}
 */
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

    [self mute];
    
    
    dispatch_async([self sessionQueue], ^{
        // Update the orientation on the still image output video connection before capturing.
        [[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation]];
        
        // Flash set to Auto for Still Capture..AVCaptureFlashModeOff AVCaptureFlashModeAuto
        //[CamViewController setFlashMode:AVCaptureFlashModeOff forDevice:[[self videoDeviceInput] device]];
        
        
        // Capture a still image.
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            
            if (imageDataSampleBuffer)
            {
                static NSData *imageData;
                imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
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
                //NSLog(@"gMicBrightness:%f",gMicBrightness);
                
                //Calculate Average Colour.
                //***************************************************************************************//
                self.myLabel.backgroundColor=[myimage mergedColor];
                //***************************************************************************************//
                
                [self.myLabel.backgroundColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
                
                //gcamLifxColor = [LFXHSBKColor colorWithHue:(hue*360) saturation:saturation brightness:brightness];
                if (!gLockEnabled)
                {
                    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
                    
                    if (gMicEnabled)
                    {
                        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           self.powerLevel.value = gMicBrightness;
                       });
                        gcamLifxColor = [LFXHSBKColor colorWithHue:(hue*360) saturation:saturation brightness:gMicBrightness];
                        
                    }
                    else
                    {
                        gcamLifxColor = [LFXHSBKColor colorWithHue:(hue*360) saturation:saturation brightness:brightness];
                    }
                    
                    //[localNetworkContext.allLightsCollection setColor:gcamLifxColor overDuration:0.5];
                    for (NSString *aDevID in self.inputLights)
                    {
                        LFXLight *aLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
                        [aLight setColor:gcamLifxColor overDuration:0.5];
                    }
                }
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
         [self.btnLock setImage: [UIImage imageNamed:@"lifxlockon"] forState:UIControlStateNormal] ;
    }
    else
    {
        [self.btnLock setSelected:NO];
         [self.btnLock setImage: [UIImage imageNamed:@"lifxlockoff"] forState:UIControlStateNormal] ;
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
    myslider_threshold.hidden = !myslider_threshold.hidden;
    myslider_scale.hidden = !myslider_scale.hidden;
    self.powerLevel.hidden = !self.powerLevel.hidden;
    lblOffset.hidden = !lblOffset.hidden;
    lblExpo.hidden = !lblExpo.hidden;

    if (gMicEnabled)
    {
        [self.btnMic setSelected:YES];
        [self.btnMic setImage: [UIImage imageNamed:@"micon"] forState:UIControlStateNormal] ;

    }
    else
    {
        [self.btnMic setSelected:NO];
        [self.btnMic setImage: [UIImage imageNamed:@"micoff"] forState:UIControlStateNormal] ;
        
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
        [sender removeFromSuperview];
        sender = nil;

        
    }
    
}
#if !(TARGET_IPHONE_SIMULATOR)

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
    [self.btnCrop setSelected:NO];gCropEnabled = FALSE;
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
