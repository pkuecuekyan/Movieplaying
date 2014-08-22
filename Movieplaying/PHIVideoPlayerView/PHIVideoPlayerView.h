//
//  PHIVideoPlayerView.h
//
//
//  Created by Philipp Kuecuekyan on 8/9/14.
//  Copyright (c) 2014 phi & co. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#ifdef DEBUG
#    define DLog(...) NSLog(__VA_ARGS__)
#else
#    define DLog(...) /* */
#endif

@class PHIVideoPlayerView;

@protocol playerViewDelegate <NSObject>
@optional
-(void)playerViewZoomButtonClicked:(PHIVideoPlayerView*)view;
-(void)playerFinishedPlayback:(PHIVideoPlayerView*)view;

@end

@interface PHIVideoPlayerView : UIView

@property (assign, nonatomic) id <playerViewDelegate> delegate;
@property (retain, nonatomic) NSURL *contentURL;
@property (retain, nonatomic) AVPlayer *moviePlayer;

@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL shouldShowHideParentNavigationBar;

@property (retain, nonatomic) UIButton *playPauseButton;
@property (retain, nonatomic) MPVolumeView *airplayButton;

@property (retain, nonatomic) UISlider *progressBar;

@property (retain, nonatomic) UILabel *playBackTime;
@property (retain, nonatomic) UILabel *playBackTotalTime;

@property (retain,nonatomic) UIView *playerHudBottom;

-(instancetype)initWithFrame:(CGRect)frame contentURL:(NSURL*)contentURL;
-(instancetype)initWithFrame:(CGRect)frame playerItem:(AVPlayerItem*)playerItem;
-(void)play;
-(void)pause;
-(void)setupConstraints;

@end

//  Forked from KSVideoPlayView, portions (c) 2014 Mike, mikeMTOL
//


