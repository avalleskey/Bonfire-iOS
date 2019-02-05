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
    ErrorViewTypeClock
} ErrorViewType;

NS_ASSUME_NONNULL_BEGIN

@interface ErrorView : UIView

- (id)initWithFrame:(CGRect)rect title:(NSString *)title description:(NSString *)description type:(NSInteger)type;

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *errorTitle;
@property (strong, nonatomic) UILabel *errorDescription;

- (void)updateType:(ErrorViewType)newType;
- (void)updateTitle:(nullable NSString *)newTitle;
- (void)updateDescription:(nullable NSString *)newDescription;

@end

NS_ASSUME_NONNULL_END
