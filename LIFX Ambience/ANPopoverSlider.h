

#import <UIKit/UIKit.h>

#import "ANPopoverView.h"

@interface ANPopoverSlider : UISlider

@property (strong, nonatomic) ANPopoverView *popupView;

@property (nonatomic, readonly) CGRect thumbRect;

@end

