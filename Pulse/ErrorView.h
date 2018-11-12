//
//  ErrorView.h
//  Pulse
//
//  Created by Austin Valleskey on 10/3/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const NSInteger ErrorViewTypeGeneral;
extern const NSInteger ErrorViewTypeBlocked;
extern const NSInteger ErrorViewTypeNotFound;
extern const NSInteger ErrorViewTypeNoInternet;
extern const NSInteger ErrorViewTypeLocked;
extern const NSInteger ErrorViewTypeHeart;
extern const NSInteger ErrorViewTypeNoPosts;

NS_ASSUME_NONNULL_BEGIN

@interface ErrorView : UIView

- (id)initWithFrame:(CGRect)rect title:(NSString *)title description:(NSString *)description type:(NSInteger)type;

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *errorTitle;
@property (strong, nonatomic) UILabel *errorDescription;

- (void)updateType:(NSInteger)newType;
- (void)updateTitle:(NSString *)newTitle;
- (void)updateDescription:(NSString *)newDescription;

@end

NS_ASSUME_NONNULL_END
