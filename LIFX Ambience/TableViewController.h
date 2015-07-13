//
//  TableViewController.h
//  drivePod_foriOs5
//
//  Created by Christopher on 3/13/12.
//  Copyright (c) 2012, 2013 Christopher Olsen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface TableViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>


@property (nonatomic, assign) id    delegate;
@property (nonatomic, retain) MPMediaItemCollection* playlist;
@property (nonatomic, retain) IBOutlet UITableView*  theTableView;
@property (nonatomic, retain) UIToolbar*             theToolbar;

- (IBAction)clickSave:(id)sender;
- (IBAction)clickCancel:(id)sender;

@end



@protocol TableViewControllerDelegate <NSObject>

-(void) ModalTableViewDidClickDone:(MPMediaItemCollection*)newPlaylist;
-(void) ModalTableViewDidClickCancel;

@end
