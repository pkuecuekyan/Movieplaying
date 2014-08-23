//
//  PHIVideoPlayerView.m
//
//
//  Created by Philipp Kuecuekyan on 8/9/14.
//  Copyright (c) 2014 phi & co. All rights reserved.
//

#import "PHIVideoPlayerView.h"
#import "UIView+ConstraintHelper.h"

@interface PHIVideoPlayerView ()
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIView *airPlayStatusView;
@property (nonatomic, strong) id playbackObserver;

@property (assign, nonatomic) BOOL isViewShowing;
@end

@implementation PHIVideoPlayerView

#pragma mark - AVPlayerLayer setup

+ (Class)layerClass {
	return [AVPlayerLayer class];
}

- (AVPlayer*)player {
	return [(AVPlayerLayer*)[self layer] player];
}

- (void)setPlayer:(AVPlayer*)player {
	[(AVPlayerLayer*)[self layer] setPlayer:player];
}

- (void)setVideoFillMode:(NSString *)fillMode {
	AVPlayerLayer *playLayer = (AVPlayerLayer*)[self layer];
	playLayer.videoGravity = fillMode;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.shouldShowHideParentNavigationBar) {
        if ([[self superviewNavigationController] isNavigationBarHidden] && (UIInterfaceOrientationIsPortrait([UIDevice currentDevice].orientation))) {
            [[self superviewNavigationController] setNavigationBarHidden:NO animated:YES];
        }
    }
}

#pragma mark - Initializers/deallocator

- (instancetype)initWithFrame:(CGRect)frame playerItem:(AVPlayerItem*)aPlayerItem {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupPlayerWithPlayerItem:aPlayerItem forFrame:frame];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame contentURL:(NSURL*)contentURL {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupPlayerWithURL:contentURL forFrame:frame];
    }
    return self;
}

-(void)dealloc {
    
    [self.moviePlayer removeTimeObserver:self.playbackObserver];
    [self unregisterObservers];
}

#pragma mark - Player setup methods

- (void)setupPlayerWithURL:(NSURL*)theURL forFrame:(CGRect)aFrame {
    
    if (self.contentURL) {
        self.contentURL = nil;
    }
    
    AVPlayerItem *aPlayerItem = [AVPlayerItem playerItemWithURL:theURL];
    self.contentURL = theURL;
    [self setupPlayerWithPlayerItem:aPlayerItem forFrame:aFrame];
}

- (void)setupPlayerWithPlayerItem:(AVPlayerItem*)aPlayerItem forFrame:(CGRect)aFrame{
    
    // defensively remote observers, notifications
    [self unregisterObservers];
    
    if (self.moviePlayer) {
        self.moviePlayer = nil;
    }
    if (self.playerLayer) {
        self.playerLayer = nil;
    }
    if (self.playerItem) {
        self.playerItem = nil;
    }
    
    _playerItem = aPlayerItem;
    self.moviePlayer = [AVPlayer playerWithPlayerItem:self.playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.moviePlayer];
    [self.playerLayer setFrame:aFrame];
    [self.moviePlayer seekToTime:kCMTimeZero];
    [self setPlayer:self.moviePlayer];
    [self setVideoFillMode:AVLayerVideoGravityResizeAspect];
    self.contentURL = nil;
    
    [self registerObservers];
    [self initializePlayerAtFrame:aFrame];
  
}

-(void) setFrame:(CGRect)frame {
    
    [super setFrame:frame];
    [self.playerLayer setFrame:frame];

}


#pragma mark - Player UI setup

