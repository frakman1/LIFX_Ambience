//
//  UIView+HierarchyLogging.m
//  LIFX Ambience
//
//  Created by alnaumf on 7/25/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@implementation UIView (ViewHierarchyLogging)
- (void)logViewHierarchy
{
    NSLog(@"%@", self);
    for (UIView *subview in self.subviews)
    {
        [subview logViewHierarchy];
    }
}
@end