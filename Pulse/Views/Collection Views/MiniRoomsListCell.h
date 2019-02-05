//
//  MiniRoomCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HAWebService.h"

@interface MiniRoomsListCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) HAWebService *manager;

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) UIView *header;
@property (strong, nonatomic) UILabel *bigTitle;
@property (strong, nonatomic) UILabel *title;

@property (strong, nonatomic) NSMutableArray *rooms;

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL errorLoading;

@end
