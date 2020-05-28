//
//  BFDetailsCollectionView.h
//  Pulse
//
//  Created by Austin Valleskey on 4/17/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BFDetailItem;

@interface BFDetailsCollectionView : UICollectionView <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) NSArray <BFDetailItem *> *details;

@end

@interface BFDetailItem : NSObject

typedef enum {
    BFDetailItemTypePrivacyPublic = 1,
    BFDetailItemTypePrivacyPrivate = 2,
    BFDetailItemTypeMembers = 3,
    BFDetailItemTypeSubscribers = 4,
    BFDetailItemTypeLocation = 5,
    BFDetailItemTypeWebsite = 6,
    BFDetailItemTypeSourceLink = 7,
    BFDetailItemTypeSourceUser = 8,
    BFDetailItemTypeSourceLink_Feed = 9,
    BFDetailItemTypeSourceUser_Feed = 10,
    BFDetailItemTypePostNotificationsOn = 11,
    BFDetailItemTypePostNotificationsOff = 12,
    BFDetailItemTypeEdit = 13,
    BFDetailItemTypeCreatedAt = 14,
    BFDetailItemTypeJoinedAt = 15,
    BFDetailItemTypeMatureContent = 16
} BFDetailItemType;

- (id)initWithType:(BFDetailItemType)type value:(NSString *)value action:(void (^_Nullable)(void))action;

@property (nonatomic) BFDetailItemType type;
@property (nonatomic) NSString *value;
@property (nonatomic, copy) void (^_Nullable action)(void);

@property (nonatomic) BOOL selectable;

- (NSString *)prettyValue;

@end

NS_ASSUME_NONNULL_END
