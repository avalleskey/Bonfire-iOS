//
//  BFVideoPlayerViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 5/18/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFVideoPlayerViewController.h"
#import <AVKit/AVKit.h>
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

@interface BFVideoPlayerViewController ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation BFVideoPlayerViewController

- (void)viewDidLoad {
//    __weak typeof(self) weakSelf = self;
//    self.senderViewFinalState = ^{
//        weakSelf.senderView.frame = CGRectMake(16, 16, 32, 32);
//    };
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initVideoPlayer];
    [self initControls];
    
    self.innerShadow = true;
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.04 alpha:1];
    
    self.loading = true;
    self.spinner.color = [UIColor bonfireSecondaryColor];
    
    [self.senderView.superview bringSubviewToFront:self.senderView];
    
    NSLog(@"📹 Start watching: %@ 📹", self.videoURL);
}

- (void)initVideoPlayer {
    _player = [AVPlayer playerWithURL:[NSURL URLWithString:self.videoURL]];
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [_player addObserver:self forKeyPath:@"status" options:0 context:nil];

    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = self.contentView.bounds;
    [self updatePlayerGravity];
    [self.contentView.layer insertSublayer:_playerLayer atIndex:0];
    
    [_player play];
    
    [self setTopGradientColor:[UIColor colorWithWhite:0 alpha:0.4] length:0.2];
    [self setBottomGradientColor:[UIColor colorWithWhite:0 alpha:0.4] length:0.1];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == _player && [keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            [self setLoading:false];
        } else if (_player.status == AVPlayerStatusFailed) {
            // something went wrong. player.error should contain some information
        }
    }
}

- (void)initControls {
    self.closeButton.tintColor = [UIColor whiteColor];
    self.showCloseButtonShadow = true;
    
    [self.contentView addGuideAtY:self.closeButton.center.y];
    [self.contentView addGuideAtX:24];
    [self.contentView addGuideAtX:self.contentView.frame.size.width-24];
}

- (void)setLoading:(BOOL)loading {
    [super setLoading:loading];
    
    if (loading) {
        _playerLayer.opacity = 0;
    }
    else {
        _playerLayer.opacity = 1;
    }
}

- (void)setFormat:(BFVideoPlayerFormat)format {
    if (format != _format) {
        _format = format;
        
        [self updatePlayerGravity];
    }
}

- (void)updatePlayerGravity {
    if (_playerLayer) {
        if (self.format == BFVideoPlayerFormatVideo) {
            _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            _playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
        }
        else if (self.format == BFVideoPlayerFormatStory) {
            _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            _playerLayer.contentsGravity = AVLayerVideoGravityResizeAspectFill;
        }
    }
}

@end
