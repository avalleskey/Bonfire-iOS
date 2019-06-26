//
//  RSTableView.h
//  Pulse
//
//  Created by Austin Valleskey on 10/4/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PostStream.h"
#import "ComposeInputView.h"

#define UIViewParentController(__view) ({ \
        UIResponder *__responder = __view; \
        while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
        (UIViewController *)__responder; \
        })

typedef enum {
    RSTableViewTypeFeed = 1,
    RSTableViewTypeCamp = 2,
    RSTableViewTypeProfile = 3
} RSTableViewType;

typedef enum {
    RSTableViewSubTypeNone = 0,
    RSTableViewSubTypeHome = 1,
    RSTableViewSubTypeTrending = 2
} RSTableViewSubType;


NS_ASSUME_NONNULL_BEGIN

@protocol RSTableViewPaginationDelegate <NSObject>

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId;

@optional
- (void)tableViewDidScroll:(UITableView *)tableView;

@required

@end

@interface RSTableView : UITableView <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

typedef enum {
    RSTableViewStyleDefault = 0,
    RSTableViewStyleGrouped = 1
} RSTableViewStyle;
@property (nonatomic) RSTableViewStyle tableViewStyle;

@property (nonatomic, strong) id parentObject;
@property (nonatomic) RSTableViewType dataType;
@property (nonatomic) RSTableViewSubType dataSubType;

@property BOOL loading;
@property BOOL error;

// pagination
@property BOOL loadingMore;
@property (nonatomic) BOOL reachedBottom;

- (void)refresh;
- (void)scrollToTop;

@property (nonatomic, strong) PostStream *stream;

@property (nonatomic) ComposeInputView *inputView;

@property (nonatomic, weak) id <RSTableViewPaginationDelegate> paginationDelegate;

@end

NS_ASSUME_NONNULL_END
