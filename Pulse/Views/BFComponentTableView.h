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

#define UIViewParentController(__view) ({ \
        UIResponder *__responder = __view; \
        while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
        (UIViewController *)__responder; \
        })

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

@protocol BFComponentTableViewDelegate <NSObject>

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

@interface BFComponentTableView : UITableView <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, SectionStreamDelegate>

@property (nonatomic, strong) BFVisualError * _Nullable  visualError;
@property BOOL includeContext;

@property BOOL loading;
@property BOOL loadingMore;
@property (nonatomic, copy, nullable) void (^onScrollBlock)(void);

@property (strong, nonatomic) NSMutableDictionary *cellHeightsDictionary;

- (void)refreshAtTop;
- (void)hardRefresh:(BOOL)animate;
- (void)refreshAtBottom;
- (void)scrollToTop;
- (void)scrollToTopWithCompletion:(void (^ __nullable)(void))completion;

@property (nonatomic, strong) SectionStream *stream;

@property (nonatomic, weak) id <BFComponentTableViewDelegate> extendedDelegate;

@end

NS_ASSUME_NONNULL_END
