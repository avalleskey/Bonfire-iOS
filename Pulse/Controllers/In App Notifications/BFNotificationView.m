//
//  BFTipView.m
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFNotificationView.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "BFNotificationManager.h"

@interface BFNotificationView ()

@property (nonatomic) CGPoint centerBegin;
@property (nonatomic) CGPoint centerFinal;

@end

@implementation BFNotificationView

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
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithObject:(BFNotificationObject *)object {
    self = [super init];
    if (self) {
        [self setObject:object];
    }
    return self;
}

- (void)setup {
    self.frame = CGRectMake(12, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width - 24, 0);
    self.layer.cornerRadius = 14.f;
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowRadius = 2.f;
    self.layer.shadowOpacity = 1;
    self.layer.masksToBounds = false;
        
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent]];
    self.blurView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.blurView.layer.cornerRadius = self.layer.cornerRadius;
    self.blurView.layer.masksToBounds = true;
    self.blurView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor_Inverted"] colorWithAlphaComponent:0.8];
    self.titleLabel.textColor = [UIColor blackColor];
    self.textLabel.textColor = [UIColor blackColor];
    [self addSubview:self.blurView];
    
    self.closeButton = [[TappableButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 22 - 12, 0, 22, 22)];
    self.closeButton.layer.cornerRadius = self.closeButton.frame.size.height / 2;
    self.closeButton.padding = UIEdgeInsetsMake(12, 12, 12, 12);
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon_small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.tintColor = [UIColor bonfireSecondaryColor];
    self.closeButton.contentMode = UIViewContentModeScaleAspectFill;
    [self.closeButton bk_whenTapped:^{
        [[BFNotificationManager manager] hideAllNotifications];
    }];
    [self addSubview:self.closeButton];
    
    self.notificationTypeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 22, 22)];
    self.notificationTypeImageView.layer.cornerRadius = self.notificationTypeImageView.frame.size.height / 2;
    self.notificationTypeImageView.layer.masksToBounds = true;
    [self addSubview:self.notificationTypeImageView];
    
    self.creatorTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.notificationTypeImageView.frame.origin.x + self.notificationTypeImageView.frame.size.width + 6, 10, 22, 22)];
    self.creatorTitleLabel.textColor = [UIColor bonfireSecondaryColor];
    self.creatorTitleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightMedium];
    [self addSubview:self.creatorTitleLabel];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.notificationTypeImageView.frame.origin.x, self.notificationTypeImageView.frame.origin.y + self.notificationTypeImageView.frame.size.height + 8, self.frame.size.width - (self.notificationTypeImageView.frame.origin.x * 2), 0)];
    self.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.textColor = [UIColor bonfirePrimaryColor];
    [self addSubview:self.titleLabel];
    
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 4, self.titleLabel.frame.size.width, 0)];
    self.textLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.textLabel.textAlignment = NSTextAlignmentLeft;
    self.textLabel.textColor = [UIColor bonfirePrimaryColor];
    [self addSubview:self.textLabel];
        
    [self setupPanRecognizer];
    
    [self layoutSubviews];
}

- (void)setupPanRecognizer {
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [self addGestureRecognizer:panRecognizer];
}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.centerBegin = recognizer.view.center;
        self.centerFinal = CGPointMake(self.centerBegin.x, -1 * (self.frame.size.height * 2) - 16);
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self.superview];
        if (translation.y < 0 || recognizer.view.center.y <= self.centerBegin.y) {
            recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                                 recognizer.view.center.y + translation.y);
        }
        else {
            CGFloat newCenterY = recognizer.view.center.y + translation.y;
            CGFloat diff = fabs(_centerBegin.y - newCenterY);
            CGFloat max = 24;
            NSLog(@"diff: %f", diff);
            NSLog(@"percentage: %f", diff / max);
            CGFloat percentage = diff / max;
            if (percentage > 1) {
                percentage = 1;
            }
            newCenterY = recognizer.view.center.y + (translation.y / (1 + 10 * percentage));
            NSLog(@"newcentery: %f", newCenterY);
            recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                                 newCenterY);
        }
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.superview];
        
        CGFloat percentage = (recognizer.view.center.y - self.centerBegin.y) / (self.centerFinal.y - self.centerBegin.y);
        
        if (percentage > 0) {
            //recognizer.view.transform = CGAffineTransformMakeScale(1.0 - (1.0 - 0.8) * percentage, 1.0 - (1.0 - 0.8) * percentage);
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:self.superview];
        
        CGFloat fromCenterY = fabs(self.centerBegin.y - recognizer.view.center.y);
        CGFloat duration = 0.15+(0.05*(fromCenterY/60));
        
        if (velocity.y < -400) {
            [[BFNotificationManager manager] hideAllNotifications];
        }
        else {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                recognizer.view.center = self.centerBegin;
            } completion:nil];
        }
    }
    
}

