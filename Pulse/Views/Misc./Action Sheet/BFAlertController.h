//
//  BFAlertController.h
//  Pulse
//
//  Created by Austin Valleskey on 4/6/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BFAlertActionStyle) {
    BFAlertActionStyleDefault = 0,
    BFAlertActionStyleCancel,
    BFAlertActionStyleDestructive,
    BFAlertActionStyleSemiDestructive,
    BFAlertActionStyleSpacer
};

typedef NS_ENUM(NSInteger, BFAlertControllerStyle) {
    BFAlertControllerStyleActionSheet = 0,
    BFAlertControllerStyleAlert
};

@class AlertViewControllerPresenter;

@interface BFAlertAction : NSObject <NSCopying>

+ (instancetype)actionWithTitle:(nullable NSString *)title style:(BFAlertActionStyle)style handler:(void (^ __nullable)(void))actionHandler;
+ (instancetype)actionWithTitle:(nullable NSString *)title iconName:(nullable NSString *)iconName style:(BFAlertActionStyle)style handler:(void (^ __nullable)(void))actionHandler;

@property (nullable, nonatomic, strong) NSString *title;
@property (nullable, nonatomic, strong) UIImage *icon;
@property (nonatomic, readonly) BFAlertActionStyle style;
@property (nonatomic, strong) void (^actionHandler)(void);
@property (nonatomic, getter=isEnabled) BOOL enabled;

@end

@interface BFAlertActionIcon : NSObject

extern NSString * const BFAlertActionIconCamera;
extern NSString * const BFAlertActionIconPhotoLibrary;
extern NSString * const BFAlertActionIconTwitter;
extern NSString * const BFAlertActionIconFacebook;
extern NSString * const BFAlertActionIconSnapchat;
extern NSString * const BFAlertActionIconInstagramStories;
extern NSString * const BFAlertActionIconImessage;
extern NSString * const BFAlertActionIconBonfire;
extern NSString * const BFAlertActionIconCopyLink;
extern NSString * const BFAlertActionIconCamp;
extern NSString * const BFAlertActionIconQuote;
extern NSString * const BFAlertActionIconReport;
extern NSString * const BFAlertActionIconMute;
extern NSString * const BFAlertActionIconUnMute;
extern NSString * const BFAlertActionIconOther;
+ (NSString *)iconNameWithTitle:(NSString *)title;

@end

@interface BFAlertController : UIViewController

+ (instancetype)alertControllerWithPreferredStyle:(BFAlertControllerStyle)preferredStyle;
+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(BFAlertControllerStyle)preferredStyle;
+ (instancetype)alertControllerWithIcon:(nullable UIImage *)icon title:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(BFAlertControllerStyle)preferredStyle;

@property (nonatomic, strong) AlertViewControllerPresenter *presenter;
- (void)show;
- (void)dismissWithCompletion:(void (^ _Nullable)(void))completion;
- (void)dismissWithAnimation:(BOOL)animation completion:(void (^ _Nullable)(void))completion;

- (void)addAction:(BFAlertAction *)action;
@property (nonatomic, strong) NSMutableArray<BFAlertAction *> *actions;

- (void)addSpacer;

// Preferred action is bold
@property (nonatomic, strong, nullable) BFAlertAction *preferredAction;

@property (nonatomic, strong, nullable) UIView *headerView;
@property (nullable, nonatomic, copy) UIImage *icon;
@property (nullable, nonatomic, copy) NSString *message;
@property (nonatomic, strong, nullable) UITextField *textField;

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic, readonly) BFAlertControllerStyle preferredStyle;

@end

@interface AlertViewControllerPresenter : UIViewController

@property UIWindow *win;

@end

NS_ASSUME_NONNULL_END
