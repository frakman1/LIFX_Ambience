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
#import "LARSBar.h"


@interface VizViewController : UIViewController <MPMediaPickerControllerDelegate, TableViewControllerDelegate>
{
    //UISlider *powerLevel;
      
}

@property (weak, nonatomic) IBOutlet UILabel *audioPlayerBackgroundLayer;

@property (weak, nonatomic) IBOutlet UISlider *currentTimeSlider;
@property (weak, nonatomic) IBOutlet UISlider *colourSlider;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *duration;
@property (weak, nonatomic) IBOutlet UILabel *timeElapsed;
@property (weak, nonatomic) IBOutlet UILabel *lblSongTitle;
@property (weak, nonatomic) IBOutlet MarqueeLabel *mlblSongTitle;
@property (weak, nonatomic) IBOutlet MarqueeLabel *mlblSongArtist;
@property (weak, nonatomic) IBOutlet UILabel *lbltitleBackground;

@property (weak, nonatomic) IBOutlet UIButton *btnnext;
@property (weak, nonatomic) IBOutlet UIButton *btnprevious;

@property (nonatomic, retain) IBOutlet UIToolbar  *toolbar;
@property (weak, nonatomic)   IBOutlet UIButton *btnRepeat;
@property (weak, nonatomic) IBOutlet UIButton *btnMixer;
@property (weak, nonatomic) IBOutlet UIButton *btnPlaylist;
@property (weak, nonatomic) IBOutlet UIButton *btnLock;


@property BOOL isPaused;
@property BOOL scrubbing;
@property BOOL colourizing;

@property (weak, nonatomic) IBOutlet LARSBar *powerLevel;
@property (weak, nonatomic) IBOutlet UIImageView *imgBox;
//@property (weak, nonatomic) IBOutlet UIButton *btnHelp;
@property (weak, nonatomic) IBOutlet UIButton *btnHelp2;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *barbtnHelp;
@property (weak, nonatomic) IBOutlet UIButton *btnAddMusic;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barbtnAddMusic;

@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet MPVolumeView *viewVolumeView;
//@property (weak, nonatomic) IBOutlet LARSBar *eqSlider;

@property (nonatomic) NSMutableArray *inputLights;
@property (atomic) NSMutableArray *inputLights2;


- (IBAction) barbtnSearchPressed:(UIBarButtonItem *)sender;
- (IBAction) btnnextPressed:(UIButton *)sender;
- (void) startPlaying;
- (IBAction) btnpreviousPressed:(UIButton *)sender;
- (IBAction)btnMixerPressed:(UIBarButtonItem *)sender;
- (IBAction)btnHelpPressed:(UIButton *)sender;
- (IBAction)btnLockPressed:(UIButton *)sender;


//TableViewController Delegate
-(void) ModalTableViewDidClickDone:(MPMediaItemCollection*)newPlaylist;
-(void) ModalTableViewDidClickCancel;
-(void) ModalTableViewDidSelectSong:(MPMediaItemCollection*)newPlaylist withSong:(int)index;


@end