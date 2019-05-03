//
//  RoomSuggestionsListCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RoomSuggestionsListCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic) BOOL loading;

@property (nonatomic, strong) NSArray *roomSuggestions;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *lineSeparator;

@end
