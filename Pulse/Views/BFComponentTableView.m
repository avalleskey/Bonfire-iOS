//
//  BFComponentTableView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/4/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "BFComponentTableView.h"
#import "ComplexNavigationController.h"

#import "CampHeaderCell.h"
#import "ProfileHeaderCell.h"

#import "StreamPostCell.h"
#import "ReplyCell.h"
#import "ExpandThreadCell.h"
#import "ExpandedPostCell.h"
#import "AddReplyCell.h"
#import "BFErrorViewCell.h"

#import "LoadingCell.h"
#import "ButtonCell.h"
#import "PaginationCell.h"
#import "Launcher.h"
#import "BFHeaderView.h"
#import "UIColor+Palette.h"
#import "CampViewController.h"
#import "ProfileCampsListViewController.h"
#import "InsightsLogger.h"

#import "PostViewController.h"

#import <JGProgressHUD/JGProgressHUD.h>
#import <HapticHelper/HapticHelper.h>
@import Firebase;

#define SHOW_CURSORS false

@interface BFComponentTableView () <UIScrollViewDelegate>

@end

@implementation BFComponentTableView

static NSString * const streamPostReuseIdentifier = @"StreamPost";
static NSString * const streamMediaPostReuseIdentifier = @"StreamPost_media";
static NSString * const streamLinkPostReuseIdentifier = @"StreamPost_link";
static NSString * const streamSmartLinkPostReuseIdentifier = @"StreamPost_smart_link";
static NSString * const streamCampPostReuseIdentifier = @"StreamPost_camp";
static NSString * const streamUserPostReuseIdentifier = @"StreamPost_user";
static NSString * const streamPostPostReuseIdentifier = @"StreamPost_post";

static NSString * const postReplyReuseIdentifier = @"ReplyReuseIdentifier";
static NSString * const expandRepliesCellIdentifier = @"ExpandRepliesReuseIdentifier";
static NSString * const addReplyCellIdentifier = @"AddReplyReuseIdentifier";

static NSString * const buttonCellIdentifier = @"ButtonCell";

static NSString * const errorCellReuseIdentifier = @"ErrorCell";
static NSString * const blankCellIdentifier = @"BlankCell";

static NSString * const loadingCellIdentifier = @"LoadingCell";

