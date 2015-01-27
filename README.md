#Movieplaying
Sample project for PHIVideoPlayerView, a minimalist AVPlayer-based video player, embedded in an easy-to-use UIView subclass. UI elements center around: a timeline scrubber, elapsed and remaining time, a play/pause button at the center, and, if available, and an AirPlay button.  

The class is largely free of external dependencies — save for a small category, consisting of AutoLayout convenience methods (provided in the class/group). Visual assets are provided in an image bundle.

## How to use the sample

The project can run on iPhones/iPads (iOS 7+) or be executed in the simulator (iOS 7+). Just open the project in Xcode 5 (and above).

## Usage

To use in your own projects, just drag the files in the [PHIVideoPlayerView folder](PHIVideoPlayerView/) into your own project and import the header files. Then, allocate an instance like so:

```objective-c
PHIVideoPlayerView *videoPlayer = [[PHIVideoPlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) contentURL:url];
```

Customize the scrubber color:

```objective-c
videoPlayer.tintColor = [UIColor redColor];
```

and specify whether the HUD should hide/show the UINavigationBar in full-screen/landscape layout:

```objective-c
videoPlayer.shouldShowHideParentNavigationBar = YES;
```

If you would like to overwrite the vibrate/mute toggle (play audio even though the phone is set to vibrate), just set the corresponding property:

```objective-c
videoPlayer.shouldPlayAudioOnVibrate = YES;
```
