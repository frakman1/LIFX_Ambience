//
//  VizViewController.h
//  LIFX Ambience
//
//  Created by alnaumf on 6/23/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#include "FSAudioPlayer.h"
#import "TableViewController.h"
#import "MarqueeLabel.h"


@interface VizViewController : UIViewController <MPMediaPickerControllerDelegate, TableViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *audioPlayerBackgroundLayer;

@property (weak, nonatomic) IBOutlet UISlider *currentTimeSlider;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *duration;
@property (weak, nonatomic) IBOutlet UILabel *timeElapsed;
@property (weak, nonatomic) IBOutlet UILabel *lblSongTitle;
@property (weak, nonatomic) IBOutlet MarqueeLabel *mlblSongTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblSongArtist;
@property (weak, nonatomic) IBOutlet UILabel *lbltitleBackground;

@property (weak, nonatomic) IBOutlet UIButton *btnnext;
@property (weak, nonatomic) IBOutlet UIButton *btnprevious;

@property (nonatomic, retain) IBOutlet UIToolbar*   toolbar;

@property BOOL isPaused;
@property BOOL scrubbing;

- (IBAction)barbtnSearchPressed:(UIBarButtonItem *)sender;
- (IBAction) btnnextPressed:(UIButton *)sender;
- (void) startPlaying;
- (IBAction)btnpreviousPressed:(UIButton *)sender;



//TableViewController Delegate
-(void) ModalTableViewDidClickDone:(MPMediaItemCollection*)newPlaylist;
-(void) ModalTableViewDidClickCancel;

@end