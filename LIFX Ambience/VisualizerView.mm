
#import "VisualizerView.h"
#import <QuartzCore/QuartzCore.h>
#import "MeterTable/MeterTable.h"
#import <LIFXKit/LIFXKit.h>
#import "VizViewController.h"
//#import "UIImageAverageColorAddition.h"
#define MIN(A,B)    ({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __a : __b; })
#define MAX(A,B)    ({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __b : __a; })

#define CLAMP(x, low, high) ({\
__typeof__(x) __x = (x); \
__typeof__(low) __low = (low);\
__typeof__(high) __high = (high);\
__x > __high ? __high : (__x < __low ? __low : __x);\
})

@implementation VisualizerView {
        MeterTable meterTable;
    UIColor *gColor ;
    LFXHSBKColor* gLifxColor ;
    CGFloat saturation, brightness, alpha;
    CGFloat gIncrement;
    CGFloat starthue;
    BOOL stopFlag ;
    CADisplayLink *dpLink;
    
    // cell constants
    CAEmitterLayer *emitterLayer;
    CAEmitterCell *cell ;
    CAEmitterCell *childCell ;
    
    
    
}
BOOL vizRunOnce;

double round(double d)
{
    return floor(d + 0.5);
}


+ (Class)layerClass {
    return [CAEmitterLayer class];
}

- (void) vizStop {
    NSLog(@"stopping Run Loop");
    stopFlag = TRUE;
    
    return;
}
- (void) vizStart {
    NSLog(@"resuming Run Loop");
    stopFlag = FALSE;
    
    return;
}


- (id)initWithFrame:(CGRect)frame
{
    stopFlag = FALSE;
    vizRunOnce = FALSE;
    NSLog(@"initWithFrame()");
    //vizTagged.lights = [[NSArray alloc] initWithArray:self.vizInputLights2];
    
    

   // gColor = [UIColor colorWithRed:0.27f green:0.5f blue:0.7f alpha:1.0f] ;
   // [gColor getHue:&starthue saturation:&saturation brightness:&brightness alpha:&alpha];
   // gLifxColor = [LFXHSBKColor colorWithHue:(starthue*360) saturation:saturation brightness:brightness];
   // NSLog(@"starting hue:%f  ",starthue);
    
   // LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    //[localNetworkContext.allLightsCollection setColor:gLifxColor];
   // for (NSString *aDevID in self.vizInputLights)
   // {
    //    LFXLight *aLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
    //    [aLight setColor:gLifxColor];
   // }
    //setPowerState:LFXPowerStateOn
    


    saturation = 0.8;
    gIncrement = 0.001;

    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor blackColor]];
        emitterLayer = (CAEmitterLayer *)self.layer;
        
        CGFloat width = MIN(frame.size.width, frame.size.height);
        CGFloat height = MAX(frame.size.width, frame.size.height);
        NSLog(@"width:%f height:%f  ",width,height);
        emitterLayer.emitterPosition = CGPointMake(width/2, height/2);
        //emitterLayer.emitterSize = CGSizeMake(30, 30);
        emitterLayer.emitterSize = CGSizeMake(width-80, 60);
        emitterLayer.emitterShape = kCAEmitterLayerCircle;
        emitterLayer.renderMode = kCAEmitterLayerAdditive;
        
        cell = [CAEmitterCell emitterCell];
        cell.name = @"cell";
        
        childCell = [CAEmitterCell emitterCell];
        childCell.name = @"childCell";
        childCell.lifetime = 1.0f / 60.0f;
        childCell.birthRate = 60.0f;
        childCell.velocity = 0.0f;
        
        childCell.contents = (id)[[UIImage imageNamed:@"particle"] CGImage];
        
        cell.emitterCells = @[childCell];
        
        cell.color = [[UIColor colorWithRed:0.0f green:0.53f blue:1.0f alpha:0.8f] CGColor];
        
        
        cell.redRange = 0.46f;
        cell.greenRange = 0.49f;
        cell.blueRange = 0.67f;
        cell.alphaRange = 0.55f;
        
        cell.redSpeed = 0.11f;
        cell.greenSpeed = 0.07f;
        cell.blueSpeed = -0.25f;
        cell.alphaSpeed = 0.15f;
        
        cell.scale = 0.25f;
        cell.scaleRange = 0.25f;
        
        cell.lifetime = 1.0f;
        cell.lifetimeRange = .25f;
        cell.birthRate = 80;
        
        cell.velocity = 100.0f;
        cell.velocityRange = 300.0f;
        cell.emissionRange = M_PI * 2;
        
        emitterLayer.emitterCells = @[cell];
        
        dpLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        [dpLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
    }
    //LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];


    return self;
}