-(void)initializePlayerAtFrame:(CGRect)frame {
    
    int playerFrameWidth =  frame.size.width;
    int playerFrameHeight = frame.size.height;
    
    self.backgroundColor = [UIColor blackColor];
    self.isViewShowing =  NO;
    
    [self.layer setMasksToBounds:YES];
    
    self.playerHudBottom = [[UIView alloc] init];
    self.playerHudBottom.frame = CGRectMake(0, 0, playerFrameWidth, 25);
    [self.playerHudBottom setBackgroundColor:[UIColor colorWithRed:127.0f/255.0f green:127.0f/255.0f blue:127.0f/255.0f alpha:0.5f]];
    [self addSubview:self.playerHudBottom];
    
    //  Play/pause button
    self.playPauseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.playPauseButton.frame = CGRectMake(5*playerFrameWidth/240, 6*playerFrameHeight/160, 16*playerFrameWidth/240, 16*playerFrameHeight/160);
    [self.playPauseButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.playPauseButton setSelected:NO];
    [self.playPauseButton setBackgroundImage:[UIImage imageNamed:@"PlayerView.bundle/playback_pause"] forState:UIControlStateSelected];
    [self.playPauseButton setBackgroundImage:[UIImage imageNamed:@"PlayerView.bundle/playback_play"] forState:UIControlStateNormal];
    [self.playPauseButton setTintColor:[UIColor clearColor]];
    self.playPauseButton.layer.opacity = 0;
    [self addSubview:self.playPauseButton];
    
    //  Progress bar = scrubber
    self.progressBar = [[UISlider alloc] init];
    self.progressBar.frame = CGRectMake(0, 0, playerFrameWidth, 15);
    [self.progressBar addTarget:self action:@selector(progressBarChanged:) forControlEvents:UIControlEventValueChanged];
    [self.progressBar addTarget:self action:@selector(progressBarChangeEnded:) forControlEvents:UIControlEventTouchUpInside];
    [self.playerHudBottom addSubview:self.progressBar];

    // Calculate appropriately sized font
    CGFloat maxFontSize = MIN(12 * playerFrameWidth/240, 15.0);
    
    //  Current time label
    self.playBackTime = [[UILabel alloc] init];
    [self.playBackTime sizeToFit];
    self.playBackTime.text = [self getStringFromCMTime:self.moviePlayer.currentTime];
    [self.playBackTime setTextAlignment:NSTextAlignmentLeft];
    [self.playBackTime setTextColor:[UIColor whiteColor]];
    self.playBackTime.font = [UIFont systemFontOfSize:maxFontSize];
    [self.playerHudBottom addSubview:self.playBackTime];
    
    //  Total time label
    self.playBackTotalTime = [[UILabel alloc] init];
    [self.playBackTotalTime sizeToFit];
    self.playBackTotalTime.text = [self getStringFromCMTime:self.moviePlayer.currentItem.asset.duration];
    [self.playBackTotalTime setTextAlignment:NSTextAlignmentRight];
    [self.playBackTotalTime setTextColor:[UIColor whiteColor]];
    self.playBackTotalTime.font = [UIFont systemFontOfSize:maxFontSize];
    [self.playerHudBottom addSubview:self.playBackTotalTime];
    
    //  AirPlay button
    self.airplayButton = [[MPVolumeView alloc] init];
    [self.airplayButton setShowsVolumeSlider:NO];
    [self.airplayButton sizeToFit];
    [self.playerHudBottom addSubview:self.airplayButton];
    
    CMTime interval = CMTimeMake(33, 1000);
    __weak __typeof(self) weakself = self;
    _playbackObserver = [self.moviePlayer addPeriodicTimeObserverForInterval:interval queue:dispatch_get_main_queue() usingBlock: ^(CMTime time) {
        CMTime endTime = CMTimeConvertScale (weakself.moviePlayer.currentItem.asset.duration, weakself.moviePlayer.currentTime.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
        if (CMTimeCompare(endTime, kCMTimeZero) != 0) {
            double normalizedTime = (double) weakself.moviePlayer.currentTime.value / (double) endTime.value;
            weakself.progressBar.value = normalizedTime;
        }
        weakself.playBackTime.text = [weakself getStringFromCMTime:weakself.moviePlayer.currentTime];
    }];
    
    [self setupConstraints];
    [self showHUD:NO];
    [self showLoader:NO];
    
    // check for AirPlay with slight delay
    float statusDelay = 1.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(statusDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.airplayButton.wirelessRouteActive) {
            [self showAirPlayIconWithOutputName:[self activeAirPlayOutputRouteName]];
        }

    });
 }

#pragma mark - AutoLayout setup

