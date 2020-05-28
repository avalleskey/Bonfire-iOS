//
//  ErrorView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/3/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "BFVisualErrorView.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

@implementation BFVisualErrorView

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

- (id)initWithVisualError:(BFVisualError *)visualError {
    if (self = [super init]) {
        [self setup];
        
        self.visualError = visualError;
    }
    
    return self;
}

- (void)setVisualError:(BFVisualError * _Nullable)visualError {
    [self updateType:visualError.errorType];
    
    if (visualError != _visualError) {
        _visualError = visualError;
        
        self.errorTitle.text = visualError.errorTitle;
        self.errorTitle.hidden = (self.errorTitle.text.length == 0);
        
        self.errorDescription.text = visualError.errorDescription;
        self.errorDescription.hidden = (self.errorDescription.text.length == 0);
        
        [self.actionButton setTitle:visualError.actionTitle forState:UIControlStateNormal];
        self.actionButton.hidden = (visualError.actionBlock == nil || self.actionButton.currentTitle.length == 0);
        
        [self.actionButton bk_removeAllBlockObservers];
        if (![self.actionButton isHidden]) {
            [self.actionButton bk_addEventHandler:^(id sender) {
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.actionButton.transform = CGAffineTransformMakeScale(0.92, 0.92);
                } completion:nil];
            } forControlEvents:UIControlEventTouchDown];
            [self.actionButton bk_addEventHandler:^(id sender) {
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.actionButton.transform = CGAffineTransformIdentity;
                } completion:nil];
            } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
            [self.actionButton bk_whenTapped:^{
                self.visualError.actionBlock();
            }];
        }
            
        [self resize];
        [self updateErrorTitleColor];
    }
}

- (void)setup {
    self.frame = CGRectMake(16, 0, [UIScreen mainScreen].bounds.size.width - 32, 0);
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 26, 0, 52, 52)];
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.layer.cornerRadius = self.imageView.frame.size.width / 2;
    self.imageView.layer.masksToBounds = true;
    self.imageView.tintColor = [UIColor contentBackgroundColor];
    [self addSubview:self.imageView];
    
    self.errorTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, self.imageView.frame.origin.y + self.imageView.frame.size.height + 12, self.frame.size.width, 30)];
    self.errorTitle.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
    self.errorTitle.textColor = [UIColor bonfireSecondaryColor];
    self.errorTitle.textAlignment = NSTextAlignmentCenter;
    self.errorTitle.numberOfLines = 0;
    self.errorTitle.lineBreakMode = NSLineBreakByWordWrapping;
    [self addSubview:self.errorTitle];
    
    self.errorDescription = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width * .1, self.errorTitle.frame.origin.y + self.errorTitle.frame.size.height + 6, self.frame.size.width * .8, 30)];
    self.errorDescription.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
    self.errorDescription.textColor = [UIColor bonfireSecondaryColor];
    self.errorDescription.textAlignment = NSTextAlignmentCenter;
    self.errorDescription.numberOfLines = 0;
    self.errorDescription.lineBreakMode = NSLineBreakByWordWrapping;
    [self addSubview:self.errorDescription];
    
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.actionButton.frame = CGRectMake(0, self.errorDescription.frame.origin.y + self.errorDescription.frame.size.height + 12, 143, 38);
    self.actionButton.layer.cornerRadius = 10.f;
    self.actionButton.backgroundColor = [UIColor bonfireSecondaryColor];
    self.actionButton.layer.masksToBounds = true;
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
    [self.actionButton setTitleColor:[UIColor contentBackgroundColor] forState:UIControlStateNormal];
    self.actionButton.hidden = true;
    [self addSubview:self.actionButton];
}

- (void)resize {
    CGPoint oldCenter = self.center;
    
    CGFloat height = 0;
    CGFloat prevPadding = 0; // padding underneath the last positioned item
    
    if (![self.imageView isHidden]) {
        height = self.imageView.frame.origin.y + self.imageView.frame.size.height;
        prevPadding = 12;
    }
    
    if (self.errorTitle.text.length > 0) {
        CGRect titleRect = [self.errorTitle.text boundingRectWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.errorTitle.font} context:nil];
        self.errorTitle.frame = CGRectMake(self.errorTitle.frame.origin.x, height + prevPadding, self.frame.size.width - (self.errorTitle.frame.origin.x * 2), ceilf(titleRect.size.height));
        prevPadding = 6;
        
        height = self.errorTitle.frame.origin.y + self.errorTitle.frame.size.height;
    }
    
    if (self.errorDescription.text.length > 0) {
        CGRect descriptionRect = [self.errorDescription.text boundingRectWithSize:CGSizeMake(self.frame.size.width * .8, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.errorDescription.font} context:nil];
        self.errorDescription.frame = CGRectMake(self.frame.size.width * .1, height + prevPadding, self.frame.size.width * .8, ceilf(descriptionRect.size.height));
        // prevPadding = 24;
        
        height = self.errorDescription.frame.origin.y + self.errorDescription.frame.size.height;
    }
    
    if (![self.actionButton isHidden] && self.actionButton.currentTitle.length > 0) {
        CGRect buttonRect = [self.actionButton.currentTitle boundingRectWithSize:CGSizeMake(self.frame.size.width * .8, self.actionButton.titleLabel.font.lineHeight) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.actionButton.titleLabel.font} context:nil];
        CGFloat buttonWidth = buttonRect.size.width + (16 * 2); // 16 padding on the left/right
        self.actionButton.frame = CGRectMake(self.frame.size.width / 2 - buttonWidth / 2, height + 20, buttonWidth, self.actionButton.frame.size.height);
        // prevPadding = 0;
        
        height = self.actionButton.frame.origin.y + self.actionButton.frame.size.height;
    }
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
    
    self.center = oldCenter;
}