#pragma mark - Initialization and Setup
- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self setup];
    }
    
    return self;
}
- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}
- (void)setup {
    self.stream = [[PostStream alloc] init];
    self.stream.delegate = self;
    
    self.backgroundColor = [UIColor tableViewBackgroundColor];
    self.loading = true;
    self.loadingMore = false;
    self.delegate = self;
    self.dataSource = self;
    self.separatorColor = [UIColor tableViewSeparatorColor];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    self.estimatedSectionHeaderHeight = 0;
    self.estimatedSectionFooterHeight = 0;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self sendSubviewToBack:self.refreshControl];
    
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamMediaPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamLinkPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamCampPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamUserPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamPostPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamSmartLinkPostReuseIdentifier];
    
    [self registerClass:[ReplyCell class] forCellReuseIdentifier:postReplyReuseIdentifier];
    [self registerClass:[ExpandThreadCell class] forCellReuseIdentifier:expandRepliesCellIdentifier];
    [self registerClass:[AddReplyCell class] forCellReuseIdentifier:addReplyCellIdentifier];
       
    [self registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellIdentifier];
    [self registerClass:[BFErrorViewCell class] forCellReuseIdentifier:errorCellReuseIdentifier];
    [self registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    
    [self registerClass:[LoadingCell class] forCellReuseIdentifier:loadingCellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(campUpdated:) name:@"CampUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUpdated:) name:@"PostUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:@"PostDeleted" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view refresh methods
- (void)hardRefresh:(BOOL)animate {
    if (!self.loading) {
        [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
    }
    
    if (animate) {
        [UIView transitionWithView:self duration:0.2f options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self layoutIfNeeded];
            [self reloadData];
        } completion:nil];
    }
    else {
        [self reloadData];
        [self layoutIfNeeded];
    }
}
- (void)refreshAtTop {
    if (!self.loading) {
        [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
    }
    
    [self reloadData];
    [self layoutIfNeeded];
}
- (void)refreshAtBottom {
    [self reloadData];
}

#pragma mark - NSNotification handlers
- (void)postUpdated:(NSNotification *)notification {
    Post *post = notification.object;
    
    if (post != nil && [self.stream performEventType:PostStreamEventTypePostUpdated object:post]) {
        // Only refresh the table view if view controller is not visible
        if (![[Launcher activeViewController] isEqual:UIViewParentController(self)]) {
            [self hardRefresh:false];
        }
    }
}
- (void)postDeleted:(NSNotification *)notification {
    Post *post = notification.object;
    
    if (post != nil && [self.stream performEventType:PostStreamEventTypePostRemoved object:post]) {
        [self hardRefresh:false];
    }
}
- (void)userUpdated:(NSNotification *)notification {
    User *user = notification.object;
    
    if (user != nil && [self.stream performEventType:PostStreamEventTypeUserUpdated object:user]) {
        [self hardRefresh:false];
    }
}
- (void)campUpdated:(NSNotification *)notification {
    Camp *camp = notification.object;
    
    if (camp != nil && [self.stream performEventType:PostStreamEventTypeCampUpdated object:camp]) {
        [self hardRefresh:false];
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(didSelectRowInFirstSection:)]) {
            return [self.extendedDelegate didSelectRowInFirstSection:indexPath.row];
        }
    }
    else {
        BFPostStreamComponent *component = [self componentAtIndexPath:indexPath];
        
        if (component.action) {
            component.action();
            return;
        }
        
        if ([self.extendedDelegate respondsToSelector:@selector(didSelectComponent:atIndexPath:)]) {
            return [self.extendedDelegate didSelectComponent:component atIndexPath:indexPath];
        }
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        if ([cell isKindOfClass:[PostCell class]]) {
            Post *post = ((PostCell *)cell).post;
            if (post) {
                // Log insight
                [InsightsLogger.sharedInstance closePostInsight:post.identifier action:InsightActionTypeDetailExpand];
                [FIRAnalytics logEventWithName:@"conversation_expand"
                                    parameters:@{
                                                 @"post_id": post.identifier
                                                 }];
                
                // Open post
                [Launcher openPost:post withKeyboard:false];
            }
        }
        else if ([cell isKindOfClass:[ExpandThreadCell class]]) {
            Post *post = component.post;
            if (post) {
                // Log insight
                [InsightsLogger.sharedInstance closePostInsight:post.identifier action:InsightActionTypeDetailExpand];
                [FIRAnalytics logEventWithName:@"conversation_expand"
                                    parameters:@{
                                                 @"post_id": post.identifier
                                                 }];
                
                // Open post
                [Launcher openPost:post withKeyboard:false];
            }
        }
        else if ([cell isKindOfClass:[AddReplyCell class]]) {
            [Launcher openComposePost:((AddReplyCell *)cell).post.attributes.postedIn inReplyTo:((AddReplyCell *)cell).post withMessage:nil media:nil quotedObject:nil];
        }
    }
}
- (void)didBeginDisplayingCell:(UITableViewCell *)cell {
    Post *post;
    if ([cell isKindOfClass:[PostCell class]]) {
        post = ((PostCell *)cell).post;
    }
    else {
        return;
    }
    
    // skip logging if invalid post identifier (most likely due to a loading cell)
    if (post.identifier == 0) return;
            
    if (self.insightSeenInLabel) {
        [InsightsLogger.sharedInstance openPostInsight:post.identifier seenIn:self.insightSeenInLabel];
    }
}
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([tableView.indexPathsForVisibleRows indexOfObject:indexPath] == NSNotFound) {
        Post *post;
        if ([cell isKindOfClass:[PostCell class]]) {
            post = ((PostCell *)cell).post;
        }
        else {
            return;
        }
        
        // skip logging if invalid post identifier (most likely due to a loading cell)
        if (post.identifier == 0) return;
        
        [InsightsLogger.sharedInstance closePostInsight:post.identifier action:nil];
    }
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(cellForRowInFirstSection:)]) {
            UITableViewCell *cell = [self.extendedDelegate cellForRowInFirstSection:indexPath.row];
            if (cell) {
                return cell;
            }
        }
    }
    else if (indexPath.section == 1) {
        if (self.stream.components.count > 0) {
            BFPostStreamComponent *component = [self componentAtIndexPath:indexPath];
            
            if ([component cellClass] == [StreamPostCell class])  {
                // determine if it's a reply or sub-reply
                Post *post = component.post;
                            
                NSString *reuseIdentifier = streamPostReuseIdentifier;
                if (post.attributes.attachments.media) {
                    reuseIdentifier = streamMediaPostReuseIdentifier;
                }
                else if (post.attributes.attachments.link) {
                    if ([post.attributes.attachments.link isSmartLink]) {
                        reuseIdentifier = streamSmartLinkPostReuseIdentifier;
                    }
                    else {
                        reuseIdentifier = streamLinkPostReuseIdentifier;
                    }
                }
                else if (post.attributes.attachments.user) {
                    reuseIdentifier = streamUserPostReuseIdentifier;
                }
                else if (post.attributes.attachments.camp) {
                    reuseIdentifier = streamCampPostReuseIdentifier;
                }
                else if (post.attributes.attachments.post) {
                    reuseIdentifier = streamPostPostReuseIdentifier;
                }

                StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];

                if (cell == nil) {
                    cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
                }

                NSString *identifierBefore = cell.post.identifier;

                cell.showContext = component.detailLevel == BFComponentDetailLevelAll;
                cell.showPostedIn = component.detailLevel == BFComponentDetailLevelAll;
                cell.hideActions = component.detailLevel == BFComponentDetailLevelMinimum;
                
                cell.post = post;

                if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                    [self didBeginDisplayingCell:cell];
                }

                if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
                    [cell.actionsView.replyButton bk_whenTapped:^{
                        [Launcher openComposePost:cell.post.attributes.postedIn inReplyTo:cell.post withMessage:nil media:nil quotedObject:nil];
                    }];
                }
                
                cell.lineSeparator.hidden = !component.showLineSeparator;
                cell.bottomLine.hidden = true;

                return cell;
            }
            else if ([component cellClass] == [ReplyCell class]) {
                ReplyCell *cell = [self dequeueReusableCellWithIdentifier:postReplyReuseIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[ReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postReplyReuseIdentifier];
                }
                
                cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
                
                cell.levelsDeep = -1;
                cell.lineSeparator.hidden = !component.showLineSeparator;
                cell.selectable = YES;
                
                NSString *identifierBefore = cell.post.identifier;
                
                cell.post = component.post;
                
                if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                    [self didBeginDisplayingCell:cell];
                }
                
                return cell;
            }
            else if ([component cellClass] == [ExpandThreadCell class]) {
                // "view more replies"
                ExpandThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:expandRepliesCellIdentifier forIndexPath:indexPath];
                
                if (!cell) {
                    cell = [[ExpandThreadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandRepliesCellIdentifier];
                }
                
                cell.levelsDeep = -1;
                cell.post = component.post;
                cell.lineSeparator.hidden = !component.showLineSeparator;
                
                return cell;
            }
            else if ([component cellClass] == [AddReplyCell class]) {
                AddReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:addReplyCellIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[AddReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addReplyCellIdentifier];
                }
                
                cell.levelsDeep = -1;
                cell.post = component.post;
                cell.lineSeparator.hidden = !component.showLineSeparator;
                
                return cell;
            }
            else if ([component cellClass] == [ButtonCell class]) {
                // "view more replies"
                ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonCellIdentifier forIndexPath:indexPath];
                
                if (!cell) {
                    cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:buttonCellIdentifier];
                }
                
                if ([component.object isKindOfClass:[NSDictionary class]] &&
                    [(NSDictionary *)component.object objectForKey:ButtonCellTitleAttributeName]) {
                    cell.buttonLabel.text = [((NSDictionary *)component.object) valueForKey:ButtonCellTitleAttributeName];
                }
                else {
                    cell.buttonLabel.text = @"";
                }
                
                if ([component.object isKindOfClass:[NSDictionary class]] &&
                    [(NSDictionary *)component.object objectForKey:ButtonCellTitleColorAttributeName]) {
                    cell.buttonLabel.textColor = [((NSDictionary *)component.object) valueForKey:ButtonCellTitleColorAttributeName];
                }
                else {
                    cell.buttonLabel.textColor = cell.kButtonColorBonfire;
                }
                
                cell.buttonLabel.textAlignment = NSTextAlignmentCenter;
                
                cell.bottomSeparator.hidden = !component.showLineSeparator;
                
                return cell;
            }
        }
        else if (self.loading) {
            // loading cell
            LoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[LoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:loadingCellIdentifier];
            }
            
            NSInteger postType = (indexPath.row - 1 % 3);
            cell.type = postType;
            
            cell.userInteractionEnabled = false;
            
            return cell;
        }
        else if (self.visualError) {
            // visual error cell
            BFErrorViewCell *cell = [tableView dequeueReusableCellWithIdentifier:errorCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[BFErrorViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:errorCellReuseIdentifier];
            }
            
            cell.visualError = self.visualError;
            
            return cell;
        }
    }
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 80;
    
    if (indexPath.section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForRowInFirstSection:)]) {
            height = [self.extendedDelegate heightForRowInFirstSection:indexPath.row];
        }
    }
    else if (indexPath.section == 1) {
        if (self.stream.components.count > 0) {
            BFPostStreamComponent *component = [self componentAtIndexPath:indexPath];
            height = component.cellHeight;
        }
        else if (self.loading) {
            switch ((indexPath.row - 1) % 3) {
                case 1:
                    height = 123;
                    break;
                case 2:
                    height = 310 + 56;
                    break;
                    
                default:
                    height = 102;
                    break;
            }
        }
        else if (self.visualError) {
            return [BFErrorViewCell heightForVisualError:self.visualError];
        }
    }
    
    return height;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // 0: First section
    // 1: Temp posts
    // 2: Posts
    
    return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(numberOfRowsInFirstSection)]) {
            return [self.extendedDelegate numberOfRowsInFirstSection];
        }
    }
    else if (section == 1) {
        if (self.stream.components.count > 0) {
            return self.stream.components.count;
        }
        else if (self.loading) {
            return 10;
        }
        else if (self.visualError) {
            return 1;
        }
    }
    
    return 0;
}

