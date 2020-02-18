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
#import <UIView+WebCache.h>

#define k_defaultAvatarTintColor [UIColor bonfireSecondaryColor]

@implementation BFAvatarView

@synthesize user = _user;
@synthesize bot = _bot;
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
//    self.imageView.sd_imageTransition = [SDWebImageTransition fadeTransition];
    [self addSubview:self.imageView];
    
    // functionality
    self.imageView.userInteractionEnabled = true;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self updateCornerRadius];
    
    self.highlightView = [[UIView alloc] initWithFrame:self.bounds];
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
    
    if (@available(iOS 13.0, *)) {
        UIContextMenuInteraction *avatarInteraction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self addInteraction:avatarInteraction];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.04f].CGColor;
    self.highlightView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.3f];
}

- (void)setOpenOnTap:(BOOL)openOnTap {
    if (openOnTap != _openOnTap) {
        _openOnTap = openOnTap;
        
        if (openOnTap) {
            self.dimsViewOnTap = true;
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
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
- (void)tapped:(UITapGestureRecognizer *)sender {
    if (self.user != nil) {
        if (!self.user.attributes.anonymous) {
            [Launcher openProfile:self.user];
        }
    }
    else if (self.bot != nil) {
        [Launcher openBot:self.bot];
    }
    else if (self.camp != nil) {
        [Launcher openCamp:self.camp];
    }
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
    if (user == nil || user != _user || ![user.attributes.color isEqualToString:_user.attributes.color]) {
        _bot = nil;
        _camp = nil;
        _user = user;
        
        if (user == nil) {
            self.imageView.layer.borderWidth = 0;
            self.imageView.tintColor = [UIColor whiteColor];
            self.imageView.backgroundColor = k_defaultAvatarTintColor;
            self.imageView.image = [UIImage imageNamed:@"anonymous"];
            [self.imageView sd_cancelCurrentImageLoad];
        }
        else {
            if (_user.attributes.media.avatar.suggested.url && _user.attributes.media.avatar.suggested.url.length > 0) {
                self.imageView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.12f];
                self.imageView.layer.borderWidth = 0;
                self.imageView.image = nil;
                
                [self.imageView sd_setImageWithURL:[NSURL URLWithString:_user.attributes.media.avatar.suggested.url] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    self.imageView.layer.borderWidth = 1;
                }];
            }
            else {
                self.imageView.backgroundColor = [UIColor fromHex:_user.attributes.color];
                self.imageView.layer.borderWidth = 0;
                [self.imageView sd_cancelCurrentImageLoad];
                
                if ([UIColor useWhiteForegroundForColor:[UIColor fromHex:_user.attributes.color]]) {
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

- (void)setBot:(Bot *)bot {
    if (bot == nil || bot != _bot || ![bot.attributes.color isEqualToString:_bot.attributes.color]) {
        _user = nil;
        _camp = nil;
        _bot = bot;
        
        if (bot == nil) {
            self.imageView.layer.borderWidth = 0;
            self.imageView.tintColor = [UIColor whiteColor];
            self.imageView.backgroundColor = k_defaultAvatarTintColor;
            self.imageView.image = [UIImage imageNamed:@"anonymous_bot"];
            [self.imageView sd_cancelCurrentImageLoad];
        }
        else {
            if (_bot.attributes.media.avatar.suggested.url && _bot.attributes.media.avatar.suggested.url.length > 0) {
                self.imageView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.12f];
                self.imageView.layer.borderWidth = 0;
                self.imageView.image = nil;
                
                [self.imageView sd_setImageWithURL:[NSURL URLWithString:_bot.attributes.media.avatar.suggested.url] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    self.imageView.layer.borderWidth = 1;
                }];
            }
            else {
                self.imageView.backgroundColor = [UIColor fromHex:_bot.attributes.color];
                self.imageView.layer.borderWidth = 0;
                [self.imageView sd_cancelCurrentImageLoad];
                
                if ([UIColor useWhiteForegroundForColor:[UIColor fromHex:_bot.attributes.color]]) {
                    // dark enough
                    self.imageView.image = [UIImage imageNamed:@"anonymous_bot"];
                }
                else {
                    self.imageView.image = [UIImage imageNamed:@"anonymous_bot_black"];
                }
            }
        }
    }
}
- (Bot *)bot {
    return _bot;
}

- (void)setCamp:(Camp *)camp {
    if (camp == nil || camp != _camp || ![camp.attributes.color isEqualToString:_camp.attributes.color]) {
        _user = nil;
        _bot = nil;
        _camp = camp;
        
        if (camp == nil) {
            self.imageView.layer.borderWidth = 0;
            self.imageView.tintColor = [UIColor whiteColor];
            self.imageView.backgroundColor = k_defaultAvatarTintColor;
            self.imageView.image = [UIImage imageNamed:@"anonymousGroup"];
            [self.imageView sd_cancelCurrentImageLoad];
        }
        else {
            if (_camp.attributes.media.avatar.suggested.url && _camp.attributes.media.avatar.suggested.url.length > 0) {
                self.imageView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.12f];
                self.imageView.layer.borderWidth = 0;
                self.imageView.image = nil;
                
                [self.imageView sd_setImageWithURL:[NSURL URLWithString:_camp.attributes.media.avatar.suggested.url] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    self.imageView.layer.borderWidth = 1;
                }];
            }
            else {
                self.imageView.backgroundColor = [UIColor fromHex:_camp.attributes.color];
                self.imageView.layer.borderWidth = 0;
                [self.imageView sd_cancelCurrentImageLoad];
                
                if ([UIColor useWhiteForegroundForColor:[UIColor fromHex:_camp.attributes.color]]) {
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
    }
    
    if (_placeholderAvatar) {
        self.imageView.backgroundColor = [UIColor clearColor];
        self.imageView.image = [[UIImage imageNamed:@"campHeaderAddIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
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
    [UIView animateWithDuration:0.15f animations:^{
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

- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(nonnull UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location  API_AVAILABLE(ios(13.0)){
    if (self.camp) {
        UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[]];
        
        CampViewController *campVC = [Launcher campViewControllerForCamp:self.camp];
        campVC.isPreview = true;
        
        UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:@"camp_preview" previewProvider:^(){return campVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
        return configuration;
    }
    else if (self.user && !self.user.attributes.anonymous) {
        UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[]];
        
        ProfileViewController *userVC = [Launcher profileViewControllerForUser:self.user];
        
        UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:@"user_preview" previewProvider:^(){return userVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
        return configuration;
    }
    
    return nil;
}

- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    [animator addCompletion:^{
        wait(0, ^{
            if (self.camp) {
                [Launcher openCamp:self.camp];
            }
            else if (self.user && !self.user.attributes.anonymous) {
                [Launcher openProfile:self.user];
            }
        });
    }];
}

@end
