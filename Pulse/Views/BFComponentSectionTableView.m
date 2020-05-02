//
//  BFComponentSectionTableView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/4/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "BFComponentSectionTableView.h"
#import "ComplexNavigationController.h"

#import "CampHeaderCell.h"
#import "ProfileHeaderCell.h"

#import "StreamPostCell.h"
#import "ReplyCell.h"
#import "ExpandThreadCell.h"
#import "ExpandedPostCell.h"
#import "AddReplyCell.h"
#import "BFErrorViewCell.h"
#import "ButtonCell.h"
#import "SpacerCell.h"
#import "SearchResultCell.h"
#import "CampCardsListCell.h"

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

@interface BFComponentSectionTableView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIViewController *parentNavigationController;

@end

@implementation BFComponentSectionTableView

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

static NSString * const campCellIdentifier = @"CampReuseIdentifier";
static NSString * const userCellIdentifier = @"UserReuseIdentifier";
static NSString * const campCollectionCellIdentifier = @"CampCollectionReuseIdentifier";

static NSString * const buttonCellReuseIdentifier = @"ButtonCellReuseIdentifier";
static NSString * const spacerCellReuseIdentifier = @"SpacerCell";
static NSString * const paginationCellReuseIdentifier = @"PaginationCell";

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
    self.stream = [[SectionStream alloc] init];
    self.stream.delegate = self;
    
    self.backgroundColor = [UIColor tableViewBackgroundColor];
    self.loading = true;
    self.loadingMore = false;
    self.delegate = self;
    self.dataSource = self;
    self.estimatedRowHeight = 0;
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
    
    [self registerClass:[SearchResultCell class] forCellReuseIdentifier:campCellIdentifier];
    [self registerClass:[SearchResultCell class] forCellReuseIdentifier:userCellIdentifier];
    [self registerClass:[CampCardsListCell class] forCellReuseIdentifier:campCollectionCellIdentifier];
    
    [self registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellReuseIdentifier];
    [self registerClass:[SpacerCell class] forCellReuseIdentifier:spacerCellReuseIdentifier];
    [self registerClass:[PaginationCell class] forCellReuseIdentifier:paginationCellReuseIdentifier];
    
    [self registerClass:[BFErrorViewCell class] forCellReuseIdentifier:errorCellReuseIdentifier];
    [self registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    
    [self registerClass:[LoadingCell class] forCellReuseIdentifier:loadingCellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(campUpdated:) name:@"CampUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUpdated:) name:@"PostUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:@"PostDeleted" object:nil];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    UIViewController *parentViewController = UIViewParentController(self);
    if (parentViewController && parentViewController.navigationController) {
        self.parentNavigationController = parentViewController.navigationController;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setLoading:(BOOL)loading {
    if (loading != _loading) {
        _loading = loading;
    }
    
    [self updateScrollEnabled];
}

- (void)updateScrollEnabled {
    self.scrollEnabled = !(_loading && self.stream.sections.count == 0);
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
        [self hardRefresh:false];
    }
}
- (void)userUpdated:(NSNotification *)notification {
    User *user = notification.object;
    
    if (user != nil && [self.stream performEventType:SectionStreamEventTypeUserUpdated object:user]) {
        [self hardRefresh:false];
    }
}
- (void)campUpdated:(NSNotification *)notification {
    Camp *camp = notification.object;
    
    if (camp != nil && [self.stream performEventType:SectionStreamEventTypeCampUpdated object:camp]) {
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
        BFStreamComponent *component = [self componentAtIndexPath:indexPath];
        
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
        else if ([cell isKindOfClass:[SearchResultCell class]]) {
            if (component.camp) {
                [Launcher openCamp:component.camp];
            }
            else if (component.user) {
                [Launcher openProfile:component.user];
            }
        }
        else {
            Section *s = [self sectionAtIndexPath:indexPath];
            
            if ([component cellClass] == [ButtonCell class]) {
                if (s.attributes.cta.target.camp) {
                    [Launcher openCamp:s.attributes.cta.target.camp];
                }
                else if (s.attributes.cta.target.creator) {
                    [Launcher openIdentity:s.attributes.cta.target.creator];
                }
                else if (s.attributes.cta.target.url) {
                    NSURL *link = [NSURL URLWithString:s.attributes.cta.target.url];
                    if (![[[UIApplication sharedApplication] delegate] application:[UIApplication sharedApplication] openURL:link options:@{}]) {
                        [Launcher openURL:link.absoluteString];
                    }
                }
            }
        }
    }
}
- (void)didBeginDisplayingCell:(UITableViewCell *)cell {
    if ([cell isKindOfClass:[PostCell class]]) {
        Post *post = ((PostCell *)cell).post;
        
        // skip logging if invalid post identifier (most likely due to a loading cell)
        if (!post.identifier) return;
                
        if (self.insightSeenInLabel) {
            [InsightsLogger.sharedInstance openPostInsight:post.identifier seenIn:self.insightSeenInLabel];
        }
    }
    else if ([cell isKindOfClass:[PaginationCell class]]) {
        DLog(@"⚪️ show that pagination cell !");
        
        if (!self.loadingMore && self.stream.pages.count > 0 && self.stream.nextCursor.length > 0) {
            DLog(@"🔘 start loading more!!!!");
            self.loadingMore = true;

            if ([self.extendedDelegate respondsToSelector:@selector(tableView:didRequestNextPageWithMaxId:)]) {
                DLog(@"🔴 get that next page");
                [self.extendedDelegate tableView:self didRequestNextPageWithMaxId:0];
            }
        }
        else if (self.loadingMore) {
            DLog(@"🔘 already loading more");
        }
        else if (self.stream.pages.count == 0) {
            NSLog(@"🔘 no pages..");
        }
        else if (self.stream.nextCursor.length == 0) {
            NSLog(@"🔘 no next cursor.");
        }
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
            return [self.extendedDelegate cellForRowInFirstSection:indexPath.row];
        }
    }
    else if (self.stream.sections.count > 0) {
        Section *s = [self sectionAtIndexPath:indexPath];
        BFStreamComponent *component = [self componentAtIndexPath:indexPath];
        
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

            cell.showContext = true;
            cell.showPostedIn = true;
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
        else if ([component cellClass] == [SearchResultCell class])  {
            NSString *reuseIdentifier;
            if (component.camp || component.user) {
                if (component.camp) {
                    reuseIdentifier = campCellIdentifier;
                }
                else if (component.user) {
                    reuseIdentifier = userCellIdentifier;
                }
                
                SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
                }
                
                if (component.camp) {
                    cell.camp = component.camp;
                }
                else if (component.user) {
                    cell.user = component.user;
                }
                else {
                    cell.camp = nil;
                    cell.user = nil;
                    cell.bot = nil;
                    
                    cell.textLabel.text = @"";
                    cell.imageView.image = nil;
                    cell.imageView.backgroundColor = [UIColor bonfireSecondaryColor];
                }
                
                BOOL last = indexPath.row == s.components.count - ([s.components lastObject].cellClass == [ButtonCell class] ? 2 : 1);
                CGFloat lineSeparatorLeftOffset = last ? 0 : cell.textLabel.frame.origin.x;
                cell.lineSeparator.frame = CGRectMake(lineSeparatorLeftOffset, self.frame.origin.y - cell.lineSeparator.frame.size.height, cell.frame.size.width - lineSeparatorLeftOffset, cell.lineSeparator.frame.size.height);
                
                return cell;
            }
        }
        else if ([component cellClass] == [CampCardsListCell class])  {
            if (component.campArray) {
                CampCardsListCell *cell = [tableView dequeueReusableCellWithIdentifier:campCollectionCellIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[CampCardsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:campCollectionCellIdentifier];
                }
                       
                cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
                cell.size = CAMP_CARD_SIZE_SMALL_MEDIUM;
                cell.camps = [[NSMutableArray alloc] initWithArray:component.campArray];
                cell.lineSeparator.hidden = !component.showLineSeparator;
                
                return cell;
            }
        }
        else if ([component cellClass] == [ButtonCell class]) {
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
            else if (s.attributes.cta.target.creator) {
                cell.buttonLabel.textColor = [UIColor fromHex:s.attributes.cta.target.creator.attributes.color adjustForOptimalContrast:true];
            }
            else {
                cell.buttonLabel.textColor = [UIColor fromHex:[UIColor toHex:self.tintColor] adjustForOptimalContrast:true];
            }
            
            cell.topSeparator.hidden = true;
            cell.bottomSeparator.hidden = false;
            
            return cell;
        }
        else if ([component cellClass] == [SpacerCell class]) {
            SpacerCell *cell = [self dequeueReusableCellWithIdentifier:spacerCellReuseIdentifier forIndexPath:indexPath];

            if (cell == nil) {
                cell = [[SpacerCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:spacerCellReuseIdentifier];
            }

            cell.topSeparator.hidden = true;
            cell.bottomSeparator.hidden = false;

            return cell;
        }
        else if ([component cellClass] == [PaginationCell class]) {
            PaginationCell *cell = [self dequeueReusableCellWithIdentifier:paginationCellReuseIdentifier forIndexPath:indexPath];

            if (cell == nil) {
                cell = [[PaginationCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:paginationCellReuseIdentifier];
            }
            
            cell.backgroundColor = [UIColor tableViewBackgroundColor];
            
            BOOL showSpinner = self.stream.nextCursor.length > 0;
            cell.spinner.hidden = !showSpinner;
            cell.textLabel.hidden = showSpinner;
            
            if (showSpinner) {
                [cell.spinner startAnimating];
            }
            else {
                [cell.spinner stopAnimating];
                cell.textLabel.text = @"You've reached the bottom!";
            }
            
            [self didBeginDisplayingCell:cell];
            
            return cell;
        }
    }
    else if (indexPath.section == 1) {
        if (self.loading) {
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
    else if (self.stream.sections.count > 0) {
        BFStreamComponent *component = [self componentAtIndexPath:indexPath];
        height = component.cellHeight;
    }
    else if (indexPath.section == 1) {
        if (self.loading) {
            switch ((indexPath.row - 1) % 3) {
                case 1:
                    height = 123;
                    break;
                case 2:
                    height = 364 + 36;
                    break;
                    
                default:
                    height = 102;
                    break;
            }
        }
        else if (self.visualError) {
            height = [BFErrorViewCell heightForVisualError:self.visualError];
        }
    }
    
    return height;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = 1;
    
    if (self.stream.sections.count > 0) {
        sections += self.stream.sections.count;
    }
    else if (self.visualError || self.loading) {
        sections += 1;
    }
    
    return sections;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(numberOfRowsInFirstSection)]) {
            return [self.extendedDelegate numberOfRowsInFirstSection];
        }
    }
    else if (self.stream.sections.count > section - 1) {
        Section *s = self.stream.sections[section-1];
                
        return s.components.count + ([self showFooterForSection:section] ? 1 : 0);
    }
    else if (self.loading) {
        return 10;
    }
    else if (section == 1 && self.visualError) {
        return 1;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForFirstSectionHeader)]) {
            return [self.extendedDelegate heightForFirstSectionHeader];
        }
    }
    else if (self.stream.sections.count > section - 1) {
        Section *s = [self sectionAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        
        return [self heightForSection:s];
    }
    
    return CGFLOAT_MIN;
}
- (CGFloat)heightForSection:(Section *)section {
    BOOL hasTitle = section.attributes.title.length > 0;
    BOOL hasText = section.attributes.text.length > 0;
    if (section.components.count > 0 && (hasTitle || hasText)) {
        if (hasTitle && hasText) {
            return 64;
        }
        else {
            return 52;
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
    else if (self.stream.sections.count > section - 1) {
        Section *s = [self sectionAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        
        if (s.components.count > 0 &&
            (s.attributes.title.length > 0 ||
            s.attributes.text.length > 0)) {
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, [self heightForSection:s])];
            header.backgroundColor = [UIColor contentBackgroundColor];
            
            UIEdgeInsets contentEdgeInsets = UIEdgeInsetsMake(12, 12, 12, 12);
            CGFloat bottomY = contentEdgeInsets.top;
            
            if (s.attributes.cta.target &&
                (s.attributes.cta.target.creator || s.attributes.cta.target.camp)) {
                BFAvatarView *avatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(header.frame.size.width - 24 - 12, (header.frame.size.height / 2) - (24 / 2), 24, 24)];
                avatarView.openOnTap = true;
                if (s.attributes.cta.target.camp) {
                    avatarView.camp = s.attributes.cta.target.camp;
                }
                else if (s.attributes.cta.target.creator) {
                    if ([s.attributes.cta.target.creator isBot]) {
                        avatarView.bot = (Bot *)s.attributes.cta.target.creator;
                    }
                    else {
                        avatarView.user = (User *)s.attributes.cta.target.creator;
                    }
                }
                [header addSubview:avatarView];
                
                contentEdgeInsets.right = header.frame.size.width - avatarView.frame.origin.x - 12;
            }
            
            if (s.attributes.title.length > 0) {
                if (s.attributes.text.length == 0) {
                    contentEdgeInsets.top =
                    contentEdgeInsets.bottom = 16;
                }
                
                UILabel *titleLabel = [[UILabel alloc] init];
                titleLabel.text = s.attributes.title;
                titleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
                titleLabel.textColor = [UIColor bonfirePrimaryColor];
                titleLabel.frame = CGRectMake(contentEdgeInsets.left, contentEdgeInsets.top, header.frame.size.width - (contentEdgeInsets.left + contentEdgeInsets.right), ceilf(titleLabel.font.lineHeight));
                [header addSubview:titleLabel];
                
                bottomY = titleLabel.frame.origin.y + titleLabel.frame.size.height + 2;
            }
            
            if (s.attributes.text.length > 0) {
                UILabel *textLabel = [[UILabel alloc] init];
                textLabel.text = s.attributes.text;
                textLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
                textLabel.textColor = [UIColor bonfireSecondaryColor];
                textLabel.frame = CGRectMake(contentEdgeInsets.left, bottomY, header.frame.size.width - (contentEdgeInsets.left + contentEdgeInsets.right), ceilf(textLabel.font.lineHeight));
                [header addSubview:textLabel];
            }
            
            UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height - HALF_PIXEL, header.frame.size.width, HALF_PIXEL)];
            lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
            [header addSubview:lineSeparator];
            
            return header;
        }
    }
    
    return nil;
}
- (BOOL)showFooterForSection:(NSInteger)section {
    if (self.stream.sections.count <= (section-1)) return false;
    
    Section *s = self.stream.sections[section-1];
    
    BOOL hasComponents = s.components.count > 0;
    if (!hasComponents) return false;
    
    BOOL sectionHasCta = (s.attributes.cta.text.length > 0);
    BOOL nextSectionHasHeader = false;
    BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
    BOOL lastSection = (section == [self numberOfSections] - 1);
    BOOL showLoadingFooter = (self.loadingMore || (hasAnotherPage && ![self.stream hasLoadedCursor:self.stream.nextCursor]));
    
    nextSectionHasHeader = false;
    if (self.stream.sections.count > section) {
        Section *nextSection = self.stream.sections[section];
        nextSectionHasHeader = (nextSection.attributes.title.length > 0 || nextSection.attributes.text.length > 0);
    }
    
    return (lastSection && showLoadingFooter) || (!lastSection && (sectionHasCta || nextSectionHasHeader));
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForFirstSectionFooter)]) {
            return [self.extendedDelegate heightForFirstSectionFooter];
        }
        else if (self.loading || self.visualError || (!self.loading && self.stream.sections.count > 0)) {
            return HALF_PIXEL;
        }
    }
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(viewForFirstSectionFooter)]) {
            return [self.extendedDelegate viewForFirstSectionFooter];
        }
        else if (self.loading || self.visualError || (!self.loading && self.stream.sections.count > 0)) {
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, HALF_PIXEL)];
            separator.backgroundColor = [UIColor tableViewSeparatorColor];
            return separator;
        }
    }
    
    return nil;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self && [self.extendedDelegate respondsToSelector:@selector(tableViewDidScroll:)]) {
        [self.extendedDelegate tableViewDidScroll:self];
                
        if (self.parentNavigationController) {
            if ([self.parentNavigationController isKindOfClass:[ComplexNavigationController class]]) {
                ComplexNavigationController *complexNav = (ComplexNavigationController *)self.parentNavigationController;
                [complexNav childTableViewDidScroll:self];
            }
            else if ([self.parentNavigationController isKindOfClass:[SimpleNavigationController class]]) {
                SimpleNavigationController *simpleNav = (SimpleNavigationController *)self.parentNavigationController;
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
        [self updateScrollEnabled];
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
- (BFStreamComponent * _Nullable)componentAtIndexPath:(NSIndexPath *)indexPath {
    Section *s = [self sectionAtIndexPath:indexPath];
    
    if (s) {
        if (indexPath.row > s.components.count) {
            return nil;
        }
        else if (indexPath.row == s.components.count) {
            if (indexPath.section == self.stream.sections.count) {
                // last section --> try  to use pagination cell
                BFStreamComponent *component = [[BFStreamComponent alloc] initWithSettings:nil className:@"PaginationCell" detailLevel:BFComponentDetailLevelAll];
                component.cellHeight = [PaginationCell height];
                return component;
            }
            else {
                // spacer cell
                BFStreamComponent *component = [[BFStreamComponent alloc] initWithSettings:nil className:@"SpacerCell" detailLevel:BFComponentDetailLevelAll];
                component.cellHeight = [SpacerCell height];
                return component;
            }
        }
        
        return s.components[indexPath.row];
    }
    
    return nil;
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
            newNavController.view.tintColor = [UIColor fromHex:p.post.themeColor adjustForOptimalContrast:true];
            [newNavController updateBarColor:[UIColor clearColor] animated:false];
            
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
