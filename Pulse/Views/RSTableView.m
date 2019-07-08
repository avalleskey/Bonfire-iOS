//
//  RSTableView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/4/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RSTableView.h"
#import "ComplexNavigationController.h"

#import "CampHeaderCell.h"
#import "ProfileHeaderCell.h"

#import "StreamPostCell.h"
#import "ReplyCell.h"
#import "ExpandThreadCell.h"
#import "AddReplyCell.h"

#import "LoadingCell.h"
#import "PaginationCell.h"
#import "Launcher.h"
#import "BFHeaderView.h"
#import "UIColor+Palette.h"
#import "CampViewController.h"
#import "ProfileCampsListViewController.h"
#import "InsightsLogger.h"

#import <JGProgressHUD/JGProgressHUD.h>
#import <HapticHelper/HapticHelper.h>
@import Firebase;

@implementation RSTableView

@synthesize dataType = _dataType;  //Must do this

static NSString * const streamPostReuseIdentifier = @"StreamPost";
static NSString * const postReplyReuseIdentifier = @"ReplyReuseIdentifier";
static NSString * const expandRepliesCellIdentifier = @"ExpandRepliesReuseIdentifier";
static NSString * const addReplyCellIdentifier = @"AddReplyReuseIdentifier";

static NSString * const previewReuseIdentifier = @"PreviewPost";
static NSString * const blankCellIdentifier = @"BlankCell";

static NSString * const loadingCellIdentifier = @"LoadingCell";
static NSString * const paginationCellIdentifier = @"PaginationCell";

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

//Setter method
- (void)setDataType:(RSTableViewType)dataType {
    if (_dataType != dataType) {
        _dataType = dataType;
        [self refresh];
    }
}
    
//Getter method
- (RSTableViewType)dataType {
    return _dataType;
}

//Setter method
- (void)setTableViewStyle:(RSTableViewStyle)tableViewStyle {
    if (tableViewStyle != _tableViewStyle) {
        _tableViewStyle = tableViewStyle;
        
        if (tableViewStyle == RSTableViewStyleDefault) {
            self.backgroundColor = [UIColor whiteColor];
        }
        else {
            self.backgroundColor = [UIColor headerBackgroundColor];
        }
        
        [self refresh];
    }
}

- (void)refresh {
    [self reloadData];
    // [self layoutIfNeeded];
    
    if (!self.loading) {
        [self.refreshControl endRefreshing];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.extendedDelegate respondsToSelector:@selector(tableViewDidScroll:)]) {
        [self.extendedDelegate tableViewDidScroll:self];
    }
}

