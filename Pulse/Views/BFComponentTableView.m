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
#import "BFSectionHeaderCell.h"
#import "ButtonCell.h"

#import "LoadingCell.h"
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

static NSString * const expandedPostReuseIdentifier = @"ExpandedPost";

static NSString * const headerCellReuseIdentifier = @"HeaderCellReuseIdentifier";

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

static NSString * const buttonCellReuseIdentifier = @"ButtonCellReuseIdentifier";

static NSString * const previewReuseIdentifier = @"PreviewPost";
static NSString * const errorCellReuseIdentifier = @"ErrorCell";
static NSString * const blankCellIdentifier = @"BlankCell";

static NSString * const loadingCellIdentifier = @"LoadingCell";
static NSString * const paginationCellIdentifier = @"PaginationCell";

#pragma mark - Initialization and Setup
- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:UITableViewStyleGrouped];
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
    self.stream = [[SectionStream alloc] init];
    self.stream.delegate = self;
    
    self.backgroundColor = [UIColor tableViewBackgroundColor];
    self.loading = true;
    self.loadingMore = false;
    self.delegate = self;
    self.dataSource = self;
    self.separatorColor = [UIColor tableViewSeparatorColor];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    self.estimatedRowHeight = 0;
    self.estimatedSectionHeaderHeight = 0;
    self.estimatedSectionFooterHeight = 0;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self sendSubviewToBack:self.refreshControl];
        
    [self registerClass:[ExpandedPostCell class] forCellReuseIdentifier:expandedPostReuseIdentifier];
    
    [self registerClass:[BFSectionHeaderCell class] forCellReuseIdentifier:headerCellReuseIdentifier];
    
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
    
    [self registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellReuseIdentifier];
    
    [self registerClass:[BFErrorViewCell class] forCellReuseIdentifier:errorCellReuseIdentifier];
    [self registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    
    [self registerClass:[LoadingCell class] forCellReuseIdentifier:loadingCellIdentifier];
    [self registerClass:[PaginationCell class] forCellReuseIdentifier:paginationCellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUpdated:) name:@"PostUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:@"PostDeleted" object:nil];
}

