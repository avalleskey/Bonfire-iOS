//
//  BFVideoPlayerAttachmentView.m
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFVideoPlayerAttachmentView.h"
#import "UIColor+Palette.h"

@implementation BFVideoPlayerAttachmentView

- (instancetype)initWithVideoURL:(NSString *)videoURL frame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.videoURL = videoURL;
    }
    
    return self;
}

- (void)setup {
    [super setup];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setVideoURL:(NSString *)videoURL {
    if (![videoURL isEqualToString:_videoURL]) {
        _videoURL = videoURL;
        
        
    }
}

@end
