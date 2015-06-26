

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VisualizerView : UIView

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (nonatomic) float glevel;


- (void) vizStop;
- (void) vizStart;
@end
