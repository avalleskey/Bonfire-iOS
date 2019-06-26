//
//  BFNotificationManager.h
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BFNotificationView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFNotificationManager : NSObject

+ (BFNotificationManager *)manager;

@property (nonatomic) BOOL presenting;

@property (nonatomic, strong) NSMutableArray <BFNotificationView *> * notifications;
- (void)presentNotification:(BFNotificationObject *)notificationObject completion:(void (^)(void))completion;
- (void)presentNotificationView:(BFNotificationView *)notificationView completion:(void (^ __nullable)(void))completion;
- (void)hideAllNotifications;

@end

NS_ASSUME_NONNULL_END
