//
//  BFTipView.h
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"
#import "TappableButton.h"
#import "UserActivity.h"

NS_ASSUME_NONNULL_BEGIN

@class BFNotificationObject;

@interface BFNotificationView : UIView

typedef enum {
    BFNotificationViewStyleLight = 0,
    BFNotificationViewStyleDark = 1
} BFNotificationViewStyle;
@property (nonatomic) BFNotificationViewStyle style;

- (id)initWithObject:(BFNotificationObject *)object;
@property (nonatomic) BFNotificationObject *object;

@property (nonatomic, strong) UIImageView *notificationTypeImageView;
@property (nonatomic, strong) UILabel *creatorTitleLabel;
@property (nonatomic, strong) TappableButton *closeButton;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, strong) UIVisualEffectView *blurView;

@property (nonatomic, strong) NSDictionary *userInfo;

@end

@interface BFNotificationObject : NSObject

+ (BFNotificationObject *)notificationWithActivityType:(USER_ACTIVITY_TYPE)activityType title:(NSString * _Nullable)title text:(NSString *)text action:(void (^ __nullable)(void))actionHandler;

@property (nonatomic) USER_ACTIVITY_TYPE activityType;
@property (nonatomic) id creator;

@property (nonatomic) NSString *creatorText;
@property (nonatomic) UIImage *creatorAvatar;

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *text;

@property (nonatomic, copy) void (^action)(void);

@end

NS_ASSUME_NONNULL_END
