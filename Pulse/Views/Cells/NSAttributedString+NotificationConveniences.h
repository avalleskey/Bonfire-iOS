//
//  NSAttributedString+NotificationConveniences.h
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NotificationCell.h"
#import "Room.h"
#import "User.h"
#import "UserActivity.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (NotificationConveniences)

+ (NSAttributedString *)attributedStringForActivity:(UserActivity *)activity;

@end

NS_ASSUME_NONNULL_END
