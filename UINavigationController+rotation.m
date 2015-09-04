//
//  UINavigationController+rotation.m
//  LIFX Ambience
//
//  Created by alnaumf on 9/3/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import "UINavigationController+rotation.h"

@implementation UINavigationController (rotation)


- (BOOL) shouldAutorotate
{
    NSLog(@"**OVERRIDE***");
    return [[self topViewController] shouldAutorotate];
}

- (NSUInteger) supportedInterfaceOrientations
{
    NSLog(@"**OVERRIDE***");
    return [[self topViewController] supportedInterfaceOrientations];
}

@end
