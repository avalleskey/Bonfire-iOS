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
    BFDetailItemTypeLocation = 4,
    BFDetailItemTypeWebsite = 5
} BFDetailItemType;

- (id)initWithType:(BFDetailItemType)type value:(NSString *)value action:(void (^_Nullable)(void))action;

@property (nonatomic) BFDetailItemType type;
@property (nonatomic) NSString *value;
@property (nonatomic, copy) void (^_Nullable action)(void);

@property (nonatomic) BOOL selectable;

- (NSString *)prettyValue;

@end

NS_ASSUME_NONNULL_END
