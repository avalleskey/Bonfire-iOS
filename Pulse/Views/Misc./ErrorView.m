//
//  ErrorView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/3/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ErrorView.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

@implementation ErrorView

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

- (id)initWithFrame:(CGRect)rect title:(NSString *)title description:(NSString *)description type:(NSInteger)type {
    self = [super initWithFrame:rect];
    if (self) {
        [self setup];
        [self updateType:type title:title description:description actionTitle:nil actionBlock:nil];
    }
    
    return self;
}

- (void)setup {
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 28, 0, 56, 56)];
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.layer.cornerRadius = self.imageView.frame.size.width / 2;
    self.imageView.layer.masksToBounds = true;
    self.imageView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.imageView];
    
    self.errorTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, self.imageView.frame.origin.y + self.imageView.frame.size.height + 12, self.frame.size.width, 30)];
    self.errorTitle.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightHeavy];
    self.errorTitle.textColor = [UIColor bonfireGray];
    self.errorTitle.textAlignment = NSTextAlignmentCenter;
    self.errorTitle.numberOfLines = 0;
    self.errorTitle.lineBreakMode = NSLineBreakByWordWrapping;
    [self addSubview:self.errorTitle];
    
    self.errorDescription = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width * .1, self.errorTitle.frame.origin.y + self.errorTitle.frame.size.height + 6, self.frame.size.width * .8, 30)];
    self.errorDescription.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
    self.errorDescription.textColor = [UIColor bonfireGray];
    self.errorDescription.textAlignment = NSTextAlignmentCenter;
    self.errorDescription.numberOfLines = 0;
    self.errorDescription.lineBreakMode = NSLineBreakByWordWrapping;
    [self addSubview:self.errorDescription];
    
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.actionButton.frame = CGRectMake(0, self.errorDescription.frame.origin.y + self.errorDescription.frame.size.height + 12, 143, 40);
    self.actionButton.layer.cornerRadius = 12.f;
    self.actionButton.layer.masksToBounds = true;
    self.actionButton.backgroundColor = [UIColor bonfireBlack];
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
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
        self.errorTitle.frame = CGRectMake(self.errorTitle.frame.origin.x, height + prevPadding, self.frame.size.width, ceilf(titleRect.size.height));
        prevPadding = 6;
        
        height = self.errorTitle.frame.origin.y + self.errorTitle.frame.size.height;
    }
    
    if (self.errorDescription.text.length > 0) {
        CGRect descriptionRect = [self.errorDescription.text boundingRectWithSize:CGSizeMake(self.frame.size.width * .8, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.errorDescription.font} context:nil];
        self.errorDescription.frame = CGRectMake(self.frame.size.width * .1, height + prevPadding, self.frame.size.width * .8, ceilf(descriptionRect.size.height));
        prevPadding = 24;
        
        height = self.errorDescription.frame.origin.y + self.errorDescription.frame.size.height;
    }
    
    if (![self.actionButton isHidden] && self.actionButton.currentTitle.length > 0) {
        CGRect buttonRect = [self.actionButton.currentTitle boundingRectWithSize:CGSizeMake(self.frame.size.width * .8, self.actionButton.titleLabel.font.lineHeight) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.actionButton.titleLabel.font} context:nil];
        CGFloat buttonWidth = buttonRect.size.width + (16 * 2); // 16 padding on the left/right
        self.actionButton.frame = CGRectMake(self.frame.size.width / 2 - buttonWidth / 2, height + 24, buttonWidth, self.actionButton.frame.size.height);
        prevPadding = 0;
        
        height = self.actionButton.frame.origin.y + self.actionButton.frame.size.height;
    }
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
    
    self.center = oldCenter;
}

- (void)updateType:(ErrorViewType)newType {
    BOOL hideImageView = false;
    
    switch (newType) {
        case ErrorViewTypeGeneral:
            hideImageView = true;
            break;
        case ErrorViewTypeBlocked:
            self.imageView.image = [UIImage imageNamed:@"errorBlocked"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            break;
        case ErrorViewTypeNotFound:
            self.imageView.image = [UIImage imageNamed:@"errorNotFound"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            break;
        case ErrorViewTypeLocked:
            self.imageView.image = [UIImage imageNamed:@"errorPrivate"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            break;
        case ErrorViewTypeNoInternet:
            self.imageView.image = [UIImage imageNamed:@"errorNoInternet"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            break;
        case ErrorViewTypeHeart:
            self.imageView.image = [UIImage imageNamed:@"errorHeart"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            break;
        case ErrorViewTypeNoPosts:
            self.imageView.image = [UIImage imageNamed:@"errorFlower"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            break;
        case ErrorViewTypeNoNotifications:
            self.imageView.image = [UIImage imageNamed:@"errorNotifications"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            break;
        case ErrorViewTypeContactsDenied:
            self.imageView.image = [UIImage imageNamed:@"errorContacts"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            break;
        case ErrorViewTypeClock:
            self.imageView.image = [UIImage imageNamed:@"errorClock"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            break;
            
        default:
            self.imageView.image = [UIImage imageNamed:@"errorGeneral"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            break;
    }

    self.imageView.hidden = hideImageView;
    
    [self updateErrorTitleColor];
}

- (void)updateType:(ErrorViewType)type title:(nullable NSString *)newTitle description:(nullable NSString *)newDescription actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionHandler {
    self.errorTitle.text = newTitle;
    self.errorTitle.hidden = (self.errorTitle.text.length == 0);
    
    self.errorDescription.text = newDescription;
    self.errorDescription.hidden = (self.errorDescription.text.length == 0);
    
    [self.actionButton setTitle:actionTitle forState:UIControlStateNormal];
    self.actionButton.hidden = (!actionHandler || self.actionButton.currentTitle.length == 0);
    if (![self.actionButton isHidden]) {
        self.actionButton.backgroundColor = self.tintColor;
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
        [self.actionButton bk_whenTapped:actionHandler];
    }
    else {
        [self.actionButton bk_removeAllBlockObservers];
    }
    
    [self updateType:type];
    [self resize];
}

- (void)updateTitle:(nullable NSString *)newTitle {
    self.errorTitle.text = newTitle;
    [self resize];
    
    [self updateErrorTitleColor];
}
- (void)updateDescription:(nullable NSString *)newDescription {
    self.errorDescription.text = newDescription;
    [self resize];
    
    [self updateErrorTitleColor];
}

- (void)updateErrorTitleColor {
    if (self.errorDescription.text.length == 0) {
        self.errorTitle.textColor = [UIColor bonfireGray];
    }
    else if (self.imageView.image == nil) {
        self.errorTitle.textColor = [UIColor bonfireGray];
    }
    else {
        self.errorTitle.textColor = [UIColor bonfireGray];
    }
}

@end
