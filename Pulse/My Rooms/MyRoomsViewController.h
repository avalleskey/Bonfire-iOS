//
//  MyRoomsViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 9/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "HAWebService.h"

NS_ASSUME_NONNULL_BEGIN

@interface MyRoomsViewController : UITableViewController <UIScrollViewDelegate>

@property (strong, nonatomic) HAWebService *manager;

@property (strong, nonatomic) UICollectionView *collectionView;
//@property (strong, nonatomic) UIButton *createRoomButton;

@end

NS_ASSUME_NONNULL_END