- (void)scrollToTop {
    [self scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

- (void)setup {
    self.reachedBottom = false;
    self.stream = [[PostStream alloc] init];
    self.loading = true;
    self.loadingMore = false;
    self.delegate = self;
    self.dataSource = self;
    self.separatorColor = [UIColor separatorColor];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    self.estimatedRowHeight = 0;
    self.tableViewStyle = RSTableViewStyleDefault;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self sendSubviewToBack:self.refreshControl];
        
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamPostReuseIdentifier];
    [self registerClass:[ReplyCell class] forCellReuseIdentifier:postReplyReuseIdentifier];
    [self registerClass:[ExpandThreadCell class] forCellReuseIdentifier:expandRepliesCellIdentifier];
    [self registerClass:[AddReplyCell class] forCellReuseIdentifier:addReplyCellIdentifier];
    
    [self registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    
    [self registerClass:[LoadingCell class] forCellReuseIdentifier:loadingCellIdentifier];
    [self registerClass:[PaginationCell class] forCellReuseIdentifier:paginationCellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUpdated:) name:@"PostUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:@"PostDeleted" object:nil];
}

- (void)postUpdated:(NSNotification *)notification {
    Post *post = notification.object;
    // NSLog(@"post that's updated: %@", post);
    
    if (post != nil) {
        // new post appears valid
        BOOL changes = [self.stream updatePost:post];
        
        if (changes) {
            // 💫 changes made
            
            // NSLog(@"parent controller: %@", UIViewParentController(self));
            if (![[Launcher activeViewController] isEqual:UIViewParentController(self)]) {
                [self refresh];
            }
        }
    }
}
- (void)postDeleted:(NSNotification *)notification {
    if (![notification.object isKindOfClass:[Post class]]) return;
    
    Post *post = notification.object;
    BOOL isReply = post.attributes.details.parentId.length > 0;
    BOOL postedInCamp = post.attributes.status.postedIn != nil;
    
    BOOL removePost = false;
    BOOL refresh = false;
    if ([self.parentObject isKindOfClass:[Camp class]] && postedInCamp) {
        Camp *parentCamp = self.parentObject;
        
        // determine type of post (post or reply)
        if ([parentCamp.identifier isEqualToString:post.attributes.status.postedIn.identifier]) {
            removePost = true;
            refresh = true;
            // Camp that contains post
            if (isReply) {
                // Decrement Post replies count
                Post *updatedPost = [self.stream postWithId:post.attributes.details.parentId];
                if (updatedPost) {
                    updatedPost.attributes.summaries.counts.replies = updatedPost.attributes.summaries.counts.replies - 1;
        
                    // update replies
                    NSMutableArray <Post *><Post> *mutableReplies = [[NSMutableArray<Post *><Post> alloc] initWithArray:updatedPost.attributes.summaries.replies];
                    NSMutableArray *repliesToDelete = [[NSMutableArray alloc] init];
                    for (NSInteger i = 0; i < mutableReplies.count; i++) {
                        Post *reply = mutableReplies[i];
                        if (reply.identifier == post.identifier) {
                            [repliesToDelete addObject:reply];
                        }
                    }
                    if (repliesToDelete.count > 0) {
                        [mutableReplies removeObjectsInArray:repliesToDelete];
                        updatedPost.attributes.summaries.replies = mutableReplies;
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:updatedPost];
                    
                    NSLog(@"✅ Decrement Post replies count inside Camp");
                }
            }
            else {
                // Decrement Camp posts count
                parentCamp.attributes.summaries.counts.posts = parentCamp.attributes.summaries.counts.posts - 1;
                
                NSLog(@"✅ Decrement Camp posts count");
            }
        }
    }
    else if ([self.parentObject isKindOfClass:[Post class]]) {
        Post *parentPost = self.parentObject;
        
        if (isReply &&
            (parentPost.identifier == post.attributes.details.parentId)) {
            // --> reply to the parent Post
            // Decrement Post replies count
            removePost = true;
            refresh = true;
            
            NSLog(@"✅ Remove reply inside Post");
        }
    }
    else if (self.dataType == RSTableViewTypeFeed) {
        Post *postInStream = [self.stream postWithId:post.identifier];
        
        if (postInStream) {
            removePost = true;
            refresh = true;
        }
    }
    else if (self.dataType == RSTableViewTypeProfile) {
        Post *postInStream = [self.stream postWithId:post.identifier];
        
        if (postInStream) {
            removePost = true;
            refresh = true;
        }
    }
    
    if (removePost) [self.stream removePost:post];
    if (refresh) [self refresh];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(cellForRowInFirstSection:)]) {
            id cell = [self.extendedDelegate cellForRowInFirstSection:indexPath.row];
            if (cell != nil) {
                return cell;
            }
        }
    }
    else if (self.stream.posts.count == 0 && self.loading) {
        // loading cell
        LoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[LoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:loadingCellIdentifier];
        }
        
        NSInteger postType = (indexPath.section) % 3;
        cell.type = postType;
        cell.shimmerContainer.shimmering = true;
        
        cell.userInteractionEnabled = false;
        
        return cell;
    }
    else if (self.stream.posts.count > indexPath.section - 1) {
        // Content
        NSInteger adjustedIndex = indexPath.section - 1;
        
        // determine if it's a reply or sub-reply
        Post *post = self.stream.posts[adjustedIndex];
        CGFloat replies = post.attributes.summaries.replies.count;
        // 0       : actual reply
        // 1       : --- "hide replies"
        // 2-(x+1) : --- replies
        // (x+1)+1 : --- "view more replies"
        // (x+1)+2 : --- "add a reply..."
        
        BOOL showViewMore = (replies < post.attributes.summaries.counts.replies);
        BOOL showAddReply = post.attributes.summaries.replies.count > 0;
        
        NSInteger firstReplyIndex = 1;
        
        if (indexPath.row == 0) {
            StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:streamPostReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:streamPostReuseIdentifier];
            }
            
            NSString *identifierBefore = cell.post.identifier;
            
            cell.showContext = true;
            cell.showCamptag = true;
            cell.post = post;
            
            [cell.actionsView setSummaries:post.attributes.summaries];
            
            if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                [self didBeginDisplayingCell:cell];
            }
            
            if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
                [cell.actionsView.replyButton bk_whenTapped:^{
                    [Launcher openComposePost:cell.post.attributes.status.postedIn inReplyTo:cell.post withMessage:nil media:nil];
                }];
            }
            
            cell.lineSeparator.hidden = post.attributes.summaries.replies.count > 0 || showViewMore || showAddReply;
            
            return cell;
        }
        else if ((indexPath.row - firstReplyIndex) <  post.attributes.summaries.replies.count) {
            NSInteger replyIndex = indexPath.row - firstReplyIndex;
            
            // reply
            ReplyCell *cell = [self dequeueReusableCellWithIdentifier:postReplyReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postReplyReuseIdentifier];
            }
            
            NSString *identifierBefore = cell.post.identifier;
            
            Post *subReply = post.attributes.summaries.replies[replyIndex];
            cell.post = subReply;
            
            if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                [self didBeginDisplayingCell:cell];
            }
            
            cell.topCell = (replyIndex == 0);
            cell.bottomCell = (indexPath.row == post.attributes.summaries.replies.count + firstReplyIndex - 1) && !showViewMore && !showAddReply;
            
            cell.lineSeparator.hidden = !cell.bottomCell;
            
            cell.selectable = YES;
            
            return cell;
        }
        else if (showViewMore && indexPath.row == post.attributes.summaries.replies.count + firstReplyIndex) {
            // "view more replies"
            ExpandThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:expandRepliesCellIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[ExpandThreadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandRepliesCellIdentifier];
            }
            
            BOOL hasExistingReplies = post.attributes.summaries.replies.count != 0;
            cell.textLabel.text = [NSString stringWithFormat:@"View%@ replies (%ld)", (hasExistingReplies ? @" more" : @""), (long)post.attributes.summaries.counts.replies - post.attributes.summaries.replies.count];
            cell.textLabel.textColor = [UIColor bonfireBlack];
            
            if (hasExistingReplies) {
                // view more replies
                cell.tag = 2;
            }
            else {
                // start replies chain
                cell.tag = 3;
            }
            
            cell.lineSeparator.hidden = showAddReply;
            
            return cell;
        }
        else if (showAddReply && indexPath.row == post.attributes.summaries.replies.count + firstReplyIndex + (showViewMore ? 1 : 0)) {
            // "add a reply"
            AddReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:addReplyCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[AddReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addReplyCellIdentifier];
            }
            
            cell.addReplyLabel.text = [NSString stringWithFormat:@"Reply to @%@...", post.attributes.details.creator.attributes.details.identifier];
            
            return cell;
        }
    }

    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForRowInFirstSection:)]) {
            return [self.extendedDelegate heightForRowInFirstSection:indexPath.row];
        }
    }
    else if (indexPath.section - 1 < self.stream.posts.count && [self.stream.posts[indexPath.section-1].type isEqualToString:@"post"]) {
        Post *post = self.stream.posts[indexPath.section-1];
        CGFloat replies = post.attributes.summaries.replies.count;
        
        BOOL showViewMore = (replies < post.attributes.summaries.counts.replies);
        BOOL showAddReply = post.attributes.summaries.replies.count > 0;
        
        NSInteger firstReplyIndex = 1;
        
        if (indexPath.row == 0) {
            // BOOL showActions = (reply.attributes.summaries.replies.count == 0);
            return [StreamPostCell heightForPost:post showContext:true showActions:true];
        }
        else if ((indexPath.row - firstReplyIndex) <  post.attributes.summaries.replies.count) {
            NSInteger replyIndex = indexPath.row - firstReplyIndex;
            Post *reply = post.attributes.summaries.replies[replyIndex];
            return [ReplyCell heightForPost:reply];
        }
        else if (showViewMore && indexPath.row == post.attributes.summaries.replies.count + firstReplyIndex) {
            // "view more replies"
            return CONVERSATION_EXPAND_CELL_HEIGHT;
        }
        else if (showAddReply && indexPath.row == post.attributes.summaries.replies.count + firstReplyIndex + (showViewMore ? 1 : 0)) {
            // "add a reply"
            return [AddReplyCell height];
        }
    }
    else if (self.stream.posts.count == 0 && self.loading) {
        // 107: 1 line post
        // 128: 2 line post
        // 295: 1 line w/ image post
        switch (indexPath.section % 3) {
            case 0:
                return 102;
                break;
            case 1:
                return 123;
                break;
            case 2:
                return 310;
                break;
                
            default:
                return 102;
                break;
        }
    }
    else if (indexPath.section - 1 == self.stream.posts.count) {
        // pagination cell
        return 52;
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
    if (self.loading && self.stream.posts.count == 0) {
        self.scrollEnabled = false;
    }
    else {
        self.scrollEnabled = true;
    }
    
    if (self.stream.posts.count == 0 && self.loading) {
        // loading cells
        return 1 + 10;
    }
    
    return 1 + self.stream.posts.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(numberOfRowsInFirstSection)]) {
            return [self.extendedDelegate numberOfRowsInFirstSection];
        }
    }
    else if (self.stream.posts.count == 0 && self.loading) {
        // loading cells
        return 1;
    }
    else if (section <= self.stream.posts.count) {
        // content
        NSInteger adjustedIndex = section - 1;
        
        Post *reply = self.stream.posts[adjustedIndex];
        CGFloat replies = reply.attributes.summaries.replies.count;
        
        // 0   : "hide replies"
        // 1-x : replies
        // x+1 : "view more replies"
        // x+2 : "add a reply..."
        
        BOOL showViewMore = (replies < reply.attributes.summaries.counts.replies);
        BOOL showAddReply = reply.attributes.summaries.replies.count > 0;
        
        NSInteger rows = 1 + replies + (showViewMore ? 1 : 0) + (showAddReply ? 1 : 0);
        
        return rows;
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Post *post;
    
    UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[StreamPostCell class]] || [cell isKindOfClass:[ReplyCell class]]) {
        if (!((PostCell *)cell).post) return;
        
        post = ((PostCell *)cell).post;
    }
    if ([cell isKindOfClass:[ExpandThreadCell class]]) {
        post = self.stream.posts[indexPath.section-1];
    }
    if ([cell isKindOfClass:[AddReplyCell class]]) {
        Post *postReplyingTo = self.stream.posts[indexPath.section-1];
        
        [Launcher openComposePost:postReplyingTo.attributes.status.postedIn inReplyTo:postReplyingTo withMessage:nil media:nil];
    }
    
    if (post) {
        [InsightsLogger.sharedInstance closePostInsight:post.identifier action:InsightActionTypeDetailExpand];
        [FIRAnalytics logEventWithName:@"conversation_expand"
                            parameters:@{
                                         @"post_id": post.identifier
                                         }];
        
        [Launcher openPost:post withKeyboard:false];
    }
}
//@property (nonatomic) NSInteger lastSinceId;
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
    switch (self.dataType) {
        case RSTableViewTypeFeed:
            if (self.dataSubType == RSTableViewSubTypeHome) {
                seenIn = InsightSeenInHomeView;
            }
            if (self.dataSubType == RSTableViewSubTypeTrending) {
                seenIn = InsightSeenInTrendingView;
            }
            break;
        case RSTableViewTypeCamp:
            seenIn = InsightSeenInCampView;
            break;
        case RSTableViewTypeProfile:
            seenIn = InsightSeenInProfileView;
            break;
    }
    
    //
    [InsightsLogger.sharedInstance openPostInsight:post.identifier seenIn:seenIn];
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForFirstSectionHeader)]) {
            return [self.extendedDelegate heightForFirstSectionHeader];
        }
    }
    
