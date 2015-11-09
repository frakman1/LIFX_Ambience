//
//  Copyright (c) 2013-2015 Cédric Luthi. All rights reserved.
//

#import "XCDYouTubeVideoPlayerViewController.h"
#import "UIImageAverageColorAddition.h"
#import "LIFXKit/LIFXKit.h"


#import "XCDYouTubeClient.h"

#import <objc/runtime.h>

NSString *const XCDMoviePlayerPlaybackDidFinishErrorUserInfoKey = @"error"; // documented in -[MPMoviePlayerController initWithContentURL:]

NSString *const XCDYouTubeVideoPlayerViewControllerDidReceiveMetadataNotification = @"XCDYouTubeVideoPlayerViewControllerDidReceiveMetadataNotification";
NSString *const XCDMetadataKeyTitle = @"Title";
NSString *const XCDMetadataKeySmallThumbnailURL = @"SmallThumbnailURL";
NSString *const XCDMetadataKeyMediumThumbnailURL = @"MediumThumbnailURL";
NSString *const XCDMetadataKeyLargeThumbnailURL = @"LargeThumbnailURL";

NSString *const XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification = @"XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification";
NSString *const XCDYouTubeVideoUserInfoKey = @"Video";

@interface XCDYouTubeVideoPlayerViewController ()
@property (nonatomic, weak) id<XCDYouTubeOperation> videoOperation;
@property (nonatomic, assign, getter = isEmbedded) BOOL embedded;
@end

@implementation XCDYouTubeVideoPlayerViewController
- (BOOL) prefersStatusBarHidden {return YES;}


/*
 * MPMoviePlayerViewController on iOS 7 and earlier
 * - (id) init
 *        `-- [super init]
 *
 * - (id) initWithContentURL:(NSURL *)contentURL
 *        |-- [self init]
 *        `-- [self.moviePlayer setContentURL:contentURL]
 *
 * MPMoviePlayerViewController on iOS 8 and later
 * - (id) init
 *        `-- [self initWithContentURL:nil]
 *
 * - (id) initWithContentURL:(NSURL *)contentURL
 *        |-- [super init]
 *        `-- [self.moviePlayer setContentURL:contentURL]
 */

- (instancetype) init
{
	return [self initWithVideoIdentifier:nil];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype) initWithContentURL:(NSURL *)contentURL
{
	@throw [NSException exceptionWithName:NSGenericException reason:@"Use the `initWithVideoIdentifier:` method instead." userInfo:nil];
}

- (instancetype) initWithVideoIdentifier:(NSString *)videoIdentifier
{
	if ([[[UIDevice currentDevice] systemVersion] integerValue] >= 8)
		self = [super initWithContentURL:nil];
	else
		self = [super init];
	
	if (!self)
		return nil;
	
	// See https://github.com/0xced/XCDYouTubeKit/commit/cadec1c3857d6a302f71b9ce7d1ae48e389e6890
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	if (videoIdentifier)
		self.videoIdentifier = videoIdentifier;
	
	return self;
}
#pragma clang diagnostic pop

#pragma mark - Public

- (NSArray *) preferredVideoQualities
{
	if (!_preferredVideoQualities)
		_preferredVideoQualities = @[ XCDYouTubeVideoQualityHTTPLiveStreaming, @(XCDYouTubeVideoQualityHD720), @(XCDYouTubeVideoQualityMedium360), @(XCDYouTubeVideoQualitySmall240) ];
	
	return _preferredVideoQualities;
}

- (void) setVideoIdentifier:(NSString *)videoIdentifier
{
	if ([videoIdentifier isEqual:self.videoIdentifier])
		return;
	
	_videoIdentifier = [videoIdentifier copy];
	
	[self.videoOperation cancel];
	self.videoOperation = [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoIdentifier completionHandler:^(XCDYouTubeVideo *video, NSError *error)
	{
		if (video)
		{
			NSURL *streamURL = nil;
			for (NSNumber *videoQuality in self.preferredVideoQualities)
			{
				streamURL = video.streamURLs[videoQuality];
				if (streamURL)
				{
					[self startVideo:video streamURL:streamURL];
					break;
				}
			}
			
			if (!streamURL)
			{
				NSError *noStreamError = [NSError errorWithDomain:XCDYouTubeVideoErrorDomain code:XCDYouTubeErrorNoStreamAvailable userInfo:nil];
				[self stopWithError:noStreamError];
			}
		}
		else
		{
			[self stopWithError:error];
		}
	}];
}

