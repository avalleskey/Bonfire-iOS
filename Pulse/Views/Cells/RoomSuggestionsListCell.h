//
//  RoomSuggestionsListCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RoomSuggestionsListCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) NSArray *roomSuggestions;

@property (strong, nonatomic) UICollectionView *collectionView;

@property (nonatomic) BOOL loading;

@property (strong, nonatomic) UIView *lineSeparator;

@end
