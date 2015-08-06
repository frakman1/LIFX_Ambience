

#import "ANPopoverView.h"

@implementation ANPopoverView {
    UILabel *textLabel;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.font = [UIFont boldSystemFontOfSize:15.0f];
        
        UIImageView *popoverView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bubble"]];
        [self addSubview:popoverView];
        
        textLabel = [[UILabel alloc] init];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.font = self.font;
        textLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.7];
        textLabel.text = self.text;
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.frame = CGRectMake(0, -2.0f, popoverView.frame.size.width, popoverView.frame.size.height);
        [self addSubview:textLabel];
        
    }
    return self;
}

-(void)setValue:(float)aValue {
    _value = aValue;
    self.text = [NSString stringWithFormat:@"%4.2f", _value];
    textLabel.text = self.text;
    [self setNeedsDisplay];
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
