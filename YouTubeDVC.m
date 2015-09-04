//
//  YouTubeDVC.m
//  LIFX Ambience
//
//  Created by alnaumf on 9/3/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import "YouTubeDVC.h"

@interface YouTubeDVC ()

@end

@implementation YouTubeDVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [super viewDidLoad];
    NSLog(@"%@", self.url);

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    //get screen and nav bar bounds for spacing
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenHeight = screenSize.height;
    CGFloat screenWidth = screenSize.width;
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat videoHeightOffset = (screenHeight - 280 - navigationBarHeight)/2;
    
    CGFloat x = screenWidth * 0.1;
    CGFloat y = (screenHeight-navigationBarHeight)*0.12;
    CGFloat width = screenWidth * 0.8;
    CGFloat height = (screenHeight-navigationBarHeight) * 0.7;
    
    NSLog(@"screen height - %f , nav bar height - %f , videoHeightOffset - %f", screenHeight, navigationBarHeight, videoHeightOffset);
    
    NSString *videoURL = self.url;
    NSString *videoHTML = [NSString stringWithFormat:@"\
                           <html><body>\
                           <embed src=\"%@\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"%f\" height=\"%f\">\
                           </embed>\
                           </body></html>", videoURL, width, height];
    
    
    CGRect videoFrame = CGRectMake(x, y, width, height);
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame: videoFrame];
    
    //webView.frame = CGRectOffset(webView.frame, 0, videoHeightOffset);
    webView.opaque = NO;
    webView.backgroundColor = [UIColor blackColor];
    
    
    [webView loadHTMLString: videoHTML baseURL: nil];
    [self.view addSubview: webView];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc]
                                    initWithTitle:@"Share"
                                    style:UIBarButtonItemStyleBordered
                                    target:self
                                    action:@selector(shareDocument:)];
    self.navigationItem.rightBarButtonItem = shareButton;
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