- (void)update
{
    
    float scale = 0.5;
    float calcBrightness = 1;
    //LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    
 
    if (vizRunOnce==FALSE)
    {
        vizRunOnce=TRUE;
        NSLog(@"vizInputLights:%@ ",self.vizInputLights);
        NSLog(@"vizInputLights2:%@ ",self.vizInputLights2);
     }
  
    if (stopFlag==TRUE)
    {
        
        CFRunLoopStop(CFRunLoopGetCurrent());
        NSLog(@"****attempting to stop*** ");
        //[dpLink removeFromRunLoop:(__CFRunLoop*)CFRunLoopGetCurrent() forMode:NSRunLoopCommonModes];
        [dpLink invalidate];
        dpLink = nil;
        
    }
   // NSLog(@"****update*** ");

    if (_audioPlayer.playing )
    {
        //----------------------------------------------------
        //--------- Update Colours ---------------------------

        _hue = (_hue + 0.1);if (_hue>360) _hue=1;
        saturation= saturation+gIncrement;
        if ( (saturation>0.9999)|| (saturation<0.5) )
        {
            gIncrement=gIncrement*(-1.0);
        }
        //----------------------------------------------------
        
        //NSLog(@"hue:%f  saturation:%f",hue,saturation);
      
        //------------ Update cell colour ------------------------------------------------------------------------
        cell.color = [[UIColor colorWithHue: _hue/360.0 saturation: saturation brightness: 1.0 alpha: 1.0]CGColor] ;
        //---------------------------------------------------------------------------------------------------------
       
        
        [_audioPlayer updateMeters];
        
        float power = 0.0f;
        for (int i = 0; i < [_audioPlayer numberOfChannels]; i++)
        {
            power += [_audioPlayer averagePowerForChannel:i];
        }
        power /= [_audioPlayer numberOfChannels];
        
        float level = meterTable.ValueAt(power);
       // NSLog(@"level:%f",level);
        
        //NSLog(@"update() Scaling   value is: %f ",self.sliderScaleValue);
        //NSLog(@"update() Threshold value is: %f ",self.sliderThresholdValue);
        
        scale = level * 5;

        level = level + self.sliderThresholdValue;
        calcBrightness = powf(level,self.sliderScaleValue);
        
        if (calcBrightness > 1.0)
        {
            //NSLog(@"CLIP DETECTED! calcBrightness:%f ",calcBrightness);
        }
        
        float clamped = CLAMP(calcBrightness,0,1);
        self.LevelValue = clamped;
        
        
        //NSLog(@"level:%f    scaled:%f   calcbrightness:%f   clamped:%f",level, scale, calcBrightness, clamped);
        
        gLifxColor = [LFXHSBKColor colorWithHue:(_hue) saturation:saturation brightness:clamped];

        /*
         //[localNetworkContext.allLightsCollection setColor:gLifxColor];
         for (NSString *aDevID in self.vizInputLights)
         {
         LFXLight *aLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
         [aLight setColor:gLifxColor];
         }
         */
  
      dispatch_async(dispatch_get_main_queue(),
        ^{
            for (LFXLight *aLight in self.vizInputLights2)
            {
                [aLight setColor:gLifxColor];
                //[aLight setPowerState:LFXPowerStateOn];
            }
        });

        
    }
    else
    {//TODO: Add use self.sliderThresholdValue as brightness when not playing.
        //NSLog(@"**** tone down *** ");
        //gLifxColor = [LFXHSBKColor colorWithHue:(starthue*360) saturation:saturation brightness:0.2];
        //LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
        //[localNetworkContext.allLightsCollection setColor:gLifxColor overDuration:2];
    }
    //NSLog(@"......emitter.....");
    [emitterLayer setValue:@(scale) forKeyPath:@"emitterCells.cell.emitterCells.childCell.scale"];
}

@end