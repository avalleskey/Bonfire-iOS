//
//  RSTableView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/4/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RSTableView.h"
#import "ComplexNavigationController.h"
//#import "Post.h"
//#import "Room.h"

#import "PostCell.h"
#import "ReplyCell.h"

#import "ExpandThreadCell.h"
#import "StreamPostCell.h"
#import "RoomHeaderCell.h"
#import "ProfileHeaderCell.h"
#import "RoomSuggestionsListCell.h"
#import "LoadingCell.h"
#import "PaginationCell.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "RoomViewController.h"
#import "ProfileCampsListViewController.h"
#import "InsightsLogger.h"

#import <JGProgressHUD/JGProgressHUD.h>
#import <HapticHelper/HapticHelper.h>
@import Firebase;

@implementation RSTableView

@synthesize dataType = _dataType;  //Must do this

static NSString * const bubbleReuseIdentifier = @"BubblePost";
static NSString * const streamPostReuseIdentifier = @"StreamPost";
static NSString * const postReplyReuseIdentifier = @"ReplyReuseIdentifier";
static NSString * const expandConversationReuseIdentifier = @"ExpandConversationReuseIdentifier";

static NSString * const previewReuseIdentifier = @"PreviewPost";
static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const suggestionsCellIdentifier = @"ChannelSuggestionsCell";
static NSString * const roomHeaderCellIdentifier = @"RoomHeaderCell";
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

