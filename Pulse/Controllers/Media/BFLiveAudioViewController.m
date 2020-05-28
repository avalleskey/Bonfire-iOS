//
//  BFVideoPlayerViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 5/18/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFLiveAudioViewController.h"
#import <AVKit/AVKit.h>
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

@interface BFLiveAudioViewController ()

@end

@implementation BFLiveAudioViewController

- (void)viewDidLoad {
    __weak typeof(self) weakSelf = self;
    self.senderViewFinalState = ^{
        weakSelf.senderView.frame = CGRectMake(self.view.frame.size.width / 2 - 120 / 2, 86, 120, 120);
    };
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.innerShadow = false;
    self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        
    [self.senderView.superview bringSubviewToFront:self.senderView];
}

- (void)setLoading:(BOOL)loading {
    [super setLoading:loading];
    
}

@end
