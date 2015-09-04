


//
//  YouTubeTVC.m
//  LIFX Ambience
//
//  Created by alnaumf on 9/3/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import "YouTubeTVC.h"
#import "YouTubeDVC.h"
#import <LIFXKit/LIFXKit.h>
#import "UIImageAverageColorAddition.h"
#import "AppDelegate.h"


@interface YouTubeTVC ()
{
    NSMutableArray *videos;
}

@end

static NSString *const kAPIKey = @"AIzaSyALnerjNgondj40BfKE2YZlUCaoAOFVSCY";
static NSString *const kPlaylistID = @"PLeRz-61h_e8lAiYFT7k9Elxuw9RhT6TV0";
static NSString *const kParts = @"playlistItems?part=snippet&playlistId=";
static NSString *const kParts2 = @"search?part=snippet&maxResults=10&q=";
//static NSString *const kSearchq = @"screen+color+test";

static NSString *const baseVideoURL = @"https://www.youtube.com/watch?v=";


//https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=20&q=dr+who&key={YOUR_API_KEY}

@implementation YouTubeTVC

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //NSLog(@"***Overriding orientation.");
   // NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
   // [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    
    // init the search bar
    self.mySearchBar = [[UISearchBar alloc] init];
    self.mySearchBar.delegate = self;
    self.mySearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    //self.mySearchBar.placeholder = NSLocalizedString(@"Search", @"Search");

    self.searchString = [[NSMutableString alloc] initWithFormat:@"Monitor+Color+Test+/+Monitor-Farbtest"];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.separatorColor = [UIColor clearColor];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                   ^{
                       [self searchWithString:self.searchString];
                       
                       // dispatch_async(dispatch_get_main_queue(),
                       // ^{
                       
                       //  });//main queue
                       
                   });//background queue
    

    
    


    
}

- (void) searchWithString:(NSMutableString *)searchString
{
    NSString *urlString = [NSString stringWithFormat:@"%@%@%@&type=video&key=%@", @"https://www.googleapis.com/youtube/v3/", kParts2, searchString, kAPIKey];
    NSLog(@"%@",urlString);
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
    NSString *jsonString = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUnicodeStringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingAllowFragments error:nil];
    NSLog(@"jsonDict:%@",jsonDict);
    videos = [NSMutableArray arrayWithArray:[jsonDict valueForKey:@"items"]];NSLog(@"videos:%@",videos);
    
     dispatch_async(dispatch_get_main_queue(),
     ^{
         [self.tableView reloadData];
     });//main queue
    
    
    
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
    
    NSURL *url = [[NSURL alloc] initWithString:thumbnailImage];
    NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
    cell.imageView.image = [UIImage imageWithData:imageData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
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
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   //NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSLog(@"indexPath %@",indexPath);
    //NSDictionary *video = [videos[indexPath.row] valueForKey:@"snippet"];
    
    //NSDictionary *content = [video valueForKey:@"resourceId"];NSLog(@"content %@",content);
    NSDictionary *id = [videos[indexPath.row] valueForKey:@"id"];NSLog(@"id %@",id);
    NSString *videoId = [id valueForKeyPath:@"videoId"];NSLog(@"videoId %@",videoId);
    NSString *url = [NSString stringWithFormat:@"%@%@", baseVideoURL, videoId];NSLog(@"url %@",url);
    
    
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        if (video)
        {
            //NSLog(@"vidtimer:%@",vidtimer);
            
            // Do something with the `video` object
            //if (vidtimer==nil)
            {
                
            //vidtimer = [NSTimer scheduledTimerWithTimeInterval: 0.2 target: self selector:@selector(myvidTick:) userInfo: nil repeats:YES];
            }
            
            self.VidPlayer = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:videoId];
            
            [self presentMoviePlayerViewControllerAnimated:self.VidPlayer];
           
        }
        else
        {
            // Handle error
            NSLog(@"***ERROR LOADING VIDEO ***");
        }
    }];
   
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
    [super viewWillDisappear:animated];
    NSLog(@"***viewWillDisappear***");
//    [self resignFirstResponder];
}


- (BOOL) shouldAutorotate
{
    return NO;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


/*- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
     NSLog(@"searchBarTextDidBeginEditing ");
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"Cancel clicked");
}
*/

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"searchBarSearchButtonClicked ");

    [searchBar resignFirstResponder];
    
    [self.searchString setString: searchBar.text];
    
    NSString* temp = [self.searchString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    [self.searchString setString:temp];
    
     NSLog(@"after: %@",self.searchString);
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
    ^{
        [self searchWithString:self.searchString];
        
     });//background queue

    
    
    
    
    
}

@end

