

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VisualizerView : UIView

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (nonatomic) float glevel;
@property (nonatomic) float sliderScaleValue;
@property (nonatomic) float sliderThresholdValue;

@property (nonatomic) float LevelValue;
@property (nonatomic) NSMutableArray *vizInputLights;


- (void) vizStop;
- (void) vizStart;

@end
