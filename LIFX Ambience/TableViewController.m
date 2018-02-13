//
//  TableViewController.m
//  drivePod_foriOs5
//
//  Created by Christopher on 3/13/12.
//  Copyright (c) 2012,2013 Christopher Olsen. All rights reserved.
//

#import "TableViewController.h"



@implementation TableViewController

@synthesize delegate, playlist, theTableView, theToolbar;


- (BOOL) prefersStatusBarHidden {return YES;}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self theTableView] setEditing:YES];
    self.theTableView.backgroundColor = [UIColor clearColor];
   // [self.theTableView setDelegate:self];
   // [self.theTableView setDataSource:self];

    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - TableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowsInSection = [playlist count];
    return rowsInSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    
    //get data for the cell
  
    NSString*songName = [[playlist.items objectAtIndex:[indexPath row]] valueForProperty:MPMediaItemPropertyTitle];
    NSString*artistName = [[playlist.items objectAtIndex:[indexPath row]] valueForProperty:MPMediaItemPropertyArtist];
    NSString*albumName = [[playlist.items objectAtIndex:[indexPath row]] valueForProperty:MPMediaItemPropertyAlbumTitle];
    [[cell textLabel] setText:[NSString stringWithFormat:@"%@", songName]];
    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@ - %@", albumName, artistName]];
    
    cell.showsReorderControl = YES;
    
    return cell;
} 


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}

/*
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    return @"Playlist";
}
*/
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel * sectionHeader = [[UILabel alloc] initWithFrame:CGRectZero] ;
    sectionHeader.backgroundColor = [UIColor clearColor];
    sectionHeader.textAlignment = UITextAlignmentCenter;
    sectionHeader.font = [UIFont boldSystemFontOfSize:15];
    sectionHeader.textColor = [UIColor whiteColor];
    
    switch(section) {
        //case 0:sectionHeader.text = @"TITLE ONE"; break;
        //case 1:sectionHeader.text = @"TITLE TWO"; break;
        default:sectionHeader.text = @"Playlist"; break;
    }
    return sectionHeader;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"Entering commitEditingStyle:%d [playlist.items count]:%d",editingStyle,[playlist.items count]);
    
    //***FRAK*** prevent a 0 length list. MediaPlayer allocation fails below otherwise.
    if ([playlist.items count] == 1) return;
    
    if (editingStyle == UITableViewCellEditingStyleDelete) 
    {
        NSMutableArray*newPlaylistArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [playlist.items count]; i++)
        {
            if (i != [indexPath row])
            {
                [newPlaylistArray addObject:[playlist.items objectAtIndex:i]];
            }
        }
        MPMediaItemCollection*newPlaylist = [[MPMediaItemCollection alloc] initWithItems:newPlaylistArray]; //make sure this is never an empty list
        playlist = newPlaylist;
        [theTableView reloadData];
        
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert)//should never happen
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    } 
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    // first of all, this method is at least twice as long as it needs to be, the two cases are really one,
    // just approached from different sides of the array.
    // second, it isn't entirely clear that this is *the* way to do this.  The issue is that the data is stored 
    // as a MPMediaItemCollection, which is 1)not mutable and 2) an Apple class that I don't want to mess with.
    // Since there isn't a method (that I know of) to move an object from here to there the entire thing needs to
    // be moved into a second container (NSMutableArray), then added back into a new MPMediaItemCollection.  Whether 
    // this should be done here, in the  ViewController class, or possibly in a different 'model' class to better 
    // follow the MVC paradigm is not entirely clear.  The current method is based on minimising the time the 
    // playlist is outside of its non-mutable apple-defined MPMediaItemCollection class, effectively quarantining
    // the break of the MVC ethic to this one method.
    
    NSMutableArray*newPlaylistArray = [[NSMutableArray alloc] init];
    
    //build the new list row by row based on moved item location/destination
    if ([fromIndexPath row] > [toIndexPath row])//moving an item to earlier in the list
    {
        int i;
        for (i = 0; i < ([toIndexPath row]); i++)
        {
            if (i != [toIndexPath row])
            {
                [newPlaylistArray addObject:[playlist.items objectAtIndex:i]];
            }
        }
        //insert the moved row    
        [newPlaylistArray addObject:[playlist.items objectAtIndex:[fromIndexPath row]]];
        int j;
        for (j = i + 1; j < [fromIndexPath row] + 1; j++)
        {
            [newPlaylistArray addObject:[playlist.items objectAtIndex:(j - 1)]];
        }
        for (int k = j; k < [playlist.items count]; k++)
        {
            [newPlaylistArray addObject:[playlist.items objectAtIndex:k]];
        }
    }
    else //moving an item to later in the list
    {
        int i;
        for (i = 0; i < ([fromIndexPath row]); i++)
        {
            [newPlaylistArray addObject:[playlist.items objectAtIndex:i]];
        }
        int j;
        for (j = i ; j < [toIndexPath row] ; j++)
        {
            [newPlaylistArray addObject:[playlist.items objectAtIndex:(j + 1)]];
        }
        //insert the moved row
        [newPlaylistArray addObject:[playlist.items objectAtIndex:[fromIndexPath row]]];
        for (int k = j + 1; k < [playlist.items count]; k++)
        {
            [newPlaylistArray addObject:[playlist.items objectAtIndex:k]];
        }
    }
    if ([newPlaylistArray count] > 0)
    {
        playlist = [[MPMediaItemCollection alloc] initWithItems:newPlaylistArray];
    }
    [theTableView reloadData];
}



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


#pragma mark - TableView Delegate

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MPMediaItem *item = [playlist.items objectAtIndex:[indexPath row]];
    NSLog(@"%ld - selected: %@",(long)[indexPath row],item.title);
    //[self.parentViewController dismissModalViewControllerAnimated:YES];
    [self.delegate ModalTableViewDidSelectSong:playlist withSong:(int)[indexPath row]];
}
/*
int index = 0;
for (MPMediaItem *i/Users/frak/Documents/XcodeProjects/LIFX Ambience/LIFX Ambience/TableViewController.htem in mymediaItemCollection.items)
{
    NSLog(@"%d) %@ - %@", index++, item.artist, item.title);
}
NSLog(@"index: %d",index);
*/


#pragma mark - Toolbar Buttons

- (IBAction)clickSave:(id)sender 
{
    [self.delegate ModalTableViewDidClickDone:playlist];
}

- (IBAction)clickCancel:(id)sender 
{
    [self.delegate ModalTableViewDidClickCancel];
}

- (IBAction)clickShuffle:(id)sender
{
    //[self.delegate ModalTableViewDidClickCancel];
    NSLog(@"Every Day I'm Shuff-a-ling");
    
    if (playlist.items.count<2) return;
    
    //MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view.window];
    //NSString *info = [NSString stringWithFormat:@"Shuffling"];
    //[hud setLabelText:info];
    //[hud setDetailsLabelText:@"Please wait..."];
    //[hud setDimBackground:YES];
    //[hud setOpacity:0.5f];
    //[hud show:YES];
    //[hud hide:YES afterDelay:3.0];
    
    NSMutableArray *tempPlayist = [[NSMutableArray alloc]initWithArray:playlist.items copyItems:TRUE]; 
    
    NSUInteger count = [tempPlayist count];
    for (NSUInteger i = 0; i < count - 1; ++i)
    {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [tempPlayist exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }

    playlist = [MPMediaItemCollection collectionWithItems:tempPlayist];
    
    [theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

}


@end


