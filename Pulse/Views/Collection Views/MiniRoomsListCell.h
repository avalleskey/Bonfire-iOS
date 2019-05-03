//
//  MiniRoomCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MiniRoomsListCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UILabel *bigTitle;
@property (nonatomic, strong) UILabel *title;

@property (nonatomic, strong) NSMutableArray *rooms;

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL errorLoading;

@end