- (void)setLoading:(BOOL)loading {
    if (loading != _loading) {
        _loading = loading;
    }
    
    self.scrollEnabled = !loading;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForFirstSectionHeader)]) {
            return [self.extendedDelegate heightForFirstSectionHeader];
        }
    }
    
    return CGFLOAT_MIN;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(viewForFirstSectionHeader)]) {
            return [self.extendedDelegate viewForFirstSectionHeader];
        }
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForFirstSectionFooter)]) {
            return [self.extendedDelegate heightForFirstSectionFooter];
        }
    }
    else if (section == 1 && !self.loading) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = (self.loadingMore || (hasAnotherPage && ![self.stream hasLoadedCursor:self.stream.nextCursor]));
        
        if (showLoadingFooter) {
            return 48;
        }
        else {
            return CGFLOAT_MIN;
        }
    }
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(viewForFirstSectionFooter)]) {
            return [self.extendedDelegate viewForFirstSectionFooter];
        }
    }
    else if (section == 1 && !self.loading) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = (self.loadingMore || (hasAnotherPage && ![self.stream hasLoadedCursor:self.stream.nextCursor]));

        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 48)];
            footer.backgroundColor = [UIColor tableViewBackgroundColor];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.color = [UIColor bonfireSecondaryColor];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 10, footer.frame.size.height / 2 - 10, 20, 20);
            [footer addSubview:spinner];

            [spinner startAnimating];

            if (!self.loadingMore && self.stream.pages.count > 0 && self.stream.nextCursor.length > 0) {
                self.loadingMore = true;

                if ([self.extendedDelegate respondsToSelector:@selector(tableView:didRequestNextPageWithMaxId:)]) {
                    [self.extendedDelegate tableView:self didRequestNextPageWithMaxId:0];
                }
            }
            
            return footer;
        }
    }
    
    return nil;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self && [self.extendedDelegate respondsToSelector:@selector(tableViewDidScroll:)]) {
        [self.extendedDelegate tableViewDidScroll:self];
                
        UINavigationController *navController = UIViewParentController(self).navigationController;
        if (navController) {
            if ([navController isKindOfClass:[ComplexNavigationController class]]) {
                ComplexNavigationController *complexNav = (ComplexNavigationController *)navController;
                [complexNav childTableViewDidScroll:self];
            }
            else if ([navController isKindOfClass:[SimpleNavigationController class]]) {
                SimpleNavigationController *simpleNav = (SimpleNavigationController *)navController;
                [simpleNav childTableViewDidScroll:self];
            }
        }
    }
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView == self && [self.extendedDelegate respondsToSelector:@selector(tableViewDidEndDragging:willDecelerate:)]) {
        [self.extendedDelegate tableViewDidEndDragging:self willDecelerate:decelerate];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self) {
        if ([self.extendedDelegate respondsToSelector:@selector(tableViewDidEndDecelerating:)]) {
            [self.extendedDelegate tableViewDidEndDecelerating:self];
        }
    }
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self) {
        self.userInteractionEnabled = true;
        [self fireOnScrollBlockIfNeeded];
    }
}
- (void)fireOnScrollBlockIfNeeded {
    if (self.onScrollBlock) {
        self.onScrollBlock();
        
        self.onScrollBlock = nil;
    }
}

