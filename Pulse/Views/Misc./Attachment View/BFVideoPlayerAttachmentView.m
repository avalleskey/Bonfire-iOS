//
//  BFVideoPlayerAttachmentView.m
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFVideoPlayerAttachmentView.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Launcher.h"

@interface BFVideoPlayerAttachmentView ()

@property (nonatomic, strong) BFActivityIndicatorView *spinner;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation BFVideoPlayerAttachmentView

- (void)setup {
    [super setup];
    
    self.contentView.backgroundColor = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.25f];
    [self bk_whenTapped:^{
        BFVideoPlayerViewController *videoVC = [Launcher openVideoViewer:self delegate:nil];
        videoVC.videoURL = self.videoURL;
    }];
    
    self.spinner = [[BFActivityIndicatorView alloc] init];
    self.spinner.color = [UIColor bonfireSecondaryColor];
    self.spinner.frame = CGRectMake(0, 0, 40, 40);
    
    [self.contentView addSubview:self.spinner];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == _player && [keyPath isEqualToString:@"status"]) {
        if (_player.status == AVPlayerStatusReadyToPlay) {
            [self.spinner setHidden:true];
        }
        else if (_player.status == AVPlayerStatusFailed) {
            // something went wrong. player.error should contain some information
        }
    }
}

- (void)initPlayer {
    if (!self.videoURL) return;
    
    if (_player) {
        _player = nil;
    }
    if (_playerLayer) {
        [_playerLayer removeFromSuperlayer];
    }
    
    _player = [AVPlayer playerWithURL:[NSURL URLWithString:self.videoURL]];
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [_player addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _playerLayer.contentsGravity = AVLayerVideoGravityResizeAspectFill;
    [self.contentView.layer addSublayer:_playerLayer];
    
    [self play];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.spinner.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    
    if (_playerLayer) {
        _playerLayer.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
    }
    
    [self startSpinnersAsNeeded];
}

- (void)pause {
    [_player pause];
}
- (void)play {
    [_player play];
}

- (void)startSpinnersAsNeeded {
    [self.spinner startAnimating];
}

- (void)setVideoURL:(NSString *)videoURL {
    if (![videoURL isEqualToString:_videoURL]) {
        _videoURL = videoURL;
        
        [self initPlayer];
    }
}

@end
