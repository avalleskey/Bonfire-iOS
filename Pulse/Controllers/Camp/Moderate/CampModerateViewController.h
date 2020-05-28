//
//  CampModerateViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/7/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Camp.h"
#import "ThemedTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CampModerateViewController : ThemedTableViewController

@property (nonatomic, strong) Camp *camp;

@end

NS_ASSUME_NONNULL_END
