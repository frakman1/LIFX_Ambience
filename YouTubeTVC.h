//
//  YouTubeTVC.h
//  LIFX Ambience
//
//  Created by alnaumf on 9/3/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCDYouTubeKit/XCDYouTubeKit.h>


@interface YouTubeTVC : UITableViewController <UISearchBarDelegate>

@property(nonatomic,strong)  XCDYouTubeVideoPlayerViewController* VidPlayer;
@property (nonatomic,strong) NSMutableString* searchString;

@property (strong,nonatomic) NSMutableArray *filteredVideosArray;
@property IBOutlet UISearchBar *mySearchBar;
@property (nonatomic) NSMutableArray *ytInputLights;
@end
