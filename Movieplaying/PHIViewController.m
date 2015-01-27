//
//  PHIViewController.m
//  Movieplaying
//
//  Created by Philipp Kuecuekyan on 8/9/14.
//  Copyright (c) 2014 phi & co. All rights reserved.
//

#import "PHIViewController.h"
#import "PHIVideoPlayerView.h"
#import "UIView+ConstraintHelper.h"

@interface PHIViewController ()
@property (nonatomic, strong) PHIVideoPlayerView *player;
@end

@implementation PHIViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Big Buck Bunny";
    self.view.backgroundColor = [UIColor whiteColor];

    [self preparePlayerWithURL:[NSURL URLWithString:@"http://content.uplynk.com/468ba4d137a44f7dab3ad028915d6276.m3u8"]];
}

#pragma mark - PHIVideoPlayerView preparation and setup

- (void)preparePlayerWithURL:(NSURL*)url {
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityView startAnimating];
    activityView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:activityView];
    [activityView centerInSuperview];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    [asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"duration"] completionHandler:^{
        NSError *error = nil;
        switch ([asset statusOfValueForKey:@"duration" error:&error]) {
            case AVKeyValueStatusLoaded:
                [activityView stopAnimating];
                [activityView removeFromSuperview];
                [self setupAndStartPlaying:asset.URL];
                break;
            default:
                NSLog(@"%s: %@", __func__, [error localizedDescription]);
                break;
        }
        
    }];

}
- (void)setupAndStartPlaying:(NSURL*)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupPlayer:url];
        [self.player play];
    });
}

- (void)setupPlayer:(NSURL*)url {

    // Create video player
    PHIVideoPlayerView *aPlayer;
    aPlayer = [[PHIVideoPlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) contentURL:url];
    aPlayer.shouldShowHideParentNavigationBar = YES;
    aPlayer.tintColor = [UIColor redColor];
    [self.view addSubview:aPlayer];
    aPlayer.translatesAutoresizingMaskIntoConstraints = NO;

    // Overwrite 'sound off,' when vibrate switch is toggled on phone
    aPlayer.shouldPlayAudioOnVibrate = YES;
    
    // Add constraints
    CGFloat maxDimension = MAX(self.view.frame.size.width, self.view.frame.size.height);
    [aPlayer constrainWithinSuperviewBounds];
    [aPlayer addConstraint:[aPlayer aspectConstraint:(16.0f / 9.0f)]];
    [aPlayer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[aPlayer(>=theWidth@750)]" options:0 metrics:@{@"theWidth":[NSNumber numberWithFloat:maxDimension]} views:NSDictionaryOfVariableBindings(aPlayer)]];
    [aPlayer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[aPlayer(>=theHeight@750)]" options:0 metrics:@{@"theHeight":[NSNumber numberWithFloat:maxDimension]} views:NSDictionaryOfVariableBindings(aPlayer)]];
    [aPlayer centerInSuperview];

    self.player = aPlayer;
}


@end
