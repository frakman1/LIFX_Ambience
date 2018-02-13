


//
//  YouTubeTVC.m
//  LIFX Ambience
//
//  Created by alnaumf on 9/3/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import "YouTubeTVC.h"
#import <LIFXKit/LIFXKit.h>
#import "UIImageAverageColorAddition.h"
#import "AppDelegate.h"
#import <SDWebImage/UIImageView+WebCache.h>



@interface YouTubeTVC ()
{
    NSMutableArray *videos;
    UIActivityIndicatorView *activityIndicator;
}

@end

static NSString *const kAPIKey = @"AIzaSyALnerjNgondj40BfKE2YZlUCaoAOFVSCY";
static NSString *const kPlaylistID = @"PLeRz-61h_e8lAiYFT7k9Elxuw9RhT6TV0";
static NSString *const kParts = @"playlistItems?part=snippet&playlistId=";
static NSString *const kParts2 = @"search?part=snippet&maxResults=50&regionCode=US&q=";
//static NSString *const kSearchq = @"screen+color+test";

static NSString *const baseVideoURL = @"https://www.youtube.com/watch?v=";


//https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=20&q=dr+who&key={YOUR_API_KEY}

@implementation YouTubeTVC


- (BOOL) prefersStatusBarHidden {return YES;}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
/*
    LFXHSBKColor* tmpColor = [LFXHSBKColor whiteColorWithBrightness:1  kelvin:3500];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    //[localNetworkContext.allLightsCollection setColor:tmpColor];
    NSLog(@"Received input lights list: %@",self.ytInputLights);
    for (NSString *aDevID in self.ytInputLights)
    {
        LFXLight *aLight = [localNetworkContext.allLightsCollection lightForDeviceID:aDevID];
        [aLight setColor:tmpColor overDuration:0.5];
    }
*/
    // !HACK ALERT! getting a reference to parent view controller to access its elements.
    MainViewController *parentViewController = (MainViewController*)[self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
    
    // Delay execution of block for 1 seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSLog(@"delayed operation...");
        
        [parentViewController restoreLightState];
        
    });


}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"***Overriding orientation.");
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.color = [UIColor blueColor];
    activityIndicator.center = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0);
    activityIndicator.transform = CGAffineTransformMakeScale(2, 2);
    [self.tableView addSubview: activityIndicator];
    
    dispatch_async(dispatch_get_main_queue(),
   ^{
       [activityIndicator startAnimating];
   });
    
    self.searchString = [[NSMutableString alloc] initWithFormat:@"Monitor+Color+Test+/+Monitor-Farbtest"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
   ^{
       [self searchWithString:self.searchString];
       
       // dispatch_async(dispatch_get_main_queue(),
       // ^{
       
       //  });//main queue
       
   });//background queue



    
    // init the search bar
    self.mySearchBar = [[UISearchBar alloc] init];
    self.mySearchBar.delegate = self;
    self.mySearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    //self.mySearchBar.placeholder = NSLocalizedString(@"Search", @"Search");

    
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.separatorColor = [UIColor clearColor];
    
}

