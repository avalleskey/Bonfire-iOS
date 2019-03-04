//
//  PostImagesView.m
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PostImagesView.h"
#import "Session.h"
#import "Launcher.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

@implementation PostImagesView

- (id)init {
    self  = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.layer.cornerRadius = 12.f;
    self.layer.masksToBounds = true;
    self.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
    self.layer.borderColor = [UIColor colorWithWhite:0.94 alpha:1].CGColor;
    
    self.imageViews = [[NSMutableArray alloc] init];
    self.media = @[];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Lay things out again
    [self layoutImageViews];
}

- (void)setMedia:(NSArray *)media {
    if (media != _media) {
        _media = media;
        
        [self initImageViews];
    }
}

- (void)initImageViews {
    if (_media.count != _imageViews.count) {
        // we need to create or remove image views
        
        if (_imageViews.count > _media.count) {
            // we need to REMOVE image views
            NSInteger x = self.imageViews.count - 1;
            NSLog(@"x : %ld", (long)x);
            NSLog(@"media.count: %ld", _media.count);
            
            for (NSInteger i = self.imageViews.count - 1; i >= _media.count - 1; i--) {
                UIImageView *imageView = self.imageViews[i];
                
                [imageView removeFromSuperview];
                [self.imageViews removeObjectAtIndex:i];
            }
        }
        else {
            // since we've alraedy determined the counts are not equal and that there are more image views than media, we know we need to ADD image views
            NSInteger newImageViews = (_media.count - _imageViews.count);
            for (int i = 0; i < newImageViews; i++) {
                UIImageView *imageView = [self newImageView];
                
                [self.imageViews addObject:imageView];
                [self addSubview:imageView];
            }
        }
    }
    
    if (_imageViews.count == 0) {
        // no image views, so stop the code here
        return;
    }
    
    // populate image views with corresponding media
    for (int i = 0; i < self.imageViews.count; i++) {
        UIImageView *imageView = self.imageViews[i];
        
        // this should always be true, but we're including the conditional to make sure we never run into an out-of-index bug that crashes the app
        if (self.media.count > i) {
            if ([self.media[i] isKindOfClass:[UIImage class]]) {
                // image
                imageView.image = self.media[i];
            }
            else if ([self.media[i] isKindOfClass:[NSString class]] && ((NSString *)self.media[i]).length > 0) {
                // url
                [imageView sd_setImageWithURL:[NSURL URLWithString:self.media[i]]];
            }
        }
    }
    
    [self layoutImageViews];
}
- (UIImageView *)newImageView {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.95 alpha:1.0];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
    imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
    imageView.layer.masksToBounds = true;
    imageView.userInteractionEnabled = true;
    
    [imageView bk_whenTapped:^{
        [[Launcher sharedInstance] expandImageView:imageView];
    }];
    
    return imageView;
}

- (void)layoutImageViews {
    if (self.imageViews.count == 0)
        return;
    
    if (self.imageViews.count == 1) {
        // full width
        UIImageView *onlyImageView = [self.imageViews firstObject];
        onlyImageView.frame = self.bounds;
    }
    else {
        CGFloat halfWidth = (self.frame.size.width - 2) / 2;
        CGFloat halfHeight = (self.frame.size.height - 2) / 2;
        
        UIImageView *imageView1 = self.imageViews[0];
        imageView1.frame = CGRectMake(0, 0, halfWidth, self.imageViews.count > 3 ? halfHeight : self.frame.size.height);
        
        if (self.imageViews.count > 1) {
            UIImageView *imageView2 = self.imageViews[1];
            imageView2.frame = CGRectMake(self.frame.size.width - halfWidth, 0, halfWidth, self.imageViews.count == 2 ? self.frame.size.height : halfHeight);
        }
        if (self.imageViews.count > 2) {
            UIImageView *imageView3 = self.imageViews[2];
            imageView3.frame = CGRectMake(self.imageViews.count == 4 ? 0 : self.frame.size.width - halfWidth, self.frame.size.height - halfHeight, halfWidth, halfHeight);
        }
        if (self.imageViews.count > 3) {
            UIImageView *imageView4 = self.imageViews[3];
            imageView4.frame = CGRectMake(self.frame.size.width - halfWidth, self.frame.size.height - halfHeight, halfWidth, halfHeight);
        }
        
    }
}

+ (CGFloat)streamImageHeight {
    return [Session sharedInstance].defaults.post.imgHeight;
}

@end
