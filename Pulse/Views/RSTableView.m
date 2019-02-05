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

#import "BubblePostCell.h"
#import "ThreadedPostCell.h"
#import "ExpandedPostCell.h"
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

static NSString * const expandedPostCellIdentifier = @"ExpandedPost";
static NSString * const bubbleReuseIdentifier = @"BubblePost";
static NSString * const threadedPostReuseIdentifier = @"ThreadedPost";
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
    [self setContentOffset:CGPointMake(0, -self.adjustedContentInset.top) animated:YES];
}

- (CGFloat)rowHeightForPost:(Post *)postAtIndex isReply:(BOOL)isReply {
    PostDisplayType type = [self typeForPost:postAtIndex];
    
    CGFloat height = postContentOffset.top;
    
    BOOL hasContext = false;
    if (hasContext) {
        height = height + postContextHeight + 8;
    }
    
    CGFloat screenWidth = self.frame.size.width;
    CGFloat leftOffset = (isReply ? replyContentOffset.left : postContentOffset.left);
    
    CGFloat nameHeight = 16 + 4; // +   2; // 1pt padding underneath
    height = height + nameHeight;
    
    // posted in indicator
    if (type != PostDisplayTypeThreaded) {
        Room *postedInRoom = postAtIndex.attributes.status.postedIn;
        NSString *currentRoomIdentifier = @"";
        if ([UIViewParentController(self) isKindOfClass:[RoomViewController class]]) {
            currentRoomIdentifier = ((Room *)self.parentObject).identifier;
        }
        
        CGFloat postedInHeight = (self.dataType != RSTableViewTypePost && !isReply && postedInRoom != nil && ![postedInRoom.identifier isEqualToString:currentRoomIdentifier]) ? 14 + 6 : 0;
        height = height + postedInHeight;
    }
    
    // message
    CGSize messageSize = [PostTextView sizeOfBubbleWithMessage:postAtIndex.attributes.details.simpleMessage withConstraints:CGSizeMake(screenWidth - leftOffset - (postTextViewInset.left + postTextViewInset.right) - 24, CGFLOAT_MAX) font:(isReply?textViewReplyFont:textViewFont)];
    CGFloat textViewHeight = postAtIndex.attributes.details.message.length == 0 ? 0 :  ceilf(messageSize.height) + (postTextViewInset.top + postTextViewInset.bottom);
    height = height + textViewHeight;

    // image
    BOOL hasImage = FBTweakValue(@"Post", @"General", @"Show Image", NO); // postAtIndex.images != nil && postAtIndex.images.count > 0;
    if (hasImage) {
        CGFloat imageHeight = hasImage ? [Session sharedInstance].defaults.post.imgHeight + 4 : 0;
        height = height + imageHeight;
    }
    
    // 4 on top and 4 on bottom
    BOOL hasURLPreview = [postAtIndex requiresURLPreview];
    if (hasURLPreview) {
        CGFloat urlPreviewHeight = !hasImage && hasURLPreview ? [Session sharedInstance].defaults.post.imgHeight + 4 : 0; // 4 on bottom
        height = height + urlPreviewHeight;
    }
    
    BOOL showSnapshot = (type == PostDisplayTypeSimple &&  postAtIndex.attributes.summaries.replies.count > 0);
    if (showSnapshot) {
        CGFloat snapshotHeight = 6 + 20 + 4; // 6 on top, 4 on bottom
        height = height + snapshotHeight;
    }
    
    // details view
    CGFloat detailsHeight = 16 + 4; // 6 = padding above details view
    height = height + detailsHeight;
    
    height = height + postContentOffset.bottom;
    
    return height;
}

