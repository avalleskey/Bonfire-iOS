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
    BFAlertActionStyleDestructive
};

typedef NS_ENUM(NSInteger, BFAlertControllerStyle) {
    BFAlertControllerStyleActionSheet = 0,
    BFAlertControllerStyleAlert
};

@interface BFAlertAction : NSObject <NSCopying>

+ (instancetype)actionWithTitle:(nullable NSString *)title style:(BFAlertActionStyle)style handler:(void (^ __nullable)(BFAlertAction *action))handler;

@property (nullable, nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BFAlertActionStyle style;
@property (nonatomic, getter=isEnabled) BOOL enabled;

@end

@interface BFAlertController : UIViewController

+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(BFAlertControllerStyle)preferredStyle;

- (void)addAction:(BFAlertAction *)action;
@property (nonatomic, readonly) NSArray<BFAlertAction *> *actions;

// Preferred action is bold
@property (nonatomic, strong, nullable) BFAlertAction *preferredAction;

@property (nonatomic, strong, nullable) UIView *header;
@property (nullable, nonatomic, copy) NSString *message;

@property (nonatomic, readonly) BFAlertControllerStyle preferredStyle;

@end

NS_ASSUME_NONNULL_END
