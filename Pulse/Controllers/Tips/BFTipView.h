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
    BFTipViewStyleDark = 1,
    BFTipViewStyleTable = 2
} BFTipViewStyle;
@property (nonatomic) BFTipViewStyle style;

- (id)initWithObject:(BFTipObject *)object;
@property (nonatomic) BFTipObject *object;

@property (nonatomic, strong) BFAvatarView *creatorAvatarView;
@property (nonatomic, strong) UILabel *creatorTitleLabel;
@property (nonatomic, strong) TappableButton *closeButton;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIButton *cta;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIVisualEffectView *blurView;

@property (nonatomic) BOOL dragToDismiss;

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

+ (BFTipObject *)tipWithCreatorType:(BFTipCreatorType)creatorType creator:(id _Nullable)creator title:(NSString * _Nullable)title text:(NSString *)text cta:(NSString * _Nullable)cta imageUrl:(NSString * _Nullable)imageUrl action:(void (^ __nullable)(void))actionHandler;

@property (nonatomic) BFTipCreatorType creatorType;
@property (nonatomic) id creator;

@property (nonatomic) NSString *creatorText;
@property (nonatomic) UIImage *creatorAvatar;

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *imageUrl;

@property (nonatomic) NSString *cta;

@property (nonatomic, copy) void (^action)(void);

@end

NS_ASSUME_NONNULL_END
