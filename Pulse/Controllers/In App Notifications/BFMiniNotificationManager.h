//
//  BFMiniNotificationManager.h
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BFMiniNotificationView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFMiniNotificationManager : NSObject

+ (BFMiniNotificationManager *)manager;

@property (nonatomic) BOOL presenting;

@property (nonatomic, strong) NSMutableArray <BFMiniNotificationView *> * notifications;
- (void)presentNotification:(BFMiniNotificationObject *)notificationObject completion:(void (^_Nullable)(void))completion;
- (void)presentNotificationView:(BFMiniNotificationView *)notificationView completion:(void (^ _Nullable)(void))completion;
- (void)hideAllNotifications;

@end

NS_ASSUME_NONNULL_END