- (void)setup {
    self.reachedBottom = false;
    self.stream = [[PostStream alloc] init];
    self.loading = true;
    self.loadingMore = false;
    self.backgroundColor = [UIColor headerBackgroundColor];
    self.delegate = self;
    self.dataSource = self;
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.separatorColor = [UIColor separatorColor];
    self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    
    [self registerClass:[ExpandedPostCell class] forCellReuseIdentifier:expandedPostCellIdentifier];
    [self registerClass:[BubblePostCell class] forCellReuseIdentifier:bubbleReuseIdentifier];
    [self registerClass:[ThreadedPostCell class] forCellReuseIdentifier:threadedPostReuseIdentifier];
    
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
    NSLog(@"postDeleted:");
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
                    NSMutableArray *mutableReplies = [[NSMutableArray alloc] initWithArray:updatedPost.attributes.summaries.replies];
                    NSMutableArray *repliesToDelete = [[NSMutableArray alloc] init];
                    for (int i = 0; i < mutableReplies.count; i++) {
                        Post *reply = [[Post alloc] initWithDictionary:mutableReplies[i] error:nil];
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
        else if (self.dataType == RSTableViewTypePost && [self.parentObject isKindOfClass:[Post class]]) {
            ExpandedPostCell *cell = [tableView dequeueReusableCellWithIdentifier:expandedPostCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ExpandedPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandedPostCellIdentifier];
            }
            
            cell.loading = self.loading;
            
            cell.post = self.parentObject;
            cell.nameLabel.attributedText = [BubblePostCell attributedCreatorStringForPost:cell.post];
            
            if (cell.post.identifier != 0) {
                [self didBeginDisplayingCell:cell];
            }
            
            if ([cell.pictureView gestureRecognizers].count == 0) {
                [cell.pictureView bk_whenTapped:^{
                    [[Launcher sharedInstance] expandImageView:cell.pictureView];
                }];
            }
            
            return cell;
        }
    }
    else {
        // Content
        if (self.stream.posts.count <= indexPath.row) {
            if (self.stream.posts.count == 0 && self.dataType != RSTableViewTypePost) {
                // loading cell
                LoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[LoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:loadingCellIdentifier];
                }
                
                NSInteger postType = (indexPath.row) % 3;
                cell.type = postType;
                cell.shimmerContainer.shimmering = true;
                
                cell.userInteractionEnabled = false;
                
                if (self.dataType == RSTableViewTypePost) {
                    cell.lineSeparator.hidden = true;
                }
                
                return cell;
            }
            else {
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
        }
        else if ([self.stream.posts[indexPath.row].type isEqualToString:@"post"]) {
            if (self.stream.posts.count > indexPath.row) {
                PostDisplayType displayType = [self typeForPost:self.stream.posts[indexPath.row]];
                
                if (displayType == PostDisplayTypeSimple) {
                    BubblePostCell *cell = [tableView dequeueReusableCellWithIdentifier:bubbleReuseIdentifier forIndexPath:indexPath];
                    
                    if (cell == nil) {
                        cell = [[BubblePostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:bubbleReuseIdentifier];
                    }
                    
                    NSInteger identifierBefore = cell.post.identifier;
                    
                    // [cell setThemed:(self.stream.posts[indexPath.row].attributes.details.parent != 0 && self.dataType == RSTableViewTypePost)];
                    cell.post = self.stream.posts[indexPath.row];
                    
                    cell.selectable = ![cell isReply];
                    
                    if (cell.post.identifier != 0 && identifierBefore == cell.post.identifier) {
                        [self didBeginDisplayingCell:cell];
                    }
                    
                    // posted in indicator
                    Room *postedInRoom = cell.post.attributes.status.postedIn;
                    NSString *currentRoomIdentifier = @"";
                    if ([UIViewParentController(self) isKindOfClass:[RoomViewController class]]) {
                        currentRoomIdentifier = ((Room *)self.parentObject).identifier;
                    }
                    
                    BOOL showPostedIn = (self.dataType != RSTableViewTypePost && ![cell isReply] && postedInRoom != nil && ![postedInRoom.identifier isEqualToString:currentRoomIdentifier]);
                    cell.postedInButton.hidden = !showPostedIn;
                    if (showPostedIn) {
                        [UIView performWithoutAnimation:^{
                            [cell.postedInButton setTitle:cell.post.attributes.status.postedIn.attributes.details.title forState:UIControlStateNormal];
                            [cell.postedInButton layoutIfNeeded];
                        }];
                        cell.postedInButton.tintColor = [UIColor fromHex:cell.post.attributes.status.postedIn.attributes.details.color];
                        [cell.postedInButton setTitleColor:cell.postedInButton.tintColor forState:UIControlStateNormal];
                        if (cell.postedInButton.gestureRecognizers.count == 0 && cell.post.attributes.status.postedIn) {
                            [cell.postedInButton bk_whenTapped:^{
                                [[Launcher sharedInstance] openRoom:cell.post.attributes.status.postedIn];
                            }];
                        }
                    }
                    
                    cell.repliesSnapshotView.hidden = !(displayType == PostDisplayTypeSimple &&  cell.post.attributes.summaries.replies.count > 0);
                    
                    return cell;
                }
                if (displayType == PostDisplayTypeThreaded) {
                    ThreadedPostCell *cell = [tableView dequeueReusableCellWithIdentifier:threadedPostReuseIdentifier];
                    
                    if (cell == nil) {
                        cell = [[ThreadedPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:threadedPostReuseIdentifier];
                    }
                    
                    NSInteger identifierBefore = cell.post.identifier;
                    
                    cell.tintColor = self.tintColor;
                    [cell setThemed:true];
                    cell.post = self.stream.posts[indexPath.row];
                    
                    if (cell.post.identifier != 0 && identifierBefore == cell.post.identifier) {
                        [self didBeginDisplayingCell:cell];
                    }
                    
                    cell.postedInButton.hidden = true;
                    
                    return cell;
                }
            }
        }
        else if ([self.stream.posts[indexPath.row].type isEqualToString:@"room_suggestions"]) {
            RoomSuggestionsListCell *cell = [tableView dequeueReusableCellWithIdentifier:suggestionsCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[RoomSuggestionsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:suggestionsCellIdentifier];
            }
            
            cell.collectionView.frame = CGRectMake(0, 12, cell.frame.size.width, cell.frame.size.height - 24);
            
            return cell;
        }
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
- (CGFloat)cellHeightForExpandedPost:(Post *)post {
    // name @username • 2hr
    CGFloat avatarHeight = 48; // 2pt padding underneath
    CGFloat avatarBottomPadding = 12; //15 + 14; // 14pt padding underneath
    
    // message
    CGFloat contentWidth = self.frame.size.width;
    NSStringDrawingContext* context = [[NSStringDrawingContext alloc] init];
    CGRect textViewRect = [post.attributes.details.message boundingRectWithSize:CGSizeMake(contentWidth - 12 - 12, 1200) options:(NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:expandedTextViewFont} context:context];
    CGFloat textViewHeight = ceilf(textViewRect.size.height) + 6 + 6 + 1;
    
    // image
    BOOL hasImage = FBTweakValue(@"Post", @"General", @"Show Image", NO); // postAtIndex.images != nil && postAtIndex.images.count > 0;
    CGFloat imageHeight = hasImage ? expandedImageHeightDefault + 8 : 0;
    
    if (hasImage) {
        UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:@"https://images.unsplash.com/photo-1490349368154-73de9c9bc37c?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2250&q=80"];
        if (diskImage) {
            // disk image!
            CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
            imageHeight = roundf(contentWidth * heightToWidthRatio);
            
            if (imageHeight < 100) {
                // NSLog(@"too small muchacho");
                imageHeight = 100;
            }
            if (imageHeight > 600) {
                // NSLog(@"too big muchacho");
                imageHeight = 600;
            }
        }
        else {
            UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:@"https://images.unsplash.com/photo-1490349368154-73de9c9bc37c?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2250&q=80"];
            if (memoryImage) {
                CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
                imageHeight = roundf(contentWidth * heightToWidthRatio);
                
                if (imageHeight < 100) {
                    // NSLog(@"too small muchacho");
                    imageHeight = 100;
                }
                if (imageHeight > 600) {
                    // NSLog(@"too big muchacho");
                    imageHeight = 600;
                }
            }
        }
        imageHeight = imageHeight + 8;
    }
    
    // deatils label
    CGFloat detailHeight = 6 + 14 + 12;
    
    // actions
    CGFloat actionsHeight = expandedActionsViewHeight; // 12 = padding above actions view
    
    return expandedPostContentOffset.top + avatarHeight + avatarBottomPadding + textViewHeight + imageHeight + actionsHeight + detailHeight + expandedPostContentOffset.bottom; // 1 = line separator
}
- (CGFloat)cellHeightForPost:(Post *)post {
    if ([post.type isEqualToString:@"post"]) {
        if (post.rowHeight == 0) {
            PostDisplayType type = [self typeForPost:post];
            // TODO: temporary fix to remove top-level replies
            if (type != PostDisplayTypeThreaded && post.attributes.details.parent != 0)
                return 0;
            
            post.rowHeight = [self rowHeightForPost:post isReply:false];
            
            if (type != PostDisplayTypeSimple && post.attributes.summaries.replies.count > 0) {
                for (int i = 0; i < post.attributes.summaries.replies.count; i++) {
                    Post *reply = post.attributes.summaries.replies[i];
                    reply.rowHeight = [self rowHeightForPost:reply isReply:true];
                    
                    post.rowHeight = post.rowHeight + reply.rowHeight;
                }
            }
        }
        
        return post.rowHeight;
    }
    
    return 0;
}
- (PostDisplayType)typeForPost:(Post *)post {
    if (self.dataType == RSTableViewTypePost) {
        return PostDisplayTypeThreaded;
    }
    else if (post.attributes.summaries.replies.count > 0) {
        //return PostDisplayTypePreview;
    }
    
    return PostDisplayTypeSimple;
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
        else if (self.dataType == RSTableViewTypePost && [self.parentObject isKindOfClass:[Post class]]) {
            // prevent getting object at index beyond bounds of array
            Post *post = self.parentObject;
            
            return [self cellHeightForExpandedPost:post];
        }
    }
    else if (indexPath.section == 1) {
        // content
        if (self.stream.posts.count > indexPath.row) {
            // prevent getting object at index beyond bounds of array
            Post *postAtIndex = self.stream.posts[indexPath.row];
            
            return [self cellHeightForPost:postAtIndex];
        }
        else {
            if (self.stream.posts.count == 0 && self.dataType != RSTableViewTypePost) {
                NSInteger postType = (indexPath.row) % 3;
                
                switch (postType) {
                    case 0:
                        return 95 + 20;
                    case 1:
                        return 116 + 20;
                    case 2:
                        return 283 + 20;
                        
                    default:
                        return 95 + 20;
                        break;
                }
            }
            else {
                return 52;
            }
        }
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
    
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        // headers
        if (self.dataType == RSTableViewTypeRoom ||
            self.dataType == RSTableViewTypeProfile ||
            self.dataType == RSTableViewTypePost) {
            return 1;
        }
    }
    else if (section == 1) {
        // content
        if (self.loading && self.dataType != RSTableViewTypePost) {
            return 10;
        }
        
        return self.stream.posts.count + ((!self.reachedBottom && self.loadingMore) || self.loadingMore ? 1 : 0);
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
    }
    else if (indexPath.section == 1) {
        if (self.stream.posts.count > indexPath.row) {
            
            // prevent getting object at index beyond bounds of array
            if ([self.stream.posts[indexPath.row].type isEqualToString:@"post"] && !self.stream.posts[indexPath.row].tempId && self.stream.posts[indexPath.row].attributes.details.parent == 0) {
                Post *postAtIndex = self.stream.posts[indexPath.row];
                
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
    if ([cell isKindOfClass:[BubblePostCell class]]) {
        BubblePostCell *bubblePostCell = (BubblePostCell *)cell;
        post = bubblePostCell.post;
    } else if ([cell isKindOfClass:[ExpandedPostCell class]]) {
        ExpandedPostCell *bubblePostCell = (ExpandedPostCell *)cell;
        post = bubblePostCell.post;
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
        case RSTableViewTypePost:
            seenIn = InsightSeenInPostView;
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
        if ([cell isKindOfClass:[BubblePostCell class]]) {
            BubblePostCell *bubblePostCell = (BubblePostCell *)cell;
            post = bubblePostCell.post;
        } else if ([cell isKindOfClass:[ExpandedPostCell class]]) {
            ExpandedPostCell *bubblePostCell = (ExpandedPostCell *)cell;
            post = bubblePostCell.post;
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
        return section == 0 ? 0 : 64; // 8 = spacing underneath
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
            else if (self.dataType == RSTableViewTypePost) {
                Post *post = self.parentObject;
                NSInteger replies = (long)post.attributes.summaries.counts.replies;
                title.text = [NSString stringWithFormat:@"%ld %@", replies, (replies == 1 ? @"Reply" : @"Replies")];
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
