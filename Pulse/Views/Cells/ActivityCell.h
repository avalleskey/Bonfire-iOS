//
//  NotificationCell.h
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"
#import "UserActivity.h"
#import "BFCampAttachmentView.h"
#import "BFUserAttachmentView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ActivityCell : UITableViewCell

@property (nonatomic) UserActivity *activity;

@property (nonatomic, strong) BFAvatarView *profilePicture;
@property (nonatomic, strong) UIImageView *typeIndicator;

@property (nonatomic, strong) UIImageView *imagePreview;

@property (nonatomic, strong) BFCampAttachmentView * _Nullable campPreviewView;
@property (nonatomic, strong) BFUserAttachmentView * _Nullable userPreviewView;

@property (nonatomic, strong) UIView *lineSeparator;

@property (nonatomic) BOOL unread;

+ (CGFloat)heightForUserActivity:(UserActivity *)activity;

@end

NS_ASSUME_NONNULL_END
