//
//  RoomSuggestionsListCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HAWebService.h"

@interface RoomCardsListCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource>

typedef enum {
    ROOM_CARD_SIZE_SMALL = 0,
    ROOM_CARD_SIZE_MEDIUM = 1,
    ROOM_CARD_SIZE_LARGE = 2
} ROOM_CARD_SIZE;

@property (strong, nonatomic) HAWebService *manager;

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSMutableArray *rooms;

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL errorLoading;
@property (nonatomic) ROOM_CARD_SIZE size;

@end
