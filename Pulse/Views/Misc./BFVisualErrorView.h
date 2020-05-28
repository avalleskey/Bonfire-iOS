//
//  ErrorView.h
//  Pulse
//
//  Created by Austin Valleskey on 10/3/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BFVisualError;

@interface BFVisualErrorView : UIView

- (id)initWithVisualError:(BFVisualError *)visualError;
@property (nonatomic, strong) BFVisualError * _Nullable visualError;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *errorTitle;
@property (nonatomic, strong) UILabel *errorDescription;
@property (nonatomic, strong) UIButton *actionButton;

- (void)resize;

@end

@interface BFVisualError : NSObject

typedef enum : NSUInteger {
    ErrorViewTypeGeneral,
    ErrorViewTypeBlocked,
    ErrorViewTypeNotFound,
    ErrorViewTypeNoInternet,
    ErrorViewTypeLocked,
    ErrorViewTypeHeart,
    ErrorViewTypeNoPosts,
    ErrorViewTypeNoNotifications,
    ErrorViewTypeContactsDenied,
    ErrorViewTypeClock,
    ErrorViewTypeSearch,
    ErrorViewTypeRepliesDisabled,
    ErrorViewTypeFirstPost
} ErrorViewType;

+ (BFVisualError *)visualErrorOfType:(NSInteger)errorType title:(NSString * _Nullable)errorTitle description:(NSString * _Nullable)errorDescription actionTitle:(NSString * _Nullable)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock;

@property (nonatomic) ErrorViewType errorType;
@property (nonatomic, strong) NSString *errorTitle;
@property (nonatomic, strong) NSString *errorDescription;
@property (nonatomic, strong) NSString *actionTitle;
@property (nonatomic, copy) void (^actionBlock)(void);

@end

NS_ASSUME_NONNULL_END