#ifdef DEBUG
    if (self.dataType == RSTableViewTypeFeed && section != 0 && self.stream.posts.count > section) {
        Post *post = self.stream.posts[section-1];
        
        if (post.prevCursor.length > 0) {
            return 24;
        }
    }
#endif
    
    if (section == 0 && self.tableViewStyle == RSTableViewStyleGrouped) {
        return (1 / [UIScreen mainScreen].scale);
    }
    
    if (section == 1 &&
        (self.dataType == RSTableViewTypeProfile || self.dataType == RSTableViewTypeCamp)) {
        return [BFHeaderView height];
    }
    
    return CGFLOAT_MIN;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(viewForFirstSectionHeader)]) {
            return [self.extendedDelegate viewForFirstSectionHeader];
        }
    }
    
#ifdef DEBUG
    if (self.dataType == RSTableViewTypeFeed && section != 0 && self.stream.posts.count > section) {
        Post *post = self.stream.posts[section-1];
        
        if (post.prevCursor.length > 0) {
            UIView *derp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 24)];
            derp.backgroundColor = [[UIColor separatorColor] colorWithAlphaComponent:0.5];
            
            UILabel *derpLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, derp.frame.size.width - 24, derp.frame.size.height)];
            NSString *string = @"";
            derpLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightRegular];
            derpLabel.textColor = [UIColor bonfireGray];
            if (post.prevCursor.length > 0) {
                string = [@"prev: " stringByAppendingString:post.prevCursor];
            }
            derpLabel.text = string;
            [derp addSubview:derpLabel];
            
            [derp bk_whenTapped:^{
                [Launcher shareOniMessage:[NSString stringWithFormat:@"post id: %@\n\nprev cursor: %@", post.identifier, post.prevCursor] image:nil];
            }];
            
            return derp;
        }
    }
