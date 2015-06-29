//
//  MainViewController.m
//  LIFX Ambience
//
//  Created by alnaumf on 6/23/15.
//  Copyright (c) 2015 Fraksoft. All rights reserved.
//

#import "MainViewController.h"
#import <LIFXKit/LIFXKit.h>


@interface MainViewController () <LFXNetworkContextObserver, LFXLightCollectionObserver, LFXLightObserver>

@property (nonatomic) LFXNetworkContext *lifxNetworkContext;

@property (nonatomic) UIView *connectionStatusView;
@property (nonatomic) NSArray *lights;
@property (nonatomic) NSArray *taggedLightCollections;



@end

@implementation MainViewController


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        self.lifxNetworkContext = [LFXClient sharedClient].localNetworkContext;
        [self.lifxNetworkContext addNetworkContextObserver:self];
        [self.lifxNetworkContext.allLightsCollection addLightCollectionObserver:self];
    }
    return self;
}



- (BOOL) prefersStatusBarHidden {return YES;}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //[self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    //self.navigationController.navigationBar.shadowImage = [UIImage new];
    //self.navigationController.navigationBar.translucent = YES;}
    
    self.connectionStatusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
    self.connectionStatusView.backgroundColor = [UIColor redColor];
    self.connectionStatusView.layer.cornerRadius = self.connectionStatusView.frame.size.height / 2.0;
    self.connectionStatusView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    self.connectionStatusView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.connectionStatusView];



}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNavBar];
   // [self updateLights];
  //  [self updateTags];
}

- (void)updateNavBar
{
    BOOL isConnected = (self.lifxNetworkContext.connectionState == LFXConnectionStateConnected);
    //self.title = [NSString stringWithFormat:@"LIFX Ambience (%@)", isConnected ? @"connected" : @"searching"];
    self.connectionStatusView.backgroundColor = isConnected ? [UIColor greenColor] : [UIColor redColor];
}

- (void)updateLights
{
    self.lights = self.lifxNetworkContext.allLightsCollection.lights;
    //[self.tableView reloadData];
}



- (void)viewDidAppear:(BOOL)animated
{
    LFXHSBKColor* tmpColor = [LFXHSBKColor colorWithHue:(200) saturation:0.6 brightness:0.35];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    [localNetworkContext.allLightsCollection setColor:tmpColor];


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    //LFXHSBKColor* tmpColor = [LFXHSBKColor whiteColorWithBrightness:1  kelvin:3500];

}

#pragma mark - LFXNetworkContextObserver

- (void)networkContextDidConnect:(LFXNetworkContext *)networkContext
{
    NSLog(@"Network Context Did Connect");
    [self updateNavBar];
}

- (void)networkContextDidDisconnect:(LFXNetworkContext *)networkContext
{
    NSLog(@"Network Context Did Disconnect");
    [self updateNavBar];
}

- (void)networkContext:(LFXNetworkContext *)networkContext didAddTaggedLightCollection:(LFXTaggedLightCollection *)collection
{
    NSLog(@"Network Context Did Add Tagged Light Collection: %@", collection.tag);
    [collection addLightCollectionObserver:self];
    //[self updateTags];
}

- (void)networkContext:(LFXNetworkContext *)networkContext didRemoveTaggedLightCollection:(LFXTaggedLightCollection *)collection
{
    NSLog(@"Network Context Did Remove Tagged Light Collection: %@", collection.tag);
    [collection removeLightCollectionObserver:self];
    //[self updateTags];
}

#pragma mark - LFXLightCollectionObserver

- (void)lightCollection:(LFXLightCollection *)lightCollection didAddLight:(LFXLight *)light
{
    NSLog(@"Light Collection: %@ Did Add Light: %@", lightCollection, light);
    [light addLightObserver:self];
    [self updateLights];
    [self updateNavBar];
}

- (void)lightCollection:(LFXLightCollection *)lightCollection didRemoveLight:(LFXLight *)light
{
    NSLog(@"Light Collection: %@ Did Remove Light: %@", lightCollection, light);
    [light removeLightObserver:self];
    [self updateLights];
    [self updateNavBar];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

}


@end