- (void) searchWithString:(NSMutableString *)searchString
{
    videos=nil;
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@%@&type=video&key=%@", @"https://www.googleapis.com/youtube/v3/", kParts2, searchString, kAPIKey];
	    NSLog(@"%@",[urlString stringByReplacingOccurrencesOfString:kAPIKey withString:@"*******"]);
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    

    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data)
        {
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];  // note the retain count here.
            NSData *jsonData = [jsonString dataUsingEncoding:NSUnicodeStringEncoding];
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingAllowFragments error:nil];
            //NSLog(@"jsonDict:%@",jsonDict);
            videos = [NSMutableArray arrayWithArray:[jsonDict valueForKey:@"items"]];//NSLog(@"videos:%@",videos);
        }
        else
        {
            // handle error
            NSLog(@"Error connecting to server");
        }
        
        dispatch_async(dispatch_get_main_queue(),
       ^{
           if (videos) [activityIndicator stopAnimating];
           [self.tableView reloadData];
       });

    }];
    ////////////
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
     return videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 100;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    dispatch_async(dispatch_get_main_queue(),
    ^{
        if (videos) [activityIndicator stopAnimating];
    });

    
    NSDictionary *video = [videos[indexPath.row] valueForKey:@"snippet"];
    
    
    NSString *title = [video valueForKeyPath:@"title"];
    
    NSDictionary *thumbnails = [video valueForKey:@"thumbnails"];
    NSDictionary *thumbnailData = [thumbnails valueForKey:@"default"];
    NSString *thumbnailImage = [thumbnailData valueForKeyPath:@"url"];
    
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:15.0];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.text = title;
    if (!thumbnailImage) return;
    
    // This is the simple, straightforward way of doing it. No caching, sychronous, blocking. Amateur
    //NSURL *url = [[NSURL alloc] initWithString:thumbnailImage];
    //NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
    //cell.imageView.image = [UIImage imageWithData:imageData];
    
    // This is slightly better but no point reinventing the wheel.
    /*
    [[ImageCache sharedInstance] downloadImageAtURL:url completionHandler:^(UIImage *image) {
        cell.imageView.image = image;
        //[self.tableView reloadData];
        NSLog(@"cell size :%@",NSStringFromCGSize(cell.bounds.size));
    }];
     */
    
    //The best practice method."Everything will be handled for you, from async downloads to caching management."
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:thumbnailImage]
                      placeholderImage:[UIImage imageNamed:@"loading"]];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   //NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSLog(@"indexPath %@",indexPath);
    //NSDictionary *video = [videos[indexPath.row] valueForKey:@"snippet"];
    
    //NSDictionary *content = [video valueForKey:@"resourceId"];NSLog(@"content %@",content);
    NSDictionary *id = [videos[indexPath.row] valueForKey:@"id"];NSLog(@"id %@",id);
    NSString *videoId = [id valueForKeyPath:@"videoId"];NSLog(@"videoId %@",videoId);
    NSString *url = [NSString stringWithFormat:@"%@%@", baseVideoURL, videoId];NSLog(@"url %@",url);
    
    XCDYouTubeVideoPlayerViewController *videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:videoId];
    videoPlayerViewController.ytpInputLights = self.ytInputLights;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:videoPlayerViewController.moviePlayer];
    [self presentMoviePlayerViewControllerAnimated:videoPlayerViewController];

    

}

- (void) moviePlayerPlaybackDidFinish:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:notification.object];
    MPMovieFinishReason finishReason = [notification.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
    if (finishReason == MPMovieFinishReasonPlaybackError)
    {
        NSError *error = notification.userInfo[XCDMoviePlayerPlaybackDidFinishErrorUserInfoKey];
        // Handle error
         NSLog(@"*** ERROR LOADING VIDEO ***\n Error:%@",error);
    }
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/
- (void)didMoveToParentViewController:(UIViewController *)parent
{
    NSLog(@"%@",parent.title );
    if (![parent isEqual:self.parentViewController])
    {
        NSLog(@"Back pressed");
       // [vidtimer invalidate];
       // vidtimer = nil;
       // self.VidPlayer=nil;

    }
}

- (void)viewWillDisappear:(BOOL)animated {
    
    NSLog(@"***viewWillDisappear***");
//    [self resignFirstResponder];
    [super viewWillDisappear:animated];
}


- (BOOL) shouldAutorotate
{
    return NO;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
     NSLog(@"searchBarTextDidBeginEditing ");
    [searchBar setPlaceholder:@""];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"Cancel clicked");
     [searchBar setText:@""];
    [searchBar setPlaceholder:@"Search YouTube"];
    [searchBar resignFirstResponder];
}


-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"searchBarSearchButtonClicked ");

    [searchBar resignFirstResponder];
    
    [self.searchString setString: searchBar.text];
    
    NSString* temp = [self.searchString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    [self.searchString setString:temp];
    
     //NSLog(@"after: %@",self.searchString);
    
    dispatch_async(dispatch_get_main_queue(),
    ^{
            [activityIndicator startAnimating];
    });//main queue

    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
    ^{
        [self searchWithString:self.searchString];
        
     });//background queue


}

@end



/*
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
 
 NSDictionary *video = [videos[indexPath.row] valueForKey:@"snippet"];
 
 //NSDictionary *content = [video valueForKey:@"resourceId"];NSLog(@"content %@",content);
 NSDictionary *id = [videos[indexPath.row] valueForKey:@"id"];
 NSString *videoId = [id valueForKeyPath:@"videoId"];NSLog(@"videoId %@",videoId);
 NSString *url = [NSString stringWithFormat:@"%@%@", baseVideoURL, videoId];NSLog(@"url %@",url);
 
 //NSDictionary *content2 = [video valueForKeyPath:@"media$group.media$player"][0];
 //NSString *shareurl = [content2 valueForKeyPath:@"url"];
 
 YouTubeDVC *detailViewController = [segue destinationViewController];
 detailViewController.url = url;
 //detailViewController.shareurl = shareurl;
 
 }
 */

