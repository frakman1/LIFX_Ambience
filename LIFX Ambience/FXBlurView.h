//
//  FXBlurView.h
//


#import <UIKit/UIKit.h>


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"


#import <Availability.h>
#undef weak_ref
#if __has_feature(objc_arc) && __has_feature(objc_arc_weak)
#define weak_ref weak
#else
#define weak_ref unsafe_unretained
#endif


@interface UIImage (FXBlurView)

- (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor;

@end


@interface FXBlurView : UIView

+ (void)setBlurEnabled:(BOOL)blurEnabled;
+ (void)setUpdatesEnabled;
+ (void)setUpdatesDisabled;

@property (nonatomic, getter = isBlurEnabled) BOOL blurEnabled;
@property (nonatomic, getter = isDynamic) BOOL dynamic;
@property (nonatomic, assign) NSUInteger iterations;
@property (nonatomic, assign) NSTimeInterval updateInterval;
@property (nonatomic, assign) CGFloat blurRadius;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, weak_ref) UIView *underlyingView;

- (void)updateAsynchronously:(BOOL)async completion:(void (^)())completion;

@end


#pragma GCC diagnostic pop