-(void) setupConstraints {
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.playPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.airplayButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.playerHudBottom.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.playBackTime.translatesAutoresizingMaskIntoConstraints = NO;
    self.playBackTotalTime.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Player HUD
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.playerHudBottom
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.playerHudBottom
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.superview
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:1.0
                                                      constant:30.0]];
    
    [self addConstraints:[NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|-0-[hudBottom(>=300@1000)]-0-|"
                          options:0
                          metrics:nil
                          views:@{@"hudBottom": self.playerHudBottom }]];
    
    // Play button
    [self.playPauseButton centerInSuperview];
    
    // currentTime, progress bar, totalTime
    NSDictionary *hudMetrics = @{@"maxWidth":[NSNumber numberWithFloat:MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)],
                                 @"airplayButtonWidth": [NSNumber numberWithFloat:self.airplayButton.frame.size.width]};
    NSDictionary *hudViews = @{@"progressBar": self.progressBar,
                               @"playBackTime": self.playBackTime,
                               @"playBackTotal": self.playBackTotalTime,
                               @"airplayButton": self.airplayButton};
    [self.playerHudBottom addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|-5-[playBackTime]-[progressBar(<=maxWidth)]-[playBackTotal]-[airplayButton(==airplayButtonWidth)]-5-|"
                                          options:0
                                          metrics:hudMetrics
                                          views:hudViews]];
    [self.playerHudBottom addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[airplayButton(==airplayButtonHeight@750)]" options:0 metrics:@{@"airplayButtonHeight":[NSNumber numberWithFloat:self.airplayButton.frame.size.height]} views:@{@"airplayButton": self.airplayButton}]];
    
    [self.airplayButton centerVerticallyInSuperview];
    [self.playBackTotalTime centerVerticallyInSuperview];
    [self.playBackTime centerVerticallyInSuperview];
    [self.progressBar centerVerticallyInSuperview];
    
//    DLog(@"%s: Auto Layout constraints = %@ %@", __func__, self.constraints, self.playerHudBottom.constraints);
    
}


-(void)playerFinishedPlaying {
    
    [self.moviePlayer pause];
    [self.moviePlayer seekToTime:kCMTimeZero];
    [self.playPauseButton setSelected:NO];
    self.isPlaying = NO;
    if ([self.delegate respondsToSelector:@selector(playerFinishedPlayback:)]) {
        [self.delegate playerFinishedPlayback:self];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    CGPoint point = [(UITouch*)[touches anyObject] locationInView:self];
    if (CGRectContainsPoint(self.playerLayer.frame, point)) {
        [self showHUD:!self.isViewShowing];
    }
}

-(void) showHUD:(BOOL)show {
    
    __weak __typeof(self) weakself = self;
    if (show) {
        CGRect frame = self.playerHudBottom.frame;
        frame.origin.y = self.bounds.size.height;
        
        [UIView animateWithDuration:0.3 animations:^{
            weakself.playerHudBottom.frame = frame;
            weakself.playPauseButton.layer.opacity = 0;
            self.isViewShowing = show;
        }];
    } else {
        CGRect frame = self.playerHudBottom.frame;
        frame.origin.y = self.bounds.size.height - self.playerHudBottom.frame.size.height;
        
        [UIView animateWithDuration:0.3 animations:^{
            weakself.playerHudBottom.frame = frame;
            weakself.playPauseButton.layer.opacity = 1;
            self.isViewShowing = show;
        }];
        
    }
    
    // show/hide parentViewController's navigationBar alongside HUD
    
    if (self.shouldShowHideParentNavigationBar) {
        if (UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            [[self superviewNavigationController] setNavigationBarHidden:_isViewShowing animated:YES];
        }
    }
}

- (UINavigationController*)superviewNavigationController {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        
        if ([nextResponder isKindOfClass:[UINavigationController class]])
        {
            return (UINavigationController*)nextResponder;
        }

    }
    
    return nil;
}

#pragma mark - Time convenience methods

-(NSString*)getStringFromCMTime:(CMTime)time
{
    Float64 currentSeconds = CMTimeGetSeconds(time);
    int mins = currentSeconds/60.0;
    int secs = fmodf(currentSeconds, 60.0);
    NSString *minsString = mins < 10 ? [NSString stringWithFormat:@"0%d", mins] : [NSString stringWithFormat:@"%d", mins];
    NSString *secsString = secs < 10 ? [NSString stringWithFormat:@"0%d", secs] : [NSString stringWithFormat:@"%d", secs];
    return [NSString stringWithFormat:@"%@:%@", minsString, secsString];
}