#endif
    
    if (section == 0 && self.tableViewStyle == RSTableViewStyleGrouped) {
        UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        lineSeparator.backgroundColor = [UIColor separatorColor];
        
        return lineSeparator;
    }
    if (section == 1) {
        if ((self.loading || (!self.loading && self.stream.posts.count > 0)) &&
            (self.dataType == RSTableViewTypeProfile ||
            self.dataType == RSTableViewTypeCamp)) {
            BFHeaderView *header = [[BFHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, [BFHeaderView height])];
            
            if (self.dataType == RSTableViewTypeCamp) {
                header.title = @"Posts";
                
                if ([self.parentObject isKindOfClass:[Camp class]]) {
                    Camp *camp = self.parentObject;
                    
                    if (camp.attributes.summaries.counts.live >= [Session sharedInstance].defaults.camp.liveThreshold) {
                        UILabel *liveCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 100 - postContentOffset.right, header.titleLabel.frame.origin.y, 100, header.titleLabel.frame.size.height)];
                        liveCountLabel.text = [NSString stringWithFormat:@"%ld LIVE", (long)camp.attributes.summaries.counts.live];
                        liveCountLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
                        liveCountLabel.textColor = [UIColor colorWithDisplayP3Red:0.87 green:0.09 blue:0.09 alpha:1];
                        liveCountLabel.textAlignment = NSTextAlignmentRight;
                        [header addSubview:liveCountLabel];
                        
                        CGRect liveCountRect = [liveCountLabel.text boundingRectWithSize:CGSizeMake(liveCountLabel.frame.size.width, liveCountLabel.frame.size.height) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:liveCountLabel.font} context:nil];
                        
                        UIView *liveCountPulse = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - postContentOffset.right - ceilf(liveCountRect.size.width) - 10 - 6, roundf(liveCountLabel.frame.origin.y + (liveCountLabel.frame.size.height / 2) - 4.5), 9, 9)];
                        liveCountPulse.layer.cornerRadius = liveCountPulse.frame.size.height / 2;
                        liveCountPulse.layer.masksToBounds = true;
                        liveCountPulse.backgroundColor = liveCountLabel.textColor;
                        liveCountPulse.layer.shouldRasterize = true;
                        liveCountPulse.layer.rasterizationScale = [UIScreen mainScreen].scale;
                        [header addSubview:liveCountPulse];
                    }
                }
            }
            else if (self.dataType == RSTableViewTypeProfile) {
                header.title = @"Posts";
            }
            else {
                header.title = @"Posts";
            }
            
            return header;
        }
    }
    
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForFirstSectionFooter)]) {
            return [self.extendedDelegate heightForFirstSectionFooter];
        }
    }
    
    if (section != 0 && section == self.stream.posts.count) {
        // last row
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = (self.loadingMore || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor];
        
        return showLoadingFooter ? 52 : 0;
    }
    
