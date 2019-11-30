//
//  NotificationsTableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThemedTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NotificationsTableViewController : ThemedTableViewController <UITableViewDelegate, UITableViewDataSource>

enum {
    MAX_CACHED_ACTIVITIES = 40
};

@property (nonatomic, strong) NSDate *lastFetch;
- (void)refreshIfNeeded;
- (void)markAllAsRead;

@end

NS_ASSUME_NONNULL_END
