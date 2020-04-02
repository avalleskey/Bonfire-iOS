//
//  BFComponentTableView.h
//  Pulse
//
//  Created by Austin Valleskey on 10/4/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PostStream.h"
#import "ComposeInputView.h"
#import "BFVisualErrorView.h"
#import "InsightsLogger.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BFComponentTableViewDelegate <NSObject>

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId;

@optional
- (void)tableViewDidScroll:(UITableView *)tableView;
- (void)tableViewDidEndDragging:(UITableView *)tableView willDecelerate:(BOOL)decelerate;
- (void)tableViewDidEndDecelerating:(UITableView *)tableView;

- (void)didSelectComponent:(BFStreamComponent *)component atIndexPath:(NSIndexPath *)indexPath;

- (UITableViewCell * _Nullable)cellForRowInFirstSection:(NSInteger)row;
- (void)didSelectRowInFirstSection:(NSInteger)row;
- (CGFloat)heightForRowInFirstSection:(NSInteger)row;
- (CGFloat)numberOfRowsInFirstSection;

- (UIView * _Nullable)viewForFirstSectionHeader;
- (CGFloat)heightForFirstSectionHeader;

- (UIView * _Nullable)viewForFirstSectionFooter;
- (CGFloat)heightForFirstSectionFooter;

@required

@end

@interface BFComponentTableView : UITableView <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, PostStreamDelegate>

@property (nonatomic, strong) BFVisualError * _Nullable  visualError;
@property (nonatomic, strong) NSString *insightSeenInLabel;

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL loadingMore;
@property (nonatomic, copy, nullable) void (^onScrollBlock)(void);

typedef enum {
    BFComponentTableViewLoadingStyleShimmer = 0,
    BFComponentTableViewLoadingStyleSpinner = 1
} BFComponentTableViewLoadingStyle;
@property (nonatomic) BFComponentTableViewLoadingStyle loadingStyle;

@property (strong, nonatomic) NSMutableDictionary *cellHeightsDictionary;

- (void)refreshAtTop;
- (void)hardRefresh:(BOOL)animate;
- (void)refreshAtBottom;
- (void)scrollToTop;
- (void)scrollToTopWithCompletion:(void (^ __nullable)(void))completion;

- (void)didBeginDisplayingCell:(UITableViewCell *)cell;

@property (nonatomic, strong) PostStream *stream;

@property (nonatomic, weak) id <BFComponentTableViewDelegate> extendedDelegate;

@end

NS_ASSUME_NONNULL_END
