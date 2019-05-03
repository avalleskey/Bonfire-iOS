//
//  MyRoomsViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 9/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyRoomsViewController : UITableViewController <UIScrollViewDelegate>

@property (strong, nonatomic) UIButton *createRoomButton;

@end

NS_ASSUME_NONNULL_END
