//
//  EditRoomViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"

NS_ASSUME_NONNULL_BEGIN

@interface EditRoomViewController : UITableViewController

@property (nonatomic, strong) Room *room;

@property (nonatomic, strong) UIView *navigationBackgroundView;

@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *saveButton;

@property (nonatomic, strong) UIColor *themeColor;

- (void)updateBarColor:(id)newColor withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay;

@end

NS_ASSUME_NONNULL_END