- (void) presentInView:(UIView *)view
{
	static const void * const XCDYouTubeVideoPlayerViewControllerKey = &XCDYouTubeVideoPlayerViewControllerKey;
	
	self.embedded = YES;
	
	self.moviePlayer.controlStyle = MPMovieControlStyleEmbedded;
	self.moviePlayer.view.frame = CGRectMake(0.f, 0.f, view.bounds.size.width, view.bounds.size.height);
	self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	if (![view.subviews containsObject:self.moviePlayer.view])
		[view addSubview:self.moviePlayer.view];
	objc_setAssociatedObject(view, XCDYouTubeVideoPlayerViewControllerKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Private

- (void) startVideo:(XCDYouTubeVideo *)video streamURL:(NSURL *)streamURL
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	if (video.title)
		userInfo[XCDMetadataKeyTitle] = video.title;
	if (video.smallThumbnailURL)
		userInfo[XCDMetadataKeySmallThumbnailURL] = video.smallThumbnailURL;
	if (video.mediumThumbnailURL)
		userInfo[XCDMetadataKeyMediumThumbnailURL] = video.mediumThumbnailURL;
	if (video.largeThumbnailURL)
		userInfo[XCDMetadataKeyLargeThumbnailURL] = video.largeThumbnailURL;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XCDYouTubeVideoPlayerViewControllerDidReceiveMetadataNotification object:self userInfo:userInfo];
#pragma clang diagnostic pop
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XCDYouTubeVideoPlayerViewControllerDidReceiveVideoNotification object:self userInfo:@{ XCDYouTubeVideoUserInfoKey: video }];
	
	self.moviePlayer.contentURL = streamURL;
}

- (void) stopWithError:(NSError *)error
{
	NSDictionary *userInfo = @{ MPMoviePlayerPlaybackDidFinishReasonUserInfoKey: @(MPMovieFinishReasonPlaybackError),
	                            XCDMoviePlayerPlaybackDidFinishErrorUserInfoKey: error };
	[[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer userInfo:userInfo];
	
	if (self.isEmbedded)
		[self.moviePlayer.view removeFromSuperview];
	else
		[self.presentingViewController dismissMoviePlayerViewControllerAnimated];
}


NSTimer *vidtimer;
-(void)myvidTick:(NSTimer *)timer
{
    
    //NSLog(@"myvidTick..");
    UIImage *capturedScreen = [ self.moviePlayer thumbnailImageAtTime:(self.moviePlayer.currentPlaybackTime+0.25)*1.0f timeOption:MPMovieTimeOptionNearestKeyFrame];

    //NSLog(@"Captured image size is %f X %f",capturedScreen.size.width,capturedScreen.size.height);
    UIColor* averageColor = [capturedScreen mergedColor];
    CGFloat red, green, blue;
    CGFloat hue, saturation, brightness, alpha;
    LFXHSBKColor *lifxColor;
    
    [averageColor getRed:&red green:&green blue:&blue alpha:NULL];
    [averageColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    [localNetworkContext.allLightsCollection setPowerState:LFXPowerStateOn];
    lifxColor = [LFXHSBKColor colorWithHue:(hue*360) saturation:saturation brightness:brightness];
    //[localNetworkContext.allLightsCollection setColor:lifxColor overDuration:0.25];
    for (NSString *aDevID in self.ytpInputLights)
    {
        LFXLight *aLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
        [aLight setPowerState:LFXPowerStateOn];
        [aLight setColor:lifxColor overDuration:0.25];
    }

    
    // NSLog(@"%@",[NSString stringWithFormat:@"average color: %.2f %.2f %.2f", red, green, blue]);
    //NSLog(@"%@",[NSString stringWithFormat:@"hue: %.2f saturation: %.2f  brightness: %.2f alpha: %.2f", hue, saturation, brightness, alpha]);
    
}

#pragma mark - UIViewController

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    vidtimer = [NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector:@selector(myvidTick:) userInfo: nil repeats:YES];

	if (![self isBeingPresented])
		return;
	
	self.moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
	[self.moviePlayer play];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    [vidtimer invalidate];
    vidtimer = nil;

	
	if (![self isBeingDismissed])
		return;
	
	[self.videoOperation cancel];
}

- (BOOL) shouldAutorotate
{
    return NO;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeLeft;
}

@end