#pragma mark - Table view refresh methods
- (void)hardRefresh:(BOOL)animate {
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
    
    if (!self.loading) {
        [self.refreshControl endRefreshing];
    }
}
- (void)refreshAtTop {
    [self layoutIfNeeded];
    CGSize beforeContentSize = self.contentSize;
    
    BOOL wasLoading = ([[self.visibleCells firstObject] isKindOfClass:[LoadingCell class]]);
    
    [self reloadData];
    
    [self layoutIfNeeded];
        
    if (!self.loading) {
        [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        
        if (!wasLoading) {
            CGSize afterContentSize = self.contentSize;

            CGPoint afterContentOffset = self.contentOffset;
            CGPoint newContentOffset = CGPointMake(afterContentOffset.x, MAX(afterContentOffset.y + afterContentSize.height - beforeContentSize.height, -1 * self.adjustedContentInset.top));
            
            self.contentOffset = newContentOffset;
        }
    }
}
- (void)refreshAtBottom {
    [self reloadData];
}

#pragma mark - NSNotification handlers
- (void)postUpdated:(NSNotification *)notification {
    Post *post = notification.object;
    
    if (post != nil && [self.stream performEventType:SectionStreamEventTypePostUpdated object:post]) {
        // Only refresh the table view if view controller is not visible
        if (![[Launcher activeViewController] isEqual:UIViewParentController(self)]) {
            [self hardRefresh:false];
        }
    }
}
- (void)postDeleted:(NSNotification *)notification {
    Post *post = notification.object;
    
    if (post != nil && [self.stream performEventType:SectionStreamEventTypePostRemoved object:post]) {
        // Only refresh the table view if view controller is not visible
        if (![[Launcher activeViewController] isEqual:UIViewParentController(self)]) {
            [self hardRefresh:false];
        }
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
        else if ([cell isKindOfClass:[AddReplyCell class]]) {
            [Launcher openComposePost:((AddReplyCell *)cell).post.attributes.postedIn inReplyTo:((AddReplyCell *)cell).post withMessage:nil media:nil quotedObject:nil];
        }
        else {
            Section *s = [self sectionAtIndexPath:indexPath];
            BFComponent *component = [self componentAtIndexPath:indexPath];
            
            if (component.cellClass == [ButtonCell class]) {
                id targetObject = s.attributes.cta.target.camp;
                
                if ([targetObject isKindOfClass:[Camp class]]) {
                    [Launcher openCamp:(Camp *)targetObject];
                }
                else if ([targetObject isKindOfClass:[User class]]) {
                    [Launcher openProfile:(User *)targetObject];
                }
                else if ([targetObject isKindOfClass:[Bot class]]) {
                    [Launcher openBot:(Bot *)targetObject];
                }
            }
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
            
    NSString *seenIn = InsightSeenInHomeView;
//    switch (self.dataType) {
//        case BFComponentTableViewTypeFeed:
//            if (self.dataSubType == BFComponentTableViewSubTypeHome) {
//                seenIn = InsightSeenInHomeView;
//            }
//            if (self.dataSubType == BFComponentTableViewSubTypeTrending) {
//                seenIn = InsightSeenInTrendingView;
//            }
//            break;
//        case BFComponentTableViewTypeCamp:
//            seenIn = InsightSeenInCampView;
//            break;
//        case BFComponentTableViewTypeProfile:
//            seenIn = InsightSeenInProfileView;
//            break;
//    }
    
    //
//    [InsightsLogger.sharedInstance openPostInsight:post.identifier seenIn:seenIn];
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
            return [self.extendedDelegate cellForRowInFirstSection:indexPath.row];
        }
    }
    else if (self.stream.sections.count  > 0) {
        Section *s = [self sectionAtIndexPath:indexPath];
        BFComponent *component = [self componentAtIndexPath:indexPath];
        
        if (component.cellClass == [BFSectionHeaderCell class]) {
            BFSectionHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:headerCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[BFSectionHeaderCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:headerCellReuseIdentifier];
            }
            
            cell.textLabel.text = component.headerObject.title;
            cell.detailTextLabel.text = component.headerObject.text;
            cell.targetObject = component.headerObject.target;
            
            return cell;
        }
        else if (component.cellClass == [StreamPostCell class])  {
            // determine if it's a reply or sub-reply
            Post *post = component.post;
            CGFloat replies = post.attributes.summaries.replies.count;
            
            BOOL showViewMore = post.attributes.summaries.replies.count > 0 && (replies < post.attributes.summaries.counts.replies);
            BOOL showAddReply = [post.attributes.context.post.permissions canReply] &&  post.attributes.summaries.replies.count > 0;
                        
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

            cell.showContext = true;
            cell.showCamptag = true;
            cell.post = post;

            if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                [self didBeginDisplayingCell:cell];
            }

            if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
                [cell.actionsView.replyButton bk_whenTapped:^{
                    [Launcher openComposePost:cell.post.attributes.postedIn inReplyTo:cell.post withMessage:nil media:nil quotedObject:nil];
                }];
            }
            
            cell.lineSeparator.hidden = post.attributes.summaries.replies.count > 0 || showViewMore || showAddReply;
            cell.bottomLine.hidden = true;

            return cell;
        }
        else if (component.cellClass == [ReplyCell class]) {
            ReplyCell *cell = [self dequeueReusableCellWithIdentifier:postReplyReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postReplyReuseIdentifier];
            }
            
            cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
            
            cell.levelsDeep = -1;
            cell.lineSeparator.hidden = true;
            cell.selectable = YES;
            
            NSString *identifierBefore = cell.post.identifier;
            
            cell.post = component.post;
            
            if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                [self didBeginDisplayingCell:cell];
            }
            
            return cell;
        }
        else if (component.cellClass == [ExpandThreadCell class]) {
            // "view more replies"
            ExpandThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:expandRepliesCellIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[ExpandThreadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandRepliesCellIdentifier];
            }
            
            cell.levelsDeep = -1;
            cell.post = component.post;
            
            return cell;
        }
        else if (component.cellClass == [AddReplyCell class]) {
            AddReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:addReplyCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[AddReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addReplyCellIdentifier];
            }
            
            cell.levelsDeep = -1;
            cell.post = component.post;
            
            return cell;
        }
        else if (component.cellClass == [ButtonCell class]) {
            ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:buttonCellReuseIdentifier];
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            // Configure the cell...
            cell.buttonLabel.text = s.attributes.cta.text;
            
            if (s.attributes.cta.target.camp) {
                cell.buttonLabel.textColor = [UIColor fromHex:s.attributes.cta.target.camp.attributes.color adjustForOptimalContrast:true];
            }
            else {
                cell.buttonLabel.textColor = cell.kButtonColorBonfire;
            }
            
            cell.topSeparator.hidden = true;
            cell.bottomSeparator.hidden = false;
            
            return cell;
        }
    }
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    blankCell.backgroundColor  = [UIColor colorWithWhite:1-(0.1*indexPath.row) alpha:1];
    return blankCell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 80;
    
    if (indexPath.section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForRowInFirstSection:)]) {
            height = [self.extendedDelegate heightForRowInFirstSection:indexPath.row];
        }
    }
    else if (self.stream.sections.count  > 0) {
        BFComponent *component = [self componentAtIndexPath:indexPath];
        height = component.cellHeight;
    }
    
    return height;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1 + self.stream.sections.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(numberOfRowsInFirstSection)]) {
            return [self.extendedDelegate numberOfRowsInFirstSection];
        }
    }
    else if (self.stream.sections.count  > 0) {
        Section *s = self.stream.sections[section-1];
        return s.components.count;
    }
    
    return 0;
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
    
    return [[UIView alloc] initWithFrame:CGRectZero];
}
- (BOOL)showFooterForSection:(NSInteger)section {
    Section *s = self.stream.sections[section-1];
    
    BOOL sectionHasCta = (s.attributes.cta.text.length > 0);
    BOOL nextSectionHasHeader = false;

    if (self.stream.sections.count > section) {
        Section *nextSection = self.stream.sections[section];
        nextSectionHasHeader = (nextSection.attributes.title.length > 0 || nextSection.attributes.text.length > 0);
    }
    
    return (sectionHasCta || nextSectionHasHeader);
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForFirstSectionFooter)]) {
            return [self.extendedDelegate heightForFirstSectionFooter];
        }
    }
    else if ([self showFooterForSection:section]) {
        if (section == self.stream.sections.count) {
            BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
            BOOL showLoadingFooter = (self.loadingMore || (hasAnotherPage && ![self.stream hasLoadedCursor:self.stream.nextCursor]));

            DSimpleLog(@"self.loadingMore? %@", self.loadingMore ? @"YES" : @"NO");
            DSimpleLog(@"hasAnotherPage? %@", hasAnotherPage ? @"YES" : @"NO");
            DSimpleLog(@"hasLoadedCursor? %@", [self.stream hasLoadedCursor:self.stream.nextCursor] ? @"YES" : @"NO");
            
            if (showLoadingFooter) {
                return 48;
            }
            else {
                return CGFLOAT_MIN;
            }
        }
        else {
            return 12;
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
    else {
        if ([self showFooterForSection:section]) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 12)];
            footer.backgroundColor = [UIColor tableViewBackgroundColor];
            
            if (section == self.stream.sections.count) {
                BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
                BOOL showLoadingFooter = (self.loadingMore || (hasAnotherPage && ![self.stream hasLoadedCursor:self.stream.nextCursor]));

                if (showLoadingFooter) {
                    SetHeight(footer, 48);
                    
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
                }
                else {
                    return nil;
                }
            }
            else {
                UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, footer.frame.size.height - HALF_PIXEL, footer.frame.size.width, HALF_PIXEL)];
                lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
                [footer addSubview:lineSeparator];
            }
            
            return footer;
        }
    }
    
    return nil; //lineSeparator;
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
- (void)sectionStreamDidUpdate:(SectionStream *)stream {
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
- (Section * _Nullable)sectionAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section > self.stream.sections.count) {
        return nil;
    }
    
    return self.stream.sections[indexPath.section-1];
}
- (BFComponent * _Nullable)componentAtIndexPath:(NSIndexPath *)indexPath {
    Section *s = [self sectionAtIndexPath:indexPath];
    
    if (indexPath.row > s.components.count) {
        return nil;
    }
    
    return s.components[indexPath.row];
}

@end
