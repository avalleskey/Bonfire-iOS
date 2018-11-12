//
//  PostImagesView.m
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PostImagesView.h"

@implementation PostImagesView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame:frame];
        _imageView.layer.cornerRadius = 16.f;
        _imageView.layer.masksToBounds = true;
        [self addSubview:_imageView];
        
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Bail if text view isn't set up yet
    if (self.imageView == nil) return;
    
    // Lay things out again
}

@end