#pragma mark - Play/pause button handling

-(void)playButtonAction:(UIButton*)sender {
    
    if (self.isPlaying) {
        [self pause];
    } else {
        [self play];
    }
}

#pragma mark - ProgressBar change handling

-(void)progressBarChanged:(UISlider*)sender {
    
    if (self.isPlaying) {
        [self.moviePlayer pause];
    }
    CMTime seekTime = CMTimeMakeWithSeconds(sender.value * (double)self.moviePlayer.currentItem.asset.duration.value/(double)self.moviePlayer.currentItem.asset.duration.timescale, self.moviePlayer.currentTime.timescale);
    [self.moviePlayer seekToTime:seekTime];
}

-(void)progressBarChangeEnded:(UISlider*)sender {
    
    if (self.isPlaying) {
        [self.moviePlayer play];
    }
}

-(void)play {
    
    [self.moviePlayer play];
    self.isPlaying = YES;
    [self.playPauseButton setSelected:YES];
}

-(void)pause {
    
    [self.moviePlayer pause];
    self.isPlaying = NO;
    [self.playPauseButton setSelected:NO];
}

- (void)endPlayer {
    
    [self.moviePlayer pause];
    self.moviePlayer.rate = 0.0;
    self.isPlaying = NO;
    [self.playerLayer removeFromSuperlayer];
    self.moviePlayer = nil;
}


#pragma mark - ActivityIndicator show/hide

- (void)showLoader:(BOOL)wasInterrupted {
    
    if (!self.activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self.activityIndicator startAnimating];
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.activityIndicator];
    
        if (!wasInterrupted) {
            self.playPauseButton.alpha = 0.0;
        }
        [self.activityIndicator centerInSuperview];
        
    }
}

- (void)removeLoader {
    [UIView animateWithDuration:0.5 animations:^{
        self.playPauseButton.alpha = 1.0;
        self.activityIndicator.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.activityIndicator stopAnimating];
        [self.activityIndicator removeFromSuperview];
        self.activityIndicator = nil;
    }];
 
}

#pragma mark - AirPlay notification and functionality


- (NSString*)activeAirPlayOutputRouteName
{
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription* currentRoute = audioSession.currentRoute;
    for (AVAudioSessionPortDescription* outputPort in currentRoute.outputs){
        if ([outputPort.portType isEqualToString:AVAudioSessionPortAirPlay])
            return outputPort.portName;
    }
    
    return nil;
}

- (void)audioRouteHasChangedNotification:(NSNotification*)notification {
    NSString *airPlayOutputRouteName = [self activeAirPlayOutputRouteName];
    DLog(@"%s: %@; outputRoute = %@",__func__, notification, airPlayOutputRouteName);
    
    if (airPlayOutputRouteName) {
        [self showAirPlayIconWithOutputName:airPlayOutputRouteName];
    } else {
        if (self.airPlayStatusView) {
            [self removeAirPlayIcon];
        }
    }
    
}

- (void)airplayAvailabilityHasChangedNotification:(NSNotification*)notification {
    DLog(@"%s: %@",__func__, notification);
    
}

