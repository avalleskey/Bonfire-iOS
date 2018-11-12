//
//  RSTableView.h
//  Pulse
//
//  Created by Austin Valleskey on 10/4/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

#define UIViewParentController(__view) ({ \
        UIResponder *__responder = __view; \
        while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
        (UIViewController *)__responder; \
        })

#define tableCategoryFeed 1
#define tableCategoryRoom 2
#define tableCategoryProfile 3
#define tableCategoryPost 4

NS_ASSUME_NONNULL_BEGIN

@protocol RSTableViewPaginationDelegate <NSObject>

- (void)tableView:(id)tableView didRequestNextPageWithSinceId:(NSInteger)sinceId;

@end

@interface RSTableView : UITableView <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) id parentObject;
@property (nonatomic) int dataType;

@property BOOL loading;
@property BOOL error;

// pagination
@property BOOL loadingMore;
@property (nonatomic) NSInteger lastSinceId;
- (BOOL)morePosts;

- (void)refresh;

@property (strong, nonatomic) NSMutableArray *data;

@property (nonatomic, weak) id <RSTableViewPaginationDelegate> paginationDelegate;

@end

NS_ASSUME_NONNULL_END