- (void)setObject:(BFNotificationObject *)object {
    if (object != _object) {
        _object = object;
        
        if (object.activityType == USER_ACTIVITY_TYPE_USER_FOLLOW) {
            self.notificationTypeImageView.image = [UIImage imageNamed:@"notificationIndicator_profile"];
            self.notificationTypeImageView.backgroundColor = [UIColor bonfireBlue];
        }
        else if (object.activityType == USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS) {
            self.notificationTypeImageView.image = [UIImage imageNamed:@"notificationIndicator_check"];
            self.notificationTypeImageView.backgroundColor = [UIColor bonfireGreen];
        }
        else if (object.activityType == USER_ACTIVITY_TYPE_CAMP_ACCESS_REQUEST) {
            self.notificationTypeImageView.image = [UIImage imageNamed:@"notificationIndicator_clock"];
            self.notificationTypeImageView.backgroundColor = [UIColor colorWithRed:0.52 green:0.53 blue:0.55 alpha:1.0];
        }
        else if (object.activityType == USER_ACTIVITY_TYPE_POST_REPLY) {
            self.notificationTypeImageView.image = [UIImage imageNamed:@"notificationIndicator_reply"];
            self.notificationTypeImageView.backgroundColor = [UIColor bonfireViolet];
        }
        else if (object.activityType == USER_ACTIVITY_TYPE_POST_VOTED) {
            self.notificationTypeImageView.image = [UIImage imageNamed:@"notificationIndicator_spark"];
            self.notificationTypeImageView.backgroundColor = [UIColor bonfireBrand];
        }
        else if (object.activityType == USER_ACTIVITY_TYPE_USER_POSTED || object.activityType == USER_ACTIVITY_TYPE_USER_POSTED_CAMP) {
            self.notificationTypeImageView.image = [UIImage imageNamed:@"notificationIndicator_user_posted"];
            self.notificationTypeImageView.backgroundColor = [UIColor bonfireGreen];
        }
        else if (object.activityType == USER_ACTIVITY_TYPE_POST_MENTION) {
            self.notificationTypeImageView.image = [UIImage imageNamed:@"notificationIndicator_mention"];
            self.notificationTypeImageView.backgroundColor = [UIColor colorWithRed:0.07 green:0.78 blue:1.00 alpha:1.0];
        }
        else {
            // unknown
            self.notificationTypeImageView.image = [UIImage imageNamed:@"Tip_Bonfire"];
            self.notificationTypeImageView.backgroundColor = [UIColor bonfireBrand];
        }
        
        self.creatorTitleLabel.text = [_object.creatorText uppercaseString];
        
        self.titleLabel.hidden = (_object.title.length == 0);
        if (![self.titleLabel isHidden]) {
            self.titleLabel.text = _object.title;
        }
        
        self.textLabel.text = _object.text;
        
        [self layoutSubviews];
        
        self.frame = CGRectMake(self.frame.origin.x, [UIScreen mainScreen].bounds.size.height, self.frame.size.width, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 12);
        self.blurView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
        [self bk_removeAllBlockObservers];
        if (object.action) {
            [self bk_whenTapped:^{
                [[BFNotificationManager manager] hideAllNotifications];
                
                object.action();
            }];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSLog(@"self.transform.a == %f", self.transform.a);
    
    if (self.transform.a == 1) {
        self.closeButton.frame = CGRectMake(self.frame.size.width - self.closeButton.frame.size.width - 12, self.notificationTypeImageView.frame.origin.y + (self.notificationTypeImageView.frame.size.height / 2) - (self.closeButton.frame.size.height / 2), self.closeButton.frame.size.width, self.closeButton.frame.size.height);
        self.creatorTitleLabel.frame = CGRectMake(self.creatorTitleLabel.frame.origin.x, self.notificationTypeImageView.frame.origin.y, (self.closeButton.frame.origin.x - 6) - self.creatorTitleLabel.frame.origin.x, self.notificationTypeImageView.frame.size.height);
        
        if (![self.titleLabel isHidden]) {
            CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (self.titleLabel.frame.origin.x * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:self.titleLabel.font} context:nil].size;
            self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y, self.frame.size.width - (self.titleLabel.frame.origin.x * 2), ceilf(titleSize.height));
        }
        
        CGSize textSize = [self.textLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (self.textLabel.frame.origin.x * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:self.textLabel.font} context:nil].size;
        self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.titleLabel.frame.origin.y + ([self.titleLabel isHidden] ? 0 : self.titleLabel.frame.size.height + 4), self.frame.size.width - (self.textLabel.frame.origin.x * 2), ceilf(textSize.height));
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.object.action) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.transform = CGAffineTransformMakeScale(0.95, 0.95);
        } completion:nil];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.alpha = 1;
    } completion:nil];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.alpha = 1;
    } completion:nil];
}

@end

@implementation BFNotificationObject

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}
+ (BFNotificationObject *)notificationWithActivityType:(USER_ACTIVITY_TYPE)activityType title:(NSString * _Nullable)title text:(NSString *)text action:(void (^ __nullable)(void))actionHandler {
    BFNotificationObject *tipObject = [[BFNotificationObject alloc] init];
    
    tipObject.activityType = activityType;
    
    /*
     switch (activityType) {
     case USER_ACTIVITY_TYPE_USER_FOLLOW: {
     tipObject.creatorText = @"New Follower";
     break;
     }
     case USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS: {
     tipObject.creatorText = @"Camp Update";
     break;
     }
     case USER_ACTIVITY_TYPE_CAMP_ACCESS_REQUEST: {
     tipObject.creatorText = @"Camp Update";
     break;
     }
     case USER_ACTIVITY_TYPE_POST_REPLY: {
     tipObject.creatorText = @"New Reply";
     break;
     }
     case USER_ACTIVITY_TYPE_POST_VOTED: {
     tipObject.creatorText = @"New Spark";
     break;
     }
     case USER_ACTIVITY_TYPE_USER_POSTED:
     USER_ACTIVITY_TYPE_USER_POSTED_CAMP: {
     tipObject.creatorText = @"New Post";
     break;
     }
     case USER_ACTIVITY_TYPE_POST_MENTION: {
     tipObject.creatorText = @"Bonfire";
     break;
     }
     
     default:
     tipObject.creatorText = @"Notifications";
     break;
     }
     */
    tipObject.creatorText = @"Notifications";
    
    tipObject.title = title;
    tipObject.text = text;
    
    tipObject.action = actionHandler;
    
    return tipObject;
}

@end
