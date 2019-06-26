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

NS_ASSUME_NONNULL_BEGIN

@class BFTipObject;

@interface BFTipView : UIView

typedef enum {
    BFTipViewStyleLight = 0,
    BFTipViewStyleDark = 1
} BFTipViewStyle;
@property (nonatomic) BFTipViewStyle style;

- (id)initWithObject:(BFTipObject *)object;
@property (nonatomic) BFTipObject *object;

@property (nonatomic, strong) BFAvatarView *creatorAvatarView;
@property (nonatomic, strong) UILabel *creatorTitleLabel;
@property (nonatomic, strong) TappableButton *closeButton;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, strong) UIVisualEffectView *blurView;

@end

@interface BFTipObject : NSObject

typedef enum {
    BFTipCreatorTypeBonfireGeneric,
    BFTipCreatorTypeBonfireTip,
    BFTipCreatorTypeBonfireFunFacts,
    BFTipCreatorTypeBonfireSupport,
    BFTipCreatorTypeCamp,
    BFTipCreatorTypeUser
} BFTipCreatorType;

+ (BFTipObject *)tipWithCreatorType:(BFTipCreatorType)creatorType creator:(id _Nullable)creator title:(NSString * _Nullable)title text:(NSString *)text action:(void (^ __nullable)(void))actionHandler;

@property (nonatomic) BFTipCreatorType creatorType;
@property (nonatomic) id creator;

@property (nonatomic) NSString *creatorText;
@property (nonatomic) UIImage *creatorAvatar;

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *text;

@end

NS_ASSUME_NONNULL_END
