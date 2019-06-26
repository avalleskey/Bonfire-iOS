//
//  RSTableView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/4/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RSTableView.h"
#import "ComplexNavigationController.h"

#import "PostCell.h"
#import "ReplyCell.h"

#import "ExpandThreadCell.h"
#import "StreamPostCell.h"
#import "CampHeaderCell.h"
#import "ProfileHeaderCell.h"
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

#define MAX_SNAPSHOT_REPLIES 2

@implementation RSTableView

@synthesize dataType = _dataType;  //Must do this

static NSString * const bubbleReuseIdentifier = @"BubblePost";
static NSString * const streamPostReuseIdentifier = @"StreamPost";
static NSString * const postReplyReuseIdentifier = @"ReplyReuseIdentifier";
static NSString * const expandConversationReuseIdentifier = @"ExpandConversationReuseIdentifier";

static NSString * const previewReuseIdentifier = @"PreviewPost";
static NSString * const blankCellIdentifier = @"BlankCell";
// static NSString * const homeHeaderCellIdentifier = @"HomeHeaderCell";
static NSString * const campHeaderCellIdentifier = @"CampHeaderCell";
static NSString * const profileHeaderCellIdentifier = @"ProfileHeaderCell";

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
    if ([self.paginationDelegate respondsToSelector:@selector(tableViewDidScroll:)]) {
        [self.paginationDelegate tableViewDidScroll:self];
    }
}

