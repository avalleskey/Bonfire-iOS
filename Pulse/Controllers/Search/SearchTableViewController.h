//
//  SearchTableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/30/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchTableViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic) CGFloat currentKeyboardHeight;

typedef enum {
    BFSearchResultsTypeTop = 0,
    BFSearchResultsTypeCamps = 1,
    BFSearchResultsTypeUsers = 2,
    BFSearchResultsTypeFeeds = 3,
    BFSearchResultsTypeTopPosts = 4,
    BFSearchResultsTypeRecentPosts = 5,
    BFSearchResultsTypeHotPosts = 6
} BFSearchResultsType;
@property (nonatomic) BFSearchResultsType resultsType;
- (void)getSearchResults;

- (void)searchFieldDidBeginEditing;
- (void)searchFieldDidChange;
- (void)searchFieldDidEndEditing;
- (void)searchFieldDidReturn;

@end

NS_ASSUME_NONNULL_END