- (void)showAirPlayIconWithOutputName:(NSString*)outputName {
    if (self.airPlayStatusView) {
        [self.airPlayStatusView removeFromSuperview];
        self.airPlayStatusView = nil;
    }
    
    _airPlayStatusView = [[UIView alloc] init];
    self.airPlayStatusView.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageView *airPlayIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PlayerView.bundle/playback_airplay"]];
    airPlayIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.airPlayStatusView addSubview:airPlayIcon];
    UILabel *airplayDeviceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 125.0, 25.0)];
    airplayDeviceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    airplayDeviceLabel.font = [UIFont systemFontOfSize:15.0];
    airplayDeviceLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    airplayDeviceLabel.text = [NSString stringWithFormat:@"Playing on %@",outputName];
    [self.airPlayStatusView addSubview:airplayDeviceLabel];
    [self addSubview:self.airPlayStatusView];
    [airPlayIcon centerHorizontallyInSuperview];
    [airplayDeviceLabel centerHorizontallyInSuperview];
    
    CGFloat maxDimension = MIN(self.frame.size.width, self.frame.size.height);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[airPlayStatusView(<=theWidth@750)]" options:0 metrics:@{@"theWidth":[NSNumber numberWithFloat:maxDimension]} views:@{@"airPlayStatusView":self.airPlayStatusView}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[airPlayStatusView(<=theHeight@750)]" options:0 metrics:@{@"theHeight":[NSNumber numberWithFloat:maxDimension]} views:@{@"airPlayStatusView":self.airPlayStatusView}]];
    [airPlayIcon addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[airplayIcon(40)]" options:0 metrics:0 views:@{@"airplayIcon":airPlayIcon}]];
    [self.airPlayStatusView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(<=10,>=5@750)-[airplayIcon(40)]-(55@750)-[airplayDeviceLabel]-(<=40,>=20@750)-|" options:0 metrics:nil views:@{@"airplayIcon":airPlayIcon, @"airplayDeviceLabel":airplayDeviceLabel}]];
    [self.airPlayStatusView centerInSuperview];
}

- (void)removeAirPlayIcon {
    if (self.airPlayStatusView) {
        [UIView animateWithDuration:0.5 animations:^{
            self.airPlayStatusView.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) {
                [self.airPlayStatusView removeFromSuperview];
                self.airPlayStatusView = nil;
            }
        }];
    }
}

#pragma mark - Observer handling for player, playerItem

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[AVPlayerItem class]])
    {
        AVPlayerItem *item = (AVPlayerItem *)object;

        //playerItem status value changed?
        if ([keyPath isEqualToString:@"status"])
        {
            // if yes, determine it...
            switch(item.status)
            {
                case AVPlayerItemStatusFailed:
                    DLog(@"%s: player item status failed", __func__);
                    break;
                case AVPlayerItemStatusReadyToPlay:
                    DLog(@"%s: player item status is ready to play", __func__);
                    [self removeLoader];
                    break;
                case AVPlayerItemStatusUnknown:
                    DLog(@"%s: player item status is unknown", __func__);
                    break;
            }
        }
        else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
        {
            if (item.playbackBufferEmpty)
            {
                if (!item.isPlaybackLikelyToKeepUp && !item.isPlaybackBufferFull) {
                    
                    // perform secondary check that player has actually stopped
                    if (self.moviePlayer.rate == 0.0) {
                        [self showLoader:YES];
                    }
                }
                DLog(@"%s: player item playback buffer is empty", __func__);
            }
        }
    }
    if ([object isKindOfClass:[AVPlayer class]]) {
        
        // secondary check on activityIndicator, remove shown && framerate > 0.0
        if ([keyPath isEqual:@"rate"]) {
            CGFloat frameRate = [(AVPlayer*)object rate];
            if (frameRate > 0.0 && self.activityIndicator) {
                [self removeLoader];
            }
            DLog(@"%s: player rate is %f", __func__, [(AVPlayer*)object rate]);
        }
    }
}

#pragma mark - KVO of Player notifications, setup/teardown

- (void)registerObservers {
    
    // monitor playhead position if reached end
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFinishedPlaying) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];

    // monitor audio output (AirPlay)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteHasChangedNotification:) name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];

    // monitor AirPlay availability (via MPVolumeView)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airplayAvailabilityHasChangedNotification:) name:MPVolumeViewWirelessRouteActiveDidChangeNotification object:self];
    
    // monitor playerItem status (ready to play, failed; buffer)
	for (NSString *keyPath in [self observablePlayerItemKeypaths]) {
		[self.playerItem addObserver:self forKeyPath:keyPath options:0 context:NULL];
	}
    
    // monitor player frame rate
    [self.player addObserver:self forKeyPath:@"rate" options:0 context:NULL];
    
}

- (void)unregisterObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	for (NSString *keyPath in [self observablePlayerItemKeypaths]) {
        [self.playerItem removeObserver:self forKeyPath:keyPath];
	}
    
    [self.player removeObserver:self forKeyPath:@"rate"];
}

- (NSArray *)observablePlayerItemKeypaths {
	return [NSArray arrayWithObjects:@"playbackBufferEmpty", @"status", nil];
}

@end