- (void)updateType:(ErrorViewType)newType {
    BOOL hideImageView = false;
    UIColor *themeColor;
    
    // reset content mode
    self.imageView.contentMode = UIViewContentModeCenter;
    
    switch (newType) {
        case ErrorViewTypeGeneral:
            // hideImageView = true;
            self.imageView.image = [[UIImage imageNamed:@"errorGeneral"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ErrorViewTypeBlocked:
            self.imageView.image = [[UIImage imageNamed:@"errorBlocked"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ErrorViewTypeNotFound:
            self.imageView.image = [[UIImage imageNamed:@"errorNotFound"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ErrorViewTypeLocked:
            self.imageView.image = [[UIImage imageNamed:@"errorPrivate"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ErrorViewTypeNoInternet:
            self.imageView.image = [[UIImage imageNamed:@"errorNoInternet"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ErrorViewTypeHeart:
            self.imageView.image = [[UIImage imageNamed:@"errorHeart"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            themeColor = [UIColor redColor];
            break;
        case ErrorViewTypeNoPosts:
            self.imageView.image = [[UIImage imageNamed:@"errorFlower"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ErrorViewTypeNoNotifications:
            self.imageView.image = [[UIImage imageNamed:@"errorNotifications"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ErrorViewTypeContactsDenied:
            self.imageView.image = [[UIImage imageNamed:@"errorContacts"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ErrorViewTypeClock:
            self.imageView.image = [[UIImage imageNamed:@"errorClock"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ErrorViewTypeSearch:
            self.imageView.image = [[UIImage imageNamed:@"errorSearch"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ErrorViewTypeRepliesDisabled:
            self.imageView.image = [[UIImage imageNamed:@"errorRepliesDisabled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ErrorViewTypeFirstPost:
            self.imageView.contentMode = UIViewContentModeScaleAspectFill;
            self.imageView.image = [UIImage imageNamed:@"errorFirstPost"];
            themeColor = [UIColor bonfireBrand];
            break;
            
        default:
            self.imageView.image = [[UIImage imageNamed:@"errorGeneral"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
    }

    self.imageView.hidden = hideImageView;
    
    if (!hideImageView) {
        if (themeColor) {
            self.imageView.tintColor = [UIColor fromHex:[UIColor toHex:themeColor] adjustForOptimalContrast:true];
            if (self.imageView.contentMode == UIViewContentModeCenter) {
                self.imageView.backgroundColor = [[UIColor fromHex:[UIColor toHex:themeColor] adjustForOptimalContrast:true] colorWithAlphaComponent:0.16];
            }
            else {
                self.imageView.backgroundColor = [UIColor clearColor];
            }
            
            self.actionButton.backgroundColor = self.imageView.tintColor;
            
            if ([UIColor useWhiteForegroundForColor:self.actionButton.backgroundColor]) {
                [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            }
            else {
                [self.actionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            }
        }
        else {
            self.imageView.tintColor = [UIColor bonfireSecondaryColor];
            self.imageView.backgroundColor = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.16];
            
            self.actionButton.backgroundColor = [UIColor bonfirePrimaryColor];
            [self.actionButton setTitleColor:[UIColor viewBackgroundColor] forState:UIControlStateNormal];
        }
    }
        
    [self updateErrorTitleColor];
}

- (void)updateErrorTitleColor {
    if (self.errorDescription.text.length == 0) {
        self.errorTitle.textColor = [UIColor bonfireSecondaryColor];
    }
    else if (self.imageView.image == nil || [self.imageView isHidden]) {
        self.errorTitle.textColor = [UIColor bonfireSecondaryColor];
    }
    else {
        self.errorTitle.textColor = [UIColor bonfirePrimaryColor];
    }
}

@end

@implementation BFVisualError

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (BFVisualError *)visualErrorOfType:(NSInteger)errorType title:(NSString * _Nullable)errorTitle description:(NSString * _Nullable)errorDescription actionTitle:(NSString * _Nullable)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock {
    BFVisualError *visualError = [[BFVisualError alloc] init];
    
    visualError.errorType = errorType;
    visualError.errorTitle = errorTitle;
    visualError.errorDescription = errorDescription;
    visualError.actionTitle = actionTitle;
    visualError.actionBlock = actionBlock;
    
    return visualError;
}

@end
