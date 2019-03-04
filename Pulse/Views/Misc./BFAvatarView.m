//
//  BFAvatarView.m
//  Pulse
//
//  Created by Austin Valleskey on 12/15/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "BFAvatarView.h"
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>
#import <UIImageView+WebCache.h>
#import "Launcher.h"
#import "UIColor+Palette.h"

#define k_defaultAvatarTintColor [UIColor bonfireGray]

@implementation BFAvatarView

@synthesize user = _user;
@synthesize room = _room;

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
    self.imageView.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.imageView.tintColor = k_defaultAvatarTintColor;
    self.imageView.layer.masksToBounds = true;
    self.imageView.layer.borderWidth = 0;
    self.imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.04f].CGColor;
    self.imageView.layer.shouldRasterize = true;
    self.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
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
        
    CGFloat onlineDotViewDiameter = 16;
    self.onlineDotView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - onlineDotViewDiameter + 1, self.frame.size.height - onlineDotViewDiameter + 1, onlineDotViewDiameter, onlineDotViewDiameter)];
    self.onlineDotView.image = [UIImage imageNamed:@"onlineDot"];
    [self addSubview:self.onlineDotView];
    [self bringSubviewToFront:self.onlineDotView];
    
    self.online = true;
    self.allowOnlineDot = false;
    self.dimsViewOnTap = false;
    self.openOnTap = false;
    self.allowAddUserPlaceholder = false;
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
    [[Launcher sharedInstance] openProfile:self.user];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    self.imageView.frame = self.bounds;
    [self updateCornerRadius];
}

- (void)updateCornerRadius {
    BOOL circleProfilePictures = FBTweakValue(@"Post", @"General", @"Circle Profile Pictures", YES);
    if (circleProfilePictures) {
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height * .5;
    }
    else {
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height * .25;
    }
}

- (void)setUser:(User *)user {
    if (user == nil || user != _user || ![user.attributes.details.color isEqualToString:_user.attributes.details.color]) {
        _user = user;
        
        if (user == nil) {
            self.imageView.layer.borderWidth = 0;
            
            if (_allowAddUserPlaceholder) {
                if (diff(self.imageView.tintColor, [UIColor bonfireGray]))
                    self.imageView.tintColor = [UIColor bonfireGray];
                
                if (diff(self.imageView.backgroundColor, [UIColor whiteColor]))
                    self.imageView.backgroundColor = [UIColor whiteColor];
                
                BOOL circleProfilePictures = FBTweakValue(@"Post", @"General", @"Circle Profile Pictures", YES);
                if (circleProfilePictures) {
                    self.imageView.image = [[UIImage imageNamed:@"inviteFriendPlaceholderCircular"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                }
                else {
                    self.imageView.image = [[UIImage imageNamed:@"inviteFriendPlaceholder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                }
            }
            else {
                if (diff(self.imageView.tintColor, [UIColor whiteColor]))
                    self.imageView.tintColor = [UIColor whiteColor];
                
                if (diff(self.imageView.backgroundColor, [UIColor bonfireGray]))
                    self.imageView.backgroundColor = [UIColor bonfireGray];
            }
        }
        else {
            if (![_user.attributes.details.media.profilePicture isEqualToString:@"<null>"] && _user.attributes.details.media.profilePicture.length > 0) {
                if (diff(self.imageView.backgroundColor, [UIColor whiteColor]))
                    self.imageView.backgroundColor = [UIColor whiteColor];
                
                if (diff(self.imageView.layer.borderWidth, 1))
                    self.imageView.layer.borderWidth = 1;
                
                [self.imageView sd_setImageWithURL:[NSURL URLWithString:_user.attributes.details.media.profilePicture] placeholderImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            }
            else {
                self.imageView.layer.borderWidth = 0;
                
                self.imageView.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                
                if (diff(self.imageView.backgroundColor, [UIColor fromHex:_user.attributes.details.color]))
                    self.imageView.backgroundColor = [UIColor fromHex:_user.attributes.details.color];
                
                UIColor *tintColor;
                if ([UIColor useWhiteForegroundForColor:[UIColor fromHex:_user.attributes.details.color]]) {
                    // dark enough
                    tintColor = [UIColor whiteColor]; //[UIColor lighterColorForColor:[UIColor fromHex:_user.attributes.details.color] amount:BFAvatarViewIconContrast];
                }
                else {
                    tintColor = [UIColor blackColor]; // [UIColor darkerColorForColor:[UIColor fromHex:_user.attributes.details.color] amount:BFAvatarViewIconContrast];
                }
                if (diff(self.imageView.tintColor, tintColor))
                    self.imageView.tintColor = tintColor;
            }
        }
    }
}
- (User *)user {
    return _user;
}
- (void)setRoom:(Room *)room {
    if (room == nil || room != _room) {
        _room = room;
        
        if (room == nil) {
            self.imageView.image = [[UIImage imageNamed:@"anonymousGroup"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.imageView.tintColor = [UIColor whiteColor];
            self.imageView.backgroundColor = [UIColor bonfireGray];
        }
        else {
            BOOL hasRoomPicture = false; // _room.attributes.details.media.profilePicture.length > 0
            if (hasRoomPicture) {
                self.imageView.backgroundColor = [UIColor whiteColor];
                self.imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.04f].CGColor;
                //[self.imageView sd_setImageWithURL:[NSURL URLWithString:_room.attributes.details.media.profilePicture] placeholderImage:[[UIImage imageNamed:@"anonymousGroup"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            }
            else {
                self.imageView.layer.borderColor = [UIColor clearColor].CGColor;
                
                self.imageView.image = [[UIImage imageNamed:@"anonymousGroup"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                self.imageView.backgroundColor = [UIColor fromHex:_room.attributes.details.color];
                if ([UIColor useWhiteForegroundForColor:[UIColor fromHex:_room.attributes.details.color]]) {
                    // dark enough
                    self.imageView.tintColor = [UIColor whiteColor]; // [UIColor lighterColorForColor:[UIColor fromHex:_room.attributes.details.color] amount:BFAvatarViewIconContrast];
                }
                else {
                    self.imageView.tintColor = [UIColor blackColor]; // [UIColor darkerColorForColor:[UIColor fromHex:_room.attributes.details.color] amount:BFAvatarViewIconContrast];
                }
            }
        }
    }
}
- (Room *)room {
    return _room;
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

@end