- (void)refresh {
    [self reloadData];
    [self layoutIfNeeded];
    
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
    self.backgroundColor = [UIColor headerBackgroundColor];
    self.delegate = self;
    self.dataSource = self;
    self.separatorColor = [UIColor separatorColor];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    self.estimatedRowHeight = 0;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self sendSubviewToBack:self.refreshControl];
        
    [self registerClass:[PostCell class] forCellReuseIdentifier:bubbleReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamPostReuseIdentifier];
    [self registerClass:[ReplyCell class] forCellReuseIdentifier:postReplyReuseIdentifier];
    [self registerClass:[ExpandThreadCell class] forCellReuseIdentifier:expandConversationReuseIdentifier];
    
    [self registerClass:[RoomHeaderCell class] forCellReuseIdentifier:roomHeaderCellIdentifier];
    [self registerClass:[ProfileHeaderCell class] forCellReuseIdentifier:profileHeaderCellIdentifier];
    [self registerClass:[RoomSuggestionsListCell class] forCellReuseIdentifier:suggestionsCellIdentifier];
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
        
        NSLog(@"changes??? %@", (changes ? @"YES" : @"NO"));
        
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
            if (![UIViewParentController(self).navigationController.topViewController isKindOfClass:[UIViewParentController(self) class]]) {
                [self refresh];
            }
        }
    }
}
- (void)postDeleted:(NSNotification *)notification {
    if (![notification.object isKindOfClass:[Post class]]) return;
    
    Post *post = notification.object;
    BOOL isReply = post.attributes.details.parentId != 0;
    BOOL postedInRoom = post.attributes.status.postedIn != nil;
    
    BOOL removePost = false;
    BOOL refresh = false;
    if ([self.parentObject isKindOfClass:[Room class]] && postedInRoom) {
        Room *parentRoom = self.parentObject;
        
        // determine type of post (post or reply)
        if ([parentRoom.identifier isEqualToString:post.attributes.status.postedIn.identifier]) {
            removePost = true;
            refresh = true;
            // Room that contains post
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
                        NSLog(@":::::update replies array:::::");
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:updatedPost];
                    
                    NSLog(@"✅ Decrement Post replies count inside Room");
                }
            }
            else {
                // Decrement Room posts count
                parentRoom.attributes.summaries.counts.posts = parentRoom.attributes.summaries.counts.posts - 1;
                
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
    // 1) Decrement Room posts count
    //       IF (parentObject isKindOfClass:Room &&
    //           type == post &&
    //           post.postedIn.identifier == parentObject.identifier)
    // 2) Decrement Post replies count
    //       IF (parentObject isKindOfClass:Room &&
    //           type == reply &&
    //           post.postedIn.identifier == parentObject.identifier)
    // 2b) Decrement Post replies count
    //       IF (parentObject isKindOfClass:Post &&
    //           type == reply &&
    //           post.parentId == parentObject.identifier)
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && self.parentObject) {
        // Header (used in Profiles, Rooms, Post Details)
        if (self.dataType == RSTableViewTypeRoom && [self.parentObject isKindOfClass:[Room class]]) {
            Room *room = self.parentObject;
            
            RoomHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:roomHeaderCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[RoomHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:roomHeaderCellIdentifier];
            }
            cell.room = room;
            
            if (self.loading && room.attributes.details.title.length == 0) {
                cell.textLabel.text = @"Loading...";
            }
            if (self.loading && room.attributes.details.identifier.length == 0) {
                cell.detailTextLabel.text = @"#Camptag";
            }
            
            cell.followButton.hidden = (cell.room.identifier.length == 0 && !self.loading);
            cell.detailsCollectionView.hidden = (room.attributes.status.visibility == nil || (!cell.room.identifier && !self.loading));
            
            if (room.attributes.status.isBlocked) {
                [cell.followButton updateStatus:ROOM_STATUS_ROOM_BLOCKED];
            }
            else if (self.loading && room.attributes.context == nil) {
                [cell.followButton updateStatus:ROOM_STATUS_LOADING];
            }
            else {
                [cell.followButton updateStatus:room.attributes.context.status];
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
                    [cell.followButton updateStatus:user.attributes.context.status];
                }
            }
            
            return cell;
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
        NSInteger adjustedRowIndex = indexPath.section - 1;
        
        if ([self.stream.posts[adjustedRowIndex].type isEqualToString:@"post"]) {
            Post *post = self.stream.posts[adjustedRowIndex];
            NSInteger snapshotReplies = post.attributes.summaries.replies.count;
            
            BOOL showSnapshot = snapshotReplies > 0;
            
            if (indexPath.row == 0) {
                StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:streamPostReuseIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:streamPostReuseIdentifier];
                }
                
                NSInteger identifierBefore = cell.post.identifier;
                
                post.attributes.details.url = @"https://open.spotify.com/track/47n6zyO3Uf9axGAPIY0ZOd?si=5iYV0vEbTNCfihI43MyBQw";
                
                // must set before cell.post
                cell.includeContext = true;
                cell.post = post;
                
                if (cell.post.identifier != 0 && identifierBefore == cell.post.identifier) {
                    [self didBeginDisplayingCell:cell];
                }
                
                if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
                    [cell.actionsView.replyButton bk_whenTapped:^{
                        [[Launcher sharedInstance] openComposePost:cell.post.attributes.status.postedIn inReplyTo:cell.post withMessage:nil media:nil];
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
                
                NSInteger identifierBefore = cell.post.identifier;
                
                Post *snapshotReply = post.attributes.summaries.replies[indexPath.row-1];
                cell.post = snapshotReply;
                
                if (cell.post.identifier != 0 && identifierBefore == cell.post.identifier) {
                    [self didBeginDisplayingCell:cell];
                }
                
                if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
                    [cell.actionsView.replyButton bk_whenTapped:^{
                        [[Launcher sharedInstance] openComposePost:cell.post.attributes.status.postedIn inReplyTo:cell.post withMessage:nil media:nil];
                    }];
                }
                
                cell.lineSeparator.hidden = false;
                
                cell.topCell = YES;
                cell.bottomCell = YES;
                
                cell.selectable = YES;
                
                return cell;
            }
        }
    }
    else if (indexPath.section == self.stream.posts.count + 1) {
        // loading cell
        PaginationCell *cell = [tableView dequeueReusableCellWithIdentifier:paginationCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[PaginationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:paginationCellIdentifier];
        }
        
        cell.contentView.backgroundColor =
        cell.backgroundColor = [UIColor clearColor];
        
        cell.loading = true;
        cell.spinner.hidden = false;
        [cell.spinner startAnimating];
        
        cell.userInteractionEnabled = false;
        
        return cell;
    }

    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGFloat)cellHeightForRoom:(Room *)room {
    CGFloat maxWidth = self.frame.size.width - (ROOM_HEADER_EDGE_INSETS.left + ROOM_HEADER_EDGE_INSETS.right);
    
    // knock out all the required bits first
    CGFloat height = ROOM_HEADER_EDGE_INSETS.top + ROOM_HEADER_AVATAR_SIZE + ROOM_HEADER_AVATAR_BOTTOM_PADDING;
    
    CGRect textLabelRect = [(room.attributes.details.title.length > 0 ? room.attributes.details.title : @"Unkown Camp") boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:ROOM_HEADER_NAME_FONT} context:nil];
    CGFloat roomTitleHeight = ceilf(textLabelRect.size.height);
    height = height + roomTitleHeight;
    
    CGRect roomTagRect = [[NSString stringWithFormat:@"#%@", room.attributes.details.identifier] boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:ROOM_HEADER_TAG_FONT} context:nil];
    CGFloat roomTagHeight = ceilf(roomTagRect.size.height);
    height = height + ROOM_HEADER_NAME_BOTTOM_PADDING + roomTagHeight;
    
    if (room.attributes.details.theDescription.length > 0) {
        NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:room.attributes.details.theDescription];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:3.f];
        [style setAlignment:NSTextAlignmentCenter];
        [attrString addAttribute:NSParagraphStyleAttributeName
                           value:style
                           range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:NSFontAttributeName value:ROOM_HEADER_DESCRIPTION_FONT range:NSMakeRange(0, attrString.length)];
        
        CGRect descriptionRect = [attrString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)  context:nil];
        CGFloat roomDescriptionHeight = ceilf(descriptionRect.size.height);
        height = height + ROOM_HEADER_TAG_BOTTOM_PADDING + roomDescriptionHeight;
    }
    
    if (room.attributes.details.identifier.length > 0 || room.identifier.length > 0) {
        CGFloat detailsHeight = 0;
        NSMutableArray *details = [[NSMutableArray alloc] init];
        
        if (room.attributes.status.visibility != nil) {
            BFDetailItem *visibility = [[BFDetailItem alloc] initWithType:(room.attributes.status.visibility.isPrivate ? BFDetailItemTypePrivacyPrivate : BFDetailItemTypePrivacyPublic) value:(room.attributes.status.visibility.isPrivate ? @"Private" : @"Public") action:nil];
            [details addObject:visibility];
        }
        
        if (room.attributes.summaries.counts != nil) {
            BFDetailItem *members = [[BFDetailItem alloc] initWithType:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)room.attributes.summaries.counts.members] action:nil];
            [details addObject:members];
        }
        
        if (details.count > 0) {
            BFDetailsCollectionView *detailCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(PROFILE_HEADER_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - PROFILE_HEADER_EDGE_INSETS.left - PROFILE_HEADER_EDGE_INSETS.right, 16)];
            detailCollectionView.delegate = detailCollectionView;
            detailCollectionView.dataSource = detailCollectionView;
            [detailCollectionView setDetails:details];
            
            detailsHeight = ROOM_HEADER_DETAILS_EDGE_INSETS.top + detailCollectionView.collectionViewLayout.collectionViewContentSize.height;
            height = height + (room.attributes.details.theDescription.length > 0 ? ROOM_HEADER_DESCRIPTION_BOTTOM_PADDING : ROOM_HEADER_TAG_BOTTOM_PADDING) + detailsHeight;
        }
        
        if (room.identifier.length > 0 || self.loading) {
            CGFloat userPrimaryActionHeight = ROOM_HEADER_FOLLOW_BUTTON_TOP_PADDING + 36;
            height = height + userPrimaryActionHeight;
        }
    }
    
    // add bottom padding and line separator
    height = height + ROOM_HEADER_EDGE_INSETS.bottom + (1 / [UIScreen mainScreen].scale);
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // header (used in Profiles, Camps)
        if (self.dataType == RSTableViewTypeRoom && [self.parentObject isKindOfClass:[Room class]]) {
            Room *room = self.parentObject;
            
            return [self cellHeightForRoom:room];
        }
        else if (self.dataType == RSTableViewTypeProfile && [self.parentObject isKindOfClass:[User class]]) {
            User *user = self.parentObject;
            
            return [ProfileHeaderCell heightForUser:user isLoading:self.loading];
        }
    }
    else if (indexPath.section - 1 < self.stream.posts.count) {
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
            return [StreamPostCell heightForPost:post]; // - (showSnapshot || showViewAllReplies ? 8 : 0);
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
                return 107;
                break;
            case 1:
                return 128;
                break;
            case 2:
                return 295;
                break;
                
            default:
                return 107;
                break;
        }
        
        return 107;
    }
    else if (indexPath.section - 1 == self.stream.posts.count) {
        return 52;
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
    if (self.loading) {
        self.scrollEnabled = false;
    }
    else {
        self.scrollEnabled = true;
    }
    
    if (self.stream.posts.count == 0 && self.loading) {
        // loading cells
        return 1 + 10;
    }
    
    return 1 + self.stream.posts.count + ((!self.reachedBottom && self.loadingMore) || self.loadingMore ? 1 : 0);
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        // headers
        if (self.dataType == RSTableViewTypeRoom ||
            self.dataType == RSTableViewTypeProfile) {
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
        BOOL snapshotReply = post.attributes.summaries.replies.count > 0;
        
        return 1 + (snapshotReply ? 1 : 0);
    }
    else if (section == self.stream.posts.count + 1 && self.stream.posts.count > 0) {
        // assume it's a pagination cell
        return 1;
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
                                         @"post_id": [NSString stringWithFormat:@"%ld", (long)cell.post.identifier]
                                         }];
        
        [[Launcher sharedInstance] openPost:cell.post withKeyboard:NO];
    }
}
//@property (nonatomic) NSInteger lastSinceId;
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if([cell isKindOfClass:[PaginationCell class]]) {
        Post *lastPost = [self.stream.posts lastObject];
        self.loadingMore = true;
        
        PaginationCell *paginationCell = (PaginationCell *)cell;
        if (!paginationCell.loading) {
            paginationCell.loading = true;
            paginationCell.spinner.hidden = false;
            [paginationCell.spinner startAnimating];
        }
        
        if (!self.reachedBottom) {
            if ([self.paginationDelegate respondsToSelector:@selector(tableView:didRequestNextPageWithMaxId:)]) {
                [self.paginationDelegate tableView:self didRequestNextPageWithMaxId:lastPost.identifier];
            }
        }
    }
    else {
        // NSLog(@"willDisplayCell");
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
    switch (self.dataType) {
        case RSTableViewTypeFeed:
            if (self.dataSubType == RSTableViewSubTypeHome) {
                seenIn = InsightSeenInHomeView;
            }
            if (self.dataSubType == RSTableViewSubTypeTrending) {
                seenIn = InsightSeenInTrendingView;
            }
            break;
        case RSTableViewTypeRoom:
            seenIn = InsightSeenInRoomView;
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
        if (self.dataSubType == RSTableViewSubTypeTrending && (self.loading || (!self.loading && self.stream.posts.count > 0))) {
            return 188 + 56;
        }

        return (1 / [UIScreen mainScreen].scale);
    }
    
    if (self.dataType == RSTableViewTypeProfile ||
        self.dataType == RSTableViewTypeRoom) {
        return section == 1 ? 56 : CGFLOAT_MIN; // 8 = spacing underneath
    }
    
    return 0;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
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
            [FIRAnalytics logEventWithName:@"copy_beta_invite_link"
                                parameters:@{@"location": @"trending_header"}];
            
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = @"http://testflight.com/bonfire-ios";
            
            JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
            HUD.textLabel.text = @"Copied Beta Link!";
            HUD.vibrancyEnabled = false;
            HUD.animation = [[JGProgressHUDFadeZoomAnimation alloc] init];
            HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
            HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
            HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
            
            [HUD showInView:[Launcher sharedInstance].activeViewController.view animated:YES];
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
            
            [HUD dismissAfterDelay:1.5f];
            
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
    
    if (section == 0) {
        UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        lineSeparator.backgroundColor = [UIColor separatorColor];
        
        return lineSeparator;
    }
    if (section == 1) {
        if ((self.loading || (!self.loading && self.stream.posts.count > 0)) &&
            (self.dataType == RSTableViewTypeProfile ||
            self.dataType == RSTableViewTypeRoom)) {
            UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 56)];
            
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 56)];
            [headerContainer addSubview:header];
                
            header.backgroundColor = [UIColor headerBackgroundColor];
            
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 30, self.frame.size.width - 66 - 100, 18)];
            if (self.dataType == RSTableViewTypeRoom) {
                title.text = @"POSTS";
                
                if ([self.parentObject isKindOfClass:[Room class]]) {
                    Room *room = self.parentObject;
                    
                    UILabel *liveCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 100 - postContentOffset.right, title.frame.origin.y, 100, title.frame.size.height)];
                    liveCountLabel.text = [NSString stringWithFormat:@"%ld LIVE", (long)room.attributes.summaries.counts.live];
                    liveCountLabel.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightBold];
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
                    
                    if (room.attributes.summaries.counts.live == 0) {
                        liveCountLabel.hidden = true;
                    }
                    else {
                        liveCountLabel.hidden = false;
                    }
                    liveCountPulse.hidden = liveCountLabel.isHidden;
                }
            }
            else if (self.dataType == RSTableViewTypeProfile) {
                title.text = @"RECENT POSTS";
            }
            else {
                title.text = @"RECENT POSTS";
            }
            title.textAlignment = NSTextAlignmentLeft;
            title.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightSemibold];
            title.textColor = [UIColor bonfireGray];
            
            [header addSubview:title];
                
            UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, 1 / [UIScreen mainScreen].scale)];
            lineSeparator.backgroundColor = [UIColor separatorColor];
            [header addSubview:lineSeparator];
            
            return headerContainer;
        }
    }
    
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

@end
