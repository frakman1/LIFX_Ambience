//
//  UIImageResizing.h
//  LIFX Ambience
//
//  Created by alnaumf on 7/31/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


// Put this in UIImageResizing.h
@interface UIImage (Resize)
- (UIImage*)scaleToSize:(CGSize)size;
@end

@interface UIImageResizing : NSObject


@end