#ifdef DEBUG
    if (section != 0 && self.dataType == RSTableViewTypeFeed && self.stream.posts.count > section) {
        Post *post = self.stream.posts[section-1];
        
        if (post.nextCursor.length > 0) {
            return 24;
        }
    }
#endif
    
//    if (section > 0 && self.stream.posts.count > section) {
//        // we do (> section) instead of (> section - 1) because we only show a divider if there is content under the post
//        Post *post = self.stream.posts[section-1];
//        Post *nextPost = self.stream.posts[section]; // only show section block if next post isn't sectioned as well
//
//        if (post.attributes.summaries.replies.count > 0 && nextPost.attributes.summaries.replies.count == 0) {
//            return 12;
//        }
//    }
    
    return (1 / [UIScreen mainScreen].scale);
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(viewForFirstSectionFooter)]) {
            return [self.extendedDelegate viewForFirstSectionFooter];
        }
    }
    
    if (section != 0 && section == self.stream.posts.count) {
        // last row
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = (self.loadingMore || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor];
        
        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 52)];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
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
    
#ifdef DEBUG
    if (section != 0 && self.dataType == RSTableViewTypeFeed && self.stream.posts.count > section) {
        Post *post = self.stream.posts[section-1];
        
        if (post.nextCursor.length > 0) {
            UIView *derp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 24)];
            derp.backgroundColor = [[UIColor separatorColor] colorWithAlphaComponent:0.5];
            
            UILabel *derpLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, derp.frame.size.width - 24, derp.frame.size.height)];
            NSString *string = @"";
            derpLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightRegular];
            derpLabel.textColor = [UIColor bonfireGray];
            if (post.nextCursor.length > 0) {
                string = [@"next: " stringByAppendingString:post.nextCursor];
            }
            derpLabel.text = string;
            [derp addSubview:derpLabel];
            
            [derp bk_whenTapped:^{
                [Launcher shareOniMessage:[NSString stringWithFormat:@"post id: %@\n\nnext cursor: %@", post.identifier, post.nextCursor] image:nil];
            }];
            
            return derp;
        }
    }
#endif
    
    if (section != 0 || self.tableViewStyle != RSTableViewStyleGrouped) return nil;
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor separatorColor];
    
    return lineSeparator;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//     if (self.dataType == RSTableViewTypeFeed) {
//         [[NSUserDefaults standardUserDefaults] setFloat:scrollView.contentOffset.y forKey:@"Home_ScrollPosition"];
//     }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//    if (self.dataType == RSTableViewTypeFeed) {
//        [[NSUserDefaults standardUserDefaults] setFloat:scrollView.contentOffset.y forKey:@"Home_ScrollPosition"];
//    }
}

@end
