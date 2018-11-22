//
//  SearchResultsTableView.h
//  Pulse
//
//  Created by Austin Valleskey on 10/13/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RoomSearchTableView : UITableView <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableDictionary *searchResults;
@property (strong, nonatomic) NSMutableArray *recentSearchResults;
    
@property (nonatomic) BOOL showRecents;
@property (nonatomic) int dataType;
    
- (void)emptySearchResults;
@property (nonatomic) CGFloat currentKeyboardHeight;
    
@end

NS_ASSUME_NONNULL_END
