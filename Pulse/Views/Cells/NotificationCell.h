//
//  NotificationCell.h
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NotificationCell : UITableViewCell

typedef enum {
    NotificationTypeUnkown = 0,
    NotificationTypeUserNewFollower = 1,
    NotificationTypeRoomJoinRequest = 2,
    NotificationTypeRoomNewMember = 3,
    NotificationTypeRoomApprovedRequest = 4,
    NotificationTypePostReply = 5,
    NotificationTypePostSparks = 6
} NotificationType;
@property (nonatomic) NotificationType type;

typedef enum {
    NotificationStateOutline = 1,
    NotificationStateFilled = 2
} NotificationState;
@property (nonatomic) NotificationState state;

@property (strong, nonatomic) UIImageView *profilePicture;
@property (strong, nonatomic) UIImageView *typeIndicator;
// @property (strong, nonatomic) UILabel *textLabel; -- inherited from UITableViewCell
@property (strong, nonatomic) UIButton *actionButton;

@end

NS_ASSUME_NONNULL_END
