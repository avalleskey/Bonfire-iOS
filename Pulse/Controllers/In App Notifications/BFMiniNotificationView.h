//
//  BFMiniNotificationView.h
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

@class BFMiniNotificationObject;

@interface BFMiniNotificationView : UIView

- (id)initWithObject:(BFMiniNotificationObject *)object;
@property (nonatomic) BFMiniNotificationObject *object;

@property (nonatomic, strong) UILabel *textLabel;

@end

@interface BFMiniNotificationObject : NSObject

+ (BFMiniNotificationObject *)notificationWithText:(NSString *)text action:(void (^ __nullable)(void))actionHandler;

@property (nonatomic) NSString *text;

@property (nonatomic, copy) void (^action)(void);

@end

NS_ASSUME_NONNULL_END
