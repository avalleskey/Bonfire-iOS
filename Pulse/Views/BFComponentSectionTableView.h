//
//  BFComponentTableView.h
//  Pulse
//
//  Created by Austin Valleskey on 10/4/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SectionStream.h"
#import "ComposeInputView.h"
#import "BFVisualErrorView.h"
#import "InsightsLogger.h"

typedef enum {
    BFComponentTableViewTypeFeed = 1,
    BFComponentTableViewTypeCamp = 2,
    BFComponentTableViewTypeProfile = 3
} BFComponentTableViewType;

typedef enum {
    BFComponentTableViewSubTypeNone = 0,
    BFComponentTableViewSubTypeHome = 1,
    BFComponentTableViewSubTypeTrending = 2
} BFComponentTableViewSubType;


NS_ASSUME_NONNULL_BEGIN

@protocol BFComponentSectionTableViewDelegate <NSObject>

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId;

@optional
- (void)tableViewDidScroll:(UITableView *)tableView;
- (void)tableViewDidEndDragging:(UITableView *)tableView willDecelerate:(BOOL)decelerate;
- (void)tableViewDidEndDecelerating:(UITableView *)tableView;

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

@interface BFComponentSectionTableView : UITableView <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, SectionStreamDelegate>

@property (nonatomic, strong) BFVisualError * _Nullable  visualError;
@property (nonatomic, strong) NSString *insightSeenInLabel;

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL loadingMore;
@property (nonatomic, copy, nullable) void (^onScrollBlock)(void);

@property (strong, nonatomic) NSMutableDictionary *cellHeightsDictionary;

- (void)refreshAtTop;
- (void)hardRefresh:(BOOL)animate;
- (void)refreshAtBottom;
- (void)scrollToTop;
- (void)scrollToTopWithCompletion:(void (^ __nullable)(void))completion;

@property (nonatomic, strong) SectionStream *stream;

@property (nonatomic, weak) id <BFComponentSectionTableViewDelegate> extendedDelegate;

@end

NS_ASSUME_NONNULL_END
