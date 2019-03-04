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
#import "MiniReplyCell.h"
#import "ExpandThreadCell.h"
#import "StreamPostCell.h"
#import "RoomHeaderCell.h"
#import "ProfileHeaderCell.h"
#import "RoomSuggestionsListCell.h"
#import "LoadingCell.h"
#import "PaginationCell.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>
#import "RoomViewController.h"
#import "ProfileCampsListViewController.h"
#import "InsightsLogger.h"

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
    // update row heights
    for (int i = 0; i < self.stream.posts.count; i++) {
        id object = self.stream.posts[i];
        if ([object isKindOfClass:[Post class]]) {
            Post *postAtIndex = object;
            postAtIndex.rowHeight = 0;
        }
    }
    
    [self reloadData];
    
    [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.paginationDelegate respondsToSelector:@selector(tableViewDidScroll:)]) {
        [self.paginationDelegate tableViewDidScroll:self];
    }
}

- (void)scrollToTop {
    [self reloadData];
    [self layoutIfNeeded];
    [self setContentOffset:CGPointZero animated:YES];
    
    [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:([self numberOfRowsInSection:0] > 0 ? 0 : 1)] atScrollPosition:UITableViewScrollPositionTop animated:YES];
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
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    
    [self registerClass:[PostCell class] forCellReuseIdentifier:bubbleReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamPostReuseIdentifier];
    [self registerClass:[MiniReplyCell class] forCellReuseIdentifier:postReplyReuseIdentifier];
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
    BOOL isReply = post.attributes.details.parent != 0;
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
                Post *updatedPost = [self.stream postWithId:post.attributes.details.parent];
                if (updatedPost) {
                    updatedPost.attributes.summaries.counts.replies = updatedPost.attributes.summaries.counts.replies - 1;
        
                    // update replies
                    NSMutableArray <Post *> *mutableReplies = [[NSMutableArray alloc] initWithArray:updatedPost.attributes.summaries.replies];
                    NSMutableArray *repliesToDelete = [[NSMutableArray alloc] init];
                    for (int i = 0; i < mutableReplies.count; i++) {
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
            (parentPost.identifier == post.attributes.details.parent)) {
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
    //           post.parent == parentObject.identifier)
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
            
            cell.followButton.hidden =
            cell.detailsLabel.hidden = (!cell.room.identifier && !self.loading);
            
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
            cell.detailsLabel.hidden = (!cell.user.identifier && !self.loading);
            
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
            NSInteger replies = post.attributes.summaries.counts.replies;
            NSInteger snapshotReplies = post.attributes.summaries.replies.count;
            
            BOOL showSnapshot = snapshotReplies > 0;
            BOOL showViewAllReplies = (showSnapshot|| replies > 0);
            // BOOL showAddReply = false;
            
            if (indexPath.row == 0) {
                StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:streamPostReuseIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:streamPostReuseIdentifier];
                }
                
                NSInteger identifierBefore = cell.post.identifier;
                
                cell.post = post;
                
                if (cell.post.identifier != 0 && identifierBefore == cell.post.identifier) {
                    [self didBeginDisplayingCell:cell];
                }
                
                cell.lineSeparator.hidden = (showSnapshot || showViewAllReplies);
                if (!cell.lineSeparator.isHidden) {
                    if (adjustedRowIndex == (self.stream.posts.count - 1)) {
                        // last one
                        cell.lineSeparator.frame = CGRectMake(0, cell.frame.size.height - (1 / [UIScreen mainScreen].scale), cell.frame.size.width, 1 / [UIScreen mainScreen].scale);
                    }
                    else {
                        cell.lineSeparator.frame = CGRectMake(postContentOffset.left, cell.frame.size.height - (1 / [UIScreen mainScreen].scale), cell.frame.size.width - postContentOffset.left, 1 / [UIScreen mainScreen].scale);
                    }
                }
                
                return cell;
            }
            else if (showSnapshot && (indexPath.row - 1) < snapshotReplies) {
                // reply
                MiniReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:postReplyReuseIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[MiniReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postReplyReuseIdentifier];
                }
                
                NSInteger identifierBefore = cell.post.identifier;
                
                Post *snapshotReply = post.attributes.summaries.replies[indexPath.row-1];
                cell.post = snapshotReply;
                
                if (cell.post.identifier != 0 && identifierBefore == cell.post.identifier) {
                    [self didBeginDisplayingCell:cell];
                }
                
                cell.lineSeparator.hidden = !(indexPath.row == snapshotReplies && !showViewAllReplies);
                if (!cell.lineSeparator.isHidden) {
                    if (adjustedRowIndex == (self.stream.posts.count - 1)) {
                        // last one
                        cell.lineSeparator.frame = CGRectMake(0, cell.frame.size.height - (1 / [UIScreen mainScreen].scale), cell.frame.size.width, 1 / [UIScreen mainScreen].scale);
                    }
                    else {
                        cell.lineSeparator.frame = CGRectMake(postContentOffset.left, cell.frame.size.height - (1 / [UIScreen mainScreen].scale), cell.frame.size.width - postContentOffset.left, 1 / [UIScreen mainScreen].scale);
                    }
                }
                
                cell.selectable = true;
                
                return cell;
            }
            else if (showViewAllReplies && (indexPath.row - 1) == snapshotReplies) {
                // "view more replies"
                ExpandThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:expandConversationReuseIdentifier forIndexPath:indexPath];
                
                if (!cell) {
                    cell = [[ExpandThreadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandConversationReuseIdentifier];
                }
                
                cell.backgroundColor = [UIColor whiteColor];
                cell.contentView.backgroundColor = [UIColor whiteColor];
                
                NSString *repliesString = post.attributes.summaries.counts.replies == 1 ? @"View 1 reply" : [NSString stringWithFormat:@"View all %ld replies", post.attributes.summaries.counts.replies];
                cell.textLabel.text = post.attributes.summaries.counts.replies > post.attributes.summaries.replies.count ? repliesString : @"View full conversation";
                
                cell.lineSeparator.hidden = false;
                if (adjustedRowIndex == (self.stream.posts.count - 1)) {
                    // last one
                    cell.lineSeparator.frame = CGRectMake(0, cell.frame.size.height - (1 / [UIScreen mainScreen].scale), cell.frame.size.width, 1 / [UIScreen mainScreen].scale);
                }
                else {
                    cell.lineSeparator.frame = CGRectMake(postContentOffset.left, cell.frame.size.height - (1 / [UIScreen mainScreen].scale), cell.frame.size.width - postContentOffset.left, 1 / [UIScreen mainScreen].scale);
                }
                
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
    
    if (room.identifier.length > 0) {
        NSArray *details = @[[BFDetailsLabel BFDetailWithType:(room.attributes.status.visibility.isPrivate ? BFDetailTypePrivacyPrivate : BFDetailTypePrivacyPublic) value:@"" action:nil], [BFDetailsLabel BFDetailWithType:BFDetailTypeMembers value:[NSNumber numberWithInteger:room.attributes.summaries.counts.members] action:nil]];
        CGFloat detailsHeight = ceilf([[BFDetailsLabel attributedStringForDetails:details linkColor:nil] boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil].size.height);
        height = height + (room.attributes.details.theDescription.length > 0 ? ROOM_HEADER_DESCRIPTION_BOTTOM_PADDING : ROOM_HEADER_TAG_BOTTOM_PADDING) +  ROOM_HEADER_DETAILS_EDGE_INSETS.top + detailsHeight;
        
        CGFloat userPrimaryActionHeight = ROOM_HEADER_FOLLOW_BUTTON_TOP_PADDING + 36;
        height = height + userPrimaryActionHeight;
    }
    
    // add bottom padding and line separator
    height = height + ROOM_HEADER_EDGE_INSETS.bottom + (1 / [UIScreen mainScreen].scale);
    
    return height;
}
- (CGFloat)cellHeightForUser:(User *)user {
    CGFloat maxWidth = self.frame.size.width - (PROFILE_HEADER_EDGE_INSETS.left + PROFILE_HEADER_EDGE_INSETS.right);
    
    // knock out all the required bits first
    CGFloat height = PROFILE_HEADER_EDGE_INSETS.top + PROFILE_HEADER_AVATAR_SIZE + PROFILE_HEADER_AVATAR_BOTTOM_PADDING;
    
    CGRect textLabelRect = [(user.attributes.details.displayName.length > 0 ? user.attributes.details.displayName : @"User") boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:PROFILE_HEADER_DISPLAY_NAME_FONT} context:nil];
    CGFloat userDisplayNameHeight = ceilf(textLabelRect.size.height);
    height = height + userDisplayNameHeight;
    
    CGRect usernameRect = [[NSString stringWithFormat:@"@%@", user.attributes.details.identifier] boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:PROFILE_HEADER_USERNAME_FONT} context:nil];
    CGFloat usernameHeight = ceilf(usernameRect.size.height);
    height = height + PROFILE_HEADER_DISPLAY_NAME_BOTTOM_PADDING + usernameHeight;
    
    if (user.attributes.details.bio.length > 0) {
        NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:user.attributes.details.bio];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:3.f];
        [style setAlignment:NSTextAlignmentCenter];
        [attrString addAttribute:NSParagraphStyleAttributeName
                           value:style
                           range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:NSFontAttributeName value:PROFILE_HEADER_BIO_FONT range:NSMakeRange(0, attrString.length)];
        
        CGRect bioRect = [attrString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)  context:nil];
        CGFloat bioHeight = ceilf(bioRect.size.height);
        height = height + PROFILE_HEADER_USERNAME_BOTTOM_PADDING + bioHeight;
    }
    
    NSMutableArray *details = [[NSMutableArray alloc] init];
    if (user.attributes.details.location) {
        [details addObject:[BFDetailsLabel BFDetailWithType:BFDetailTypeLocation value:user.attributes.details.location.value action:nil]];
    }
    if (user.attributes.details.website) {
        [details addObject:[BFDetailsLabel BFDetailWithType:BFDetailTypeWebsite value:user.attributes.details.website.value action:nil]];
    }
    
    if (details.count > 0) {
        CGFloat detailsHeight = ceilf([[BFDetailsLabel attributedStringForDetails:details linkColor:nil] boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil].size.height);
        height = height + (user.attributes.details.bio.length > 0 ? PROFILE_HEADER_BIO_BOTTOM_PADDING : PROFILE_HEADER_USERNAME_BOTTOM_PADDING) +  PROFILE_HEADER_DETAILS_EDGE_INSETS.top + detailsHeight;
    }
    
    CGFloat userPrimaryActionHeight = (user.identifier.length > 0 || self.loading ? PROFILE_HEADER_FOLLOW_BUTTON_TOP_PADDING + 36 : 0);
    height = height + userPrimaryActionHeight;
    
    // add bottom padding and line separator
    height = height + PROFILE_HEADER_EDGE_INSETS.bottom + (1 / [UIScreen mainScreen].scale);
    
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
            
            return [self cellHeightForUser:user];
        }
    }
    else if (indexPath.section - 1 < self.stream.posts.count) {
        Post *post = self.stream.posts[indexPath.section-1];
        NSInteger replies = post.attributes.summaries.counts.replies;
        NSInteger snapshotReplies = post.attributes.summaries.replies.count;
        // 0       : actual reply
        // 1       : --- "hide replies"
        // 2-(x+1) : --- replies
        // (x+1)+1 : --- "view more replies"
        // (x+1)+2 : --- "add a reply..."
        
        BOOL showSnapshot = snapshotReplies > 0;
        BOOL showViewAllReplies = (showSnapshot || replies > 0);
        
        if (indexPath.row == 0) {
            return [StreamPostCell heightForPost:post] - (showSnapshot || showViewAllReplies ? 8 : 0);
        }
        else if (showSnapshot && (indexPath.row - 1) < snapshotReplies) {
            // snapshot reply
            Post *reply = post.attributes.summaries.replies[indexPath.row - 1];
            return [MiniReplyCell heightForPost:reply];
        }
        else if ((indexPath.row - 1) == snapshotReplies) {
            return 48;
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
        CGFloat replies = post.attributes.summaries.counts.replies;
        CGFloat snapshotReplies = post.attributes.summaries.replies.count;
        // 0       : actual reply
        // 1       : --- "hide replies"
        // 2-(x+1) : --- replies
        // (x+1)+1 : --- "view more replies"
        // (x+1)+2 : --- "add a reply..."
        
        BOOL showSnapshot = snapshotReplies > 0;
        BOOL showViewAllReplies = (showSnapshot || replies > 0);
        // BOOL showAddReply = false;
        
        return 1 + snapshotReplies + (showViewAllReplies ? 1 : 0);
    }
    else if (section == self.stream.posts.count + 1 && self.stream.posts.count > 0) {
        // assume it's a pagination cell
        return 1;
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
    }
    else if (indexPath.section <= self.stream.posts.count) {
        // content
        NSInteger adjustedRowIndex = (indexPath.section - 1);
        if (self.stream.posts.count > adjustedRowIndex) {
            NSLog(@"did select row");
            // prevent getting object at index beyond bounds of array
            if ([self.stream.posts[adjustedRowIndex].type isEqualToString:@"post"] && !self.stream.posts[adjustedRowIndex].tempId /* && self.stream.posts[indexPath.row].attributes.details.parent == 0*/) {
                Post *postAtIndex = self.stream.posts[adjustedRowIndex];
                
                [InsightsLogger.sharedInstance closePostInsight:postAtIndex.identifier action:InsightActionTypeDetailExpand];
                
                [[Launcher sharedInstance] openPost:postAtIndex withKeyboard:NO];
            }
        }
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
    if (self.dataType == RSTableViewTypeProfile ||
        self.dataType == RSTableViewTypeRoom) {
        return section == 1 ? 64 : CGFLOAT_MIN; // 8 = spacing underneath
    }
    
    return 0;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        if ((self.loading || (!self.loading && self.stream.posts.count > 0)) &&
            (self.dataType == RSTableViewTypeProfile ||
            self.dataType == RSTableViewTypeRoom)) {
            UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 64)];
            
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 64)];
            [headerContainer addSubview:header];
                
            header.backgroundColor = [UIColor headerBackgroundColor];
            
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 32, self.frame.size.width - 66 - 100, 21)];
            if (self.dataType == RSTableViewTypeRoom) {
                title.text = @"Posts";
                
                if ([self.parentObject isKindOfClass:[Room class]]) {
                    Room *room = self.parentObject;
                    
                    UILabel *liveCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 100 - postContentOffset.right, title.frame.origin.y, 100, title.frame.size.height)];
                    liveCountLabel.text = [NSString stringWithFormat:@"%ld LIVE", (long)room.attributes.summaries.counts.live];
                    liveCountLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
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
                title.text = @"Recent Posts";
            }
            else {
                title.text = @"Recent Posts";
            }
            title.textAlignment = NSTextAlignmentLeft;
            title.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
            title.textColor = [UIColor colorWithWhite:0.47f alpha:1];
            
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