- (void)scrollToTop {
    NSLog(@"boom!");

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
        
    [self registerClass:[PostCell class] forCellReuseIdentifier:bubbleReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamPostReuseIdentifier];
    [self registerClass:[ReplyCell class] forCellReuseIdentifier:postReplyReuseIdentifier];
    [self registerClass:[ExpandThreadCell class] forCellReuseIdentifier:expandConversationReuseIdentifier];
    
    [self registerClass:[CampHeaderCell class] forCellReuseIdentifier:campHeaderCellIdentifier];
    [self registerClass:[ProfileHeaderCell class] forCellReuseIdentifier:profileHeaderCellIdentifier];
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
        
        // if self.parentObject is a post, update that
        if ([self.parentObject isKindOfClass:[Post class]]) {
            Post *p = self.parentObject;
            if (p.identifier == post.identifier) {
                // same post
                changes = true;
                self.parentObject = post;
            }
        }
        
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
    
    
    // TODO:
    // 1) Decrement Camp posts count
    //       IF (parentObject isKindOfClass:Camp &&
    //           type == post &&
    //           post.postedIn.identifier == parentObject.identifier)
    // 2) Decrement Post replies count
    //       IF (parentObject isKindOfClass:Camp &&
    //           type == reply &&
    //           post.postedIn.identifier == parentObject.identifier)
    // 2b) Decrement Post replies count
    //       IF (parentObject isKindOfClass:Post &&
    //           type == reply &&
    //           post.parentId == parentObject.identifier)
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && self.parentObject) {
        // Header (used in Profiles, Camps, Post Details)
        if (self.dataType == RSTableViewTypeCamp && [self.parentObject isKindOfClass:[Camp class]]) {
            Camp *camp = self.parentObject;
            
            CampHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:campHeaderCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[CampHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:campHeaderCellIdentifier];
            }
            cell.camp = camp;
            
            BOOL emptyCampTitle = camp.attributes.details.title.length == 0;
            BOOL emptyCamptag = camp.attributes.details.identifier.length == 0;
            if (self.loading) {
                if (emptyCampTitle) {
                    cell.textLabel.text = @"Loading...";
                }
                if (emptyCamptag) {
                    cell.detailTextLabel.text = @"Loading...";
                }
            }
            else {
                if (emptyCamptag) {
                    cell.detailTextLabel.text = @"Unknown Camp";
                    if (emptyCampTitle) {
                        cell.textLabel.text = @"Unknown Camp";
                    }
                }
                else {
                    if (emptyCampTitle) {
                        cell.textLabel.text = [NSString stringWithFormat:@"#%@", camp.attributes.details.identifier];
                    }
                }
            }
            
            cell.followButton.hidden = (cell.camp.identifier.length == 0);
            
            if ([camp.attributes.context.camp.permissions canUpdate]) {
                [cell.followButton updateStatus:CAMP_STATUS_CAN_EDIT];
            }
            else if ([camp.attributes.status isBlocked]) {
                [cell.followButton updateStatus:CAMP_STATUS_CAMP_BLOCKED];
            }
            else if (self.loading && camp.attributes.context == nil) {
                [cell.followButton updateStatus:CAMP_STATUS_LOADING];
            }
            else {
                [cell.followButton updateStatus:camp.attributes.context.camp.status];
            }
            
            return cell;
        }
        else if (self.dataType == RSTableViewTypeProfile && [self.parentObject isKindOfClass:[User class]]) {
            User *user = self.parentObject;
            
            ProfileHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:profileHeaderCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ProfileHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:profileHeaderCellIdentifier];
            }
            
            cell.user = user;
            
            BOOL hasValidIdentifier = (cell.user.attributes.details.identifier.length > 0 || cell.user.identifier.length >   0);
            cell.followingButton.hidden =
            cell.campsButton.hidden = !hasValidIdentifier || (!self.loading && cell.user.identifier.length == 0);
            
            cell.followButton.hidden =
            cell.detailsCollectionView.hidden = (!cell.user.identifier && !self.loading);
            
            cell.detailTextLabel.textColor = [UIColor fromHex:user.attributes.details.color];
            
            if (!cell.followButton.isHidden) {
                if ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
                    [cell.followButton updateStatus:USER_STATUS_ME];
                }
                else if (self.loading && user.attributes.context == nil) {
                    [cell.followButton updateStatus:USER_STATUS_LOADING];
                }
                else {
                    [cell.followButton updateStatus:user.attributes.context.me.status];
                }
            }
            
            return cell;
        }
        /*else if (self.dataSubType == RSTableViewSubTypeHome && [self.parentObject isKindOfClass:[NSArray class]]) {
            MiniCampsListCell *cell = [tableView dequeueReusableCellWithIdentifier:homeHeaderCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[MiniCampsListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:homeHeaderCellIdentifier];
            }
            
            cell.loading = true;

         if (self.loadingCamps && self.camps.count == 0) {
                cell.loading = true;
            }
            else {
                cell.loading = false;
                cell.users = self.parentObject;
                
                [cell.collectionView reloadData];
            }
            
            return cell;
        }*/
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
        NSInteger adjustedRowIndex = indexPath.section - 1;
        
        if ([self.stream.posts[adjustedRowIndex].type isEqualToString:@"post"]) {
            Post *post = self.stream.posts[adjustedRowIndex];
            NSInteger snapshotReplies = post.attributes.summaries.replies.count;
            if (snapshotReplies > MAX_SNAPSHOT_REPLIES)
                snapshotReplies = MAX_SNAPSHOT_REPLIES;
            
            BOOL showSnapshot = snapshotReplies > 0;
            
            if (indexPath.row == 0) {
                StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:streamPostReuseIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:streamPostReuseIdentifier];
                }
                
                NSString *identifierBefore = cell.post.identifier;
                                
                // must set before cell.post
                cell.showContext = true;
                cell.showCamptag = !([self.parentObject isKindOfClass:[Camp class]] && [((Camp *)self.parentObject).identifier isEqualToString:post.attributes.status.postedIn.identifier]);
                cell.post = post;
                
                if (cell.post.identifier != 0 && ![identifierBefore isEqualToString:cell.post.identifier]) {
                    [self didBeginDisplayingCell:cell];
                }
                
                if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
                    [cell.actionsView.replyButton bk_whenTapped:^{
                        [Launcher openComposePost:cell.post.attributes.status.postedIn inReplyTo:cell.post withMessage:nil media:nil];
                    }];
                }
                
                cell.lineSeparator.hidden = showSnapshot;
                
                return cell;
            }
            else if (showSnapshot && (indexPath.row - 1) < snapshotReplies) {
                // reply
                ReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:postReplyReuseIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[ReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postReplyReuseIdentifier];
                }
                
                NSString *identifierBefore = cell.post.identifier;
                
                Post *snapshotReply = post.attributes.summaries.replies[indexPath.row-1];
                cell.post = snapshotReply;
                
                if (cell.post.identifier != 0 && ![identifierBefore isEqualToString:cell.post.identifier]) {
                    [self didBeginDisplayingCell:cell];
                }
                
                if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
                    [cell.actionsView.replyButton bk_whenTapped:^{
                        [Launcher openComposePost:cell.post.attributes.status.postedIn inReplyTo:cell.post withMessage:nil media:nil];
                    }];
                }
                
                cell.topCell = indexPath.row == 1;
                cell.bottomCell = indexPath.row == snapshotReplies;
                
                cell.lineSeparator.hidden = !cell.bottomCell;
                
                cell.selectable = YES;
                
                return cell;
            }
        }
    }

    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // header (used in Profiles, Camps)
        if (self.dataType == RSTableViewTypeCamp && [self.parentObject isKindOfClass:[Camp class]]) {
            Camp *camp = self.parentObject;
            
            return [CampHeaderCell heightForCamp:camp isLoading:self.loading];
        }
        else if (self.dataType == RSTableViewTypeProfile && [self.parentObject isKindOfClass:[User class]]) {
            User *user = self.parentObject;
            
            return [ProfileHeaderCell heightForUser:user isLoading:self.loading];
        }
        /*
        else if (self.dataSubType == RSTableViewSubTypeHome) {
            return MINI_CARD_HEIGHT;
        }
         */
    }
    else if (indexPath.section - 1 < self.stream.posts.count && [self.stream.posts[indexPath.section-1].type isEqualToString:@"post"]) {
        Post *post = self.stream.posts[indexPath.section-1];
        //NSInteger replies = post.attributes.summaries.counts.replies;
        NSInteger snapshotReplies = post.attributes.summaries.replies.count;
        // 0       : actual reply
        // 1       : --- "hide replies"
        // 2-(x+1) : --- replies
        // (x+1)+1 : --- "view more replies"
        // (x+1)+2 : --- "add a reply..."
        
        BOOL showSnapshot = snapshotReplies > 0;
        //BOOL showViewAllReplies = (showSnapshot || replies > 0);
        
        if (indexPath.row == 0) {
            return [StreamPostCell heightForPost:post showContext:true]; // - (showSnapshot || showViewAllReplies ? 8 : 0);
        }
        else if (showSnapshot && (indexPath.row - 1) < snapshotReplies) {
            // snapshot reply
            Post *reply = post.attributes.summaries.replies[indexPath.row - 1];
            return [ReplyCell heightForPost:reply];
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
        // headers
        if (self.dataType == RSTableViewTypeCamp ||
            self.dataType == RSTableViewTypeProfile/* ||
            self.dataSubType == RSTableViewSubTypeHome*/) {
            return 1;
        }
    }
    else if (self.stream.posts.count == 0 && self.loading) {
        // loading cells
        return 1;
    }
    else if (section <= self.stream.posts.count) {
        // content
        Post *post = self.stream.posts[section-1];
        NSInteger snapshotReplies = post.attributes.summaries.replies.count;
        if (snapshotReplies > MAX_SNAPSHOT_REPLIES)
            snapshotReplies = MAX_SNAPSHOT_REPLIES;
        
        return 1 + snapshotReplies;
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[PostCell class]]) {
        PostCell *cell = (PostCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        if (!cell.post) return;
        
        [InsightsLogger.sharedInstance closePostInsight:cell.post.identifier action:InsightActionTypeDetailExpand];
        [FIRAnalytics logEventWithName:@"conversation_expand"
                            parameters:@{
                                         @"post_id": cell.post.identifier
                                         }];
        
        [Launcher openPost:cell.post withKeyboard:NO];
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
    
    /*
     if (self.stream.posts.count > section - 1) {
     Post *post = self.stream.posts[section-1];
     
     if (post.attributes.summaries.replies.count > 0) {
     return 12;
     }
     }
     */
    
    return CGFLOAT_MIN;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
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
    
    if (section == 0 && self.dataSubType == RSTableViewSubTypeTrending && (self.loading || (!self.loading && self.stream.posts.count > 0))) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 188 + 56)];
        
        UIView *upsell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, header.frame.size.width, 188)];
        upsell.layer.cornerRadius = 10.f;
        upsell.backgroundColor = [UIColor whiteColor];
        upsell.layer.masksToBounds = false;
        
        UIImageView *inviteGraphic = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 399 / 2, 17, 399, 86)];
        inviteGraphic.image = [UIImage imageNamed:@"inviteFriendUpsellGraphic"];
        inviteGraphic.contentMode = UIViewContentModeScaleAspectFill;
        [upsell addSubview:inviteGraphic];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 111, upsell.frame.size.width - 24, 22)];
        title.text = @"Bonfire is more fun with friends!";
        title.textColor = [UIColor bonfireBlack];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
        [upsell addSubview:title];
        
        UIButton *shareWithFriends = [UIButton buttonWithType:UIButtonTypeCustom];
        [shareWithFriends setTitle:@"Copy Beta Invite Link" forState:UIControlStateNormal];
        [shareWithFriends setTitleColor:[UIColor bonfireBrand] forState:UIControlStateNormal];
        shareWithFriends.frame = CGRectMake(upsell.frame.size.width / 2 - 100, 132, 200, 40);
        shareWithFriends.titleLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightSemibold];
        shareWithFriends.layer.cornerRadius = 10.f;
        //shareWithFriends.layer.borderWidth = 1.f;
        //shareWithFriends.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
        [shareWithFriends bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                shareWithFriends.transform = CGAffineTransformMakeScale(0.92, 0.92);
                shareWithFriends.alpha = 0.75;
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        [shareWithFriends bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                shareWithFriends.transform = CGAffineTransformIdentity;
                shareWithFriends.alpha = 1;
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        [shareWithFriends bk_whenTapped:^{
            [Launcher copyBetaInviteLink];
            
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                shareWithFriends.transform = CGAffineTransformIdentity;
                shareWithFriends.alpha = 1;
            } completion:nil];
        }];
        [upsell addSubview:shareWithFriends];
        
        [header addSubview:upsell];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, upsell.frame.origin.y + upsell.frame.size.height + 30, self.frame.size.width - 66 - 100, 18)];
        titleLabel.text = @"TRENDING NOW";
        titleLabel.textAlignment = NSTextAlignmentLeft;
        titleLabel.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightSemibold];
        titleLabel.textColor = [UIColor bonfireGray];
        [header addSubview:titleLabel];
        
        UIView *topLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, upsell.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        topLineSeparator.backgroundColor = [UIColor separatorColor];
        [header addSubview:topLineSeparator];
        
        UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, upsell.frame.size.height, upsell.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        lineSeparator.backgroundColor = [UIColor separatorColor];
        [header addSubview:lineSeparator];
        
        UIView *lineSeparator2 = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, 1 / [UIScreen mainScreen].scale)];
        lineSeparator2.backgroundColor = [UIColor separatorColor];
        [header addSubview:lineSeparator2];
        
        return header;
    }
    
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
    
