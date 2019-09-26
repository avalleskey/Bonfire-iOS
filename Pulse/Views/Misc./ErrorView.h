//
//  ErrorView.h
//  Pulse
//
//  Created by Austin Valleskey on 10/3/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

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
    ErrorViewTypeSearch
} ErrorViewType;

NS_ASSUME_NONNULL_BEGIN

@interface ErrorView : UIView

- (id)initWithFrame:(CGRect)rect title:(NSString *)title description:(NSString *)description type:(NSInteger)type;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *errorTitle;
@property (nonatomic, strong) UILabel *errorDescription;
@property (nonatomic, strong) UIButton *actionButton;

- (void)updateType:(ErrorViewType)type title:(nullable NSString *)newTitle description:(nullable NSString *)newDescription actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionHandler;

- (void)updateType:(ErrorViewType)newType;
- (void)updateTitle:(nullable NSString *)newTitle;
- (void)updateDescription:(nullable NSString *)newDescription;

@end

NS_ASSUME_NONNULL_END