#pragma mark - SectionStreamDelegate
- (void)postStreamDidUpdate:(PostStream *)stream {
    if (stream == _stream) {
        
    }
}

#pragma mark - Scroll to top
- (void)scrollToTop {
    [self layoutIfNeeded];
    [self scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:true];
}
- (void)scrollToTopWithCompletion:(void (^ __nullable)(void))completion {
    self.userInteractionEnabled = false;
    
    [self layoutIfNeeded];
    
    self.onScrollBlock = ^void(void){
        completion();
    };
    
    CGFloat normalizedScrollViewContentOffsetY = self.contentOffset.y + self.adjustedContentInset.top;
    if (normalizedScrollViewContentOffsetY == 0) {
        // doesn't need to scroll therefore it won't call the function we need to fire
        [self scrollViewDidEndScrollingAnimation:self];
    }
    else {
        [self scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:true];
    }
}

#pragma mark - Misc. Helper Methods
- (BFPostStreamComponent * _Nullable)componentAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.stream.components.count) {
        return nil;
    }
    
    return self.stream.components[indexPath.row];
}

#pragma mark - UIContextMenuConfiguration
- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)){
    if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[PostCell class]]) {
        Post *post = ((PostCell *)[tableView cellForRowAtIndexPath:indexPath]).post;
        
        if (post) {
            NSMutableArray *actions = [NSMutableArray new];
            if ([post.attributes.context.post.permissions canReply]) {
                UIAction *replyAction = [UIAction actionWithTitle:@"Reply" image:[UIImage systemImageNamed:@"arrowshape.turn.up.left"] identifier:@"reply" handler:^(__kindof UIAction * _Nonnull action) {
                    wait(0, ^{
                        [Launcher openComposePost:post.attributes.postedIn inReplyTo:post withMessage:nil media:nil  quotedObject:nil];
                    });
                }];
                [actions addObject:replyAction];
            }
            
            UIAction *quoteAction = [UIAction actionWithTitle:@"Quote" image:[UIImage systemImageNamed:@"quote.bubble"] identifier:@"quote" handler:^(__kindof UIAction * _Nonnull action) {
                wait(0, ^{
                    [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil  quotedObject:post];
                });
            }];
            [actions addObject:quoteAction];
            
            if (post.attributes.postedIn) {
                UIAction *openCamp = [UIAction actionWithTitle:@"Open Camp" image:[UIImage systemImageNamed:@"number"] identifier:@"open_camp" handler:^(__kindof UIAction * _Nonnull action) {
                    wait(0, ^{
                        Camp *camp = [[Camp alloc] initWithDictionary:[post.attributes.postedIn toDictionary] error:nil];
                        
                        [Launcher openCamp:camp];
                    });
                }];
                [actions addObject:openCamp];
            }
            
            UIAction *shareViaAction = [UIAction actionWithTitle:@"Share via..." image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:@"share_via" handler:^(__kindof UIAction * _Nonnull action) {
                [Launcher sharePost:post];
            }];
            [actions addObject:shareViaAction];
            
            UIMenu *menu = [UIMenu menuWithTitle:@"" children:actions];
            
            PostViewController *postVC = [Launcher postViewControllerForPost:post];
            postVC.isPreview = true;
            
            UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:indexPath previewProvider:^(){return postVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
            return configuration;
        }
    }
    
    return nil;
}
- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    void(^completionAction)(void);
    
    if ([animator.previewViewController isKindOfClass:[PostViewController class]]) {
        PostViewController *p = (PostViewController *)animator.previewViewController;
        completionAction = ^{
            SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:p];
            newNavController.transitioningDelegate = [Launcher sharedInstance];
            [newNavController setLeftAction:SNActionTypeBack];
            newNavController.currentTheme = p.theme;
            
            [Launcher push:newNavController animated:YES];
        };
    }

    [animator addCompletion:^{
        wait(0, ^{
            if (completionAction) {
                completionAction();
            }
        });
    }];
}

@end