//    if (self.stream.posts.count > section - 1) {
//        Post *post = self.stream.posts[section-1];
//
//        if (post.attributes.summaries.replies.count > 0) {
//            UIView *derp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 12)];
//            derp.backgroundColor = [UIColor headerBackgroundColor];
//
//            UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, derp.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
//            lineSeparator.backgroundColor = [UIColor separatorColor];
//            [derp addSubview:lineSeparator];
//
//            return derp;
//        }
//    }
    
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
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
    
    return section == 0 && self.tableViewStyle == RSTableViewStyleGrouped ? (1 / [UIScreen mainScreen].scale) : CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
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
                NSLog(@"fetch next page : %@", self.stream.nextCursor);
                
                if ([self.paginationDelegate respondsToSelector:@selector(tableView:didRequestNextPageWithMaxId:)]) {
                    [self.paginationDelegate tableView:self didRequestNextPageWithMaxId:0];
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
    
//    if (section > 0 && self.stream.posts.count > section) {
//        // we do (> section) instead of (> section - 1) because we only show a divider if there is content under the post
//        Post *post = self.stream.posts[section-1];
//        Post *nextPost = self.stream.posts[section]; // only show section block if next post isn't sectioned as well
//        
//        if (post.attributes.summaries.replies.count > 0 && nextPost.attributes.summaries.replies.count == 0) {
//            UIView *derp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 12)];
//            derp.backgroundColor = [UIColor headerBackgroundColor];
//            
//            UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, derp.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
//            lineSeparator.backgroundColor = [UIColor separatorColor];
//            [derp addSubview:lineSeparator];
//            
//            return derp;
//        }
//    }
    
    if (section != 0 || self.tableViewStyle != RSTableViewStyleGrouped) return nil;
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor separatorColor];
    
    return lineSeparator;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.dataType == RSTableViewTypeFeed) {
        NSLog(@"updated Home_ScrollPosition:: %f", scrollView.contentOffset.y);
        
        [[NSUserDefaults standardUserDefaults] setFloat:scrollView.contentOffset.y forKey:@"Home_ScrollPosition"];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.dataType == RSTableViewTypeFeed) {
        NSLog(@"updated Home_ScrollPosition:: %f", scrollView.contentOffset.y);
        
        [[NSUserDefaults standardUserDefaults] setFloat:scrollView.contentOffset.y forKey:@"Home_ScrollPosition"];
    }
}

@end
