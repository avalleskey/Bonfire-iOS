//
//  BFAvatarView.m
//  Pulse
//
//  Created by Austin Valleskey on 12/15/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "BFAvatarView.h"
#import "UIColor+Palette.h"
#import <UIImageView+WebCache.h>
#import "Launcher.h"
#import "UIColor+Palette.h"

#define k_defaultAvatarTintColor [UIColor bonfireGray]

@implementation BFAvatarView

@synthesize user = _user;
@synthesize camp = _camp;

- (id)init {
    self = [super init];
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
    // style
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.imageView.image = [UIImage imageNamed:@"anonymous"];
    self.imageView.layer.masksToBounds = true;
    self.imageView.layer.borderWidth = 0;
    self.imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.04f].CGColor;
    [self addSubview:self.imageView];
    
    // functionality
    self.imageView.userInteractionEnabled = true;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self updateCornerRadius];
    
    self.highlightView = [[UIView alloc] initWithFrame:self.bounds];
    self.highlightView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3f];
    self.highlightView.userInteractionEnabled = false;
    self.highlightView.alpha = 0;
    [self.imageView addSubview:self.highlightView];
        
    CGFloat onlineDotViewDiameter = roundf(self.frame.size.width / 3);;
    self.onlineDotView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - onlineDotViewDiameter + 1, self.frame.size.height - onlineDotViewDiameter + 1, onlineDotViewDiameter, onlineDotViewDiameter)];
    self.onlineDotView.image = [UIImage imageNamed:@"onlineDot"];
    [self addSubview:self.onlineDotView];
    [self bringSubviewToFront:self.onlineDotView];
    
    self.online = true;
    self.allowOnlineDot = false;
    self.dimsViewOnTap = false;
    self.openOnTap = false;
    self.placeholderAvatar = false;
}

- (void)setOpenOnTap:(BOOL)openOnTap {
    if (openOnTap != _openOnTap) {
        _openOnTap = openOnTap;
        
        if (openOnTap) {
            self.dimsViewOnTap = true;
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openUser:)];
            [self addGestureRecognizer:tapGestureRecognizer];
        }
        else {
            self.dimsViewOnTap = false;
            for (UITapGestureRecognizer *tapGestureRecognizer in self.gestureRecognizers) {
                [self removeGestureRecognizer:tapGestureRecognizer];
            }
        }
    }
}
- (void)openUser:(UITapGestureRecognizer *)sender {
    [Launcher openProfile:self.user];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    self.imageView.frame = self.bounds;
    [self updateCornerRadius];
    
    CGFloat onlineDotViewDiameter = roundf(self.frame.size.width / 3);
    self.onlineDotView.frame = CGRectMake(self.frame.size.width - onlineDotViewDiameter + 1, self.frame.size.height - onlineDotViewDiameter + 1, onlineDotViewDiameter, onlineDotViewDiameter);
}

- (void)updateCornerRadius {
    self.imageView.layer.cornerRadius = self.imageView.frame.size.height * .5;
}

- (void)setUser:(User *)user {
    if (user == nil || user != _user || ![user.attributes.details.color isEqualToString:_user.attributes.details.color]) {
        _user = user;
        
        if (user == nil) {
            self.imageView.layer.borderWidth = 0;
            self.imageView.tintColor = [UIColor whiteColor];
            self.imageView.backgroundColor = k_defaultAvatarTintColor;
        }
        else {
            if (_user.attributes.details.media.userAvatar.suggested.url && _user.attributes.details.media.userAvatar.suggested.url.length > 0) {
                self.imageView.backgroundColor = [UIColor bonfireGrayWithLevel:100];
                self.imageView.layer.borderWidth = 0;
                self.imageView.image = nil;
                
                [self.imageView sd_setImageWithURL:[NSURL URLWithString:_user.attributes.details.media.userAvatar.suggested.url] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    self.imageView.backgroundColor = [UIColor whiteColor];
                    self.imageView.layer.borderWidth = 1;
                }];
            }
            else {
                self.imageView.backgroundColor = [UIColor fromHex:_user.attributes.details.color];
                self.imageView.layer.borderWidth = 0;
                
                if ([UIColor useWhiteForegroundForColor:[UIColor fromHex:_user.attributes.details.color]]) {
                    // dark enough
                    self.imageView.image = [UIImage imageNamed:@"anonymous"];
                }
                else {
                    self.imageView.image = [UIImage imageNamed:@"anonymous_black"];
                }
            }
        }
    }
}
- (User *)user {
    return _user;
}
- (void)setCamp:(Camp *)camp {
    if (camp == nil || camp != _camp || ![camp.attributes.details.color isEqualToString:_camp.attributes.details.color]) {
        _camp = camp;
        
        if (camp == nil) {
            self.imageView.image = [UIImage imageNamed:@"anonymousGroup"];
            self.imageView.tintColor = [UIColor whiteColor];
            self.imageView.backgroundColor = [UIColor bonfireGray];
        }
        else {
            if (_camp.attributes.details.media.campAvatar.suggested.url && _camp.attributes.details.media.campAvatar.suggested.url.length > 0) {
                self.imageView.backgroundColor = [UIColor bonfireGrayWithLevel:100];
                self.imageView.layer.borderWidth = 0;
                self.imageView.image = nil;
                
                [self.imageView sd_setImageWithURL:[NSURL URLWithString:_camp.attributes.details.media.campAvatar.suggested.url] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    self.imageView.backgroundColor = [UIColor whiteColor];
                    self.imageView.layer.borderWidth = 1;
                }];
            }
            else {
                self.imageView.backgroundColor = [UIColor fromHex:_camp.attributes.details.color];
                self.imageView.layer.borderWidth = 0;
                
                if ([UIColor useWhiteForegroundForColor:[UIColor fromHex:_camp.attributes.details.color]]) {
                    // dark enough
                    self.imageView.image = [UIImage imageNamed:@"anonymousGroup"];
                }
                else {
                    self.imageView.image = [UIImage imageNamed:@"anonymousGroup_black"];
                }
            }
        }
    }
}
- (Camp *)camp {
    return _camp;
}

- (void)setPlaceholderAvatar:(BOOL)placeholderAvatar {
    if (placeholderAvatar != _placeholderAvatar) {
        _placeholderAvatar = placeholderAvatar;
        
        if (_placeholderAvatar) {
            self.imageView.backgroundColor = [UIColor whiteColor];
            self.imageView.image = [UIImage imageNamed:@"inviteFriendPlaceholderCircular"];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.dimsViewOnTap) {
        self.touchDown = YES;
        
        [UIView animateWithDuration:0.2f animations:^{
            self.highlightView.alpha = 1;
        }];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered when touch is released
    if (self.dimsViewOnTap) {
        if (self.touchDown) {
            self.touchDown = NO;
            
            [self touchCancel];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered if touch leaves view
    if (self.dimsViewOnTap) {
        if (self.touchDown) {
            self.touchDown = NO;
            
            [self touchCancel];
        }
    }
}

- (void)touchCancel {
    [UIView animateWithDuration:0.2f animations:^{
        self.highlightView.alpha = 0;
    }];
}

- (void)setOnline:(BOOL)online {
    self.onlineDotView.hidden = !online;
}
- (void)setAllowOnlineDot:(BOOL)allowOnlineDot {
    if (allowOnlineDot) {
        [self setOnline:self.online];
    }
    else {
        self.onlineDotView.hidden = true;
    }
}

- (void)userUpdated:(NSNotification *)notification {
    self.user = [Session sharedInstance].currentUser;
}

@end
