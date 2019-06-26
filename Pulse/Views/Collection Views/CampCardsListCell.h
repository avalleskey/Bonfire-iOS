//
//  CampCardsListCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HAWebService.h"
#import "SmallCampCardCell.h"
#import "MediumCampCardCell.h"
#import "LargeCampCardCell.h"

@interface CampCardsListCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource>

typedef enum {
    CAMP_CARD_SIZE_SMALL = 0,
    CAMP_CARD_SIZE_MEDIUM = 1,
    CAMP_CARD_SIZE_LARGE = 2
} CAMP_CARD_SIZE;

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray *camps;

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL errorLoading;
@property (nonatomic) CAMP_CARD_SIZE size;

@end
