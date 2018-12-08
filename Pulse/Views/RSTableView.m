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
#import <JTSImageViewController/JTSImageViewController.h>

#import "PostCell.h"
#import "BubblePostCell.h"
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

@implementation RSTableView

@synthesize dataType = _dataType;  //Must do this

static NSString * const expandedPostCellIdentifier = @"ExpandedPost";
static NSString * const reuseIdentifier = @"Post";
static NSString * const bubbleReuseIdentifier = @"BubblePost";
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
    [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
    
    self.backgroundColor = [UIColor headerBackgroundColor];
}


- (void)setup {
    self.stream = [[PostStream alloc] init];
    self.loading = true;
    self.loadingMore = false;
    self.backgroundColor = [UIColor clearColor];
    self.delegate = self;
    self.dataSource = self;
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.separatorColor = [UIColor colorWithWhite:0.85f alpha:1];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self registerClass:[ExpandedPostCell class] forCellReuseIdentifier:expandedPostCellIdentifier];
    [self registerClass:[PostCell class] forCellReuseIdentifier:reuseIdentifier];
    [self registerClass:[BubblePostCell class] forCellReuseIdentifier:bubbleReuseIdentifier];
    
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
        BOOL changes = [self.stream updatePost:post];;
        
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
                [self reloadData];
            }
        }
    }
}
- (void)postDeleted:(NSNotification *)notification {
    Post *post = notification.object;
    [self.stream removePost:post];
    [self refresh];
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
            cell.tintColor = self.superview.tintColor;
            
            if (room.attributes.status.isBlocked) {
                [cell.followButton updateStatus:ROOM_STATUS_ROOM_BLOCKED];
            }
            else if (self.loading && room.attributes.context == nil) {
                [cell.followButton updateStatus:ROOM_STATUS_LOADING];
            }
            else {
                [cell.followButton updateStatus:room.attributes.context.status];
            }
            
            if (room.attributes.details.title) {
                cell.nameLabel.text = room.attributes.details.title.length > 0 ? room.attributes.details.title : @"Unkown Room";
            }
            else {
                cell.nameLabel.text = @"Loading...";
            }
            cell.descriptionLabel.text = room.attributes.details.theDescription;
            
            // set profile pictures
            UIImage *anonymousProfilePic;
            anonymousProfilePic = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            for (int i = 0; i < 7; i++) {
                UIImageView *imageView;
                if (i == 0) { imageView = cell.member1; }
                else if (i == 1) { imageView = cell.member2; }
                else if (i == 2) { imageView = cell.member3; }
                else if (i == 3) { imageView = cell.member4; }
                else if (i == 4) { imageView = cell.member5; }
                else if (i == 5) { imageView = cell.member6; }
                else { imageView = cell.member7; }
                
                if (i == 0) {
                    // TODO: Check if group image exists
                    
                    [imageView setImage:[[UIImage imageNamed:@"anonymousGroup"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                }
                else {
                    if (room.attributes.summaries.members.count > i-1) {
                        imageView.hidden = false;
                        
                        NSError *userError;
                        User *userForImageView = [[User alloc] initWithDictionary:(NSDictionary *)room.attributes.summaries.members[i-1] error:&userError];
                        
                        imageView.tintColor = [UIColor fromHex:userForImageView.attributes.details.color];
                        if (!userError) {
                            NSString *picURL = userForImageView.attributes.details.media.profilePicture;
                            if (picURL.length > 0) {
                                [imageView sd_setImageWithURL:[NSURL URLWithString:picURL]];
                            }
                            else {
                                [imageView setImage:anonymousProfilePic];
                            }
                        }
                        else {
                            [imageView setImage:anonymousProfilePic];
                        }
                    }
                    else {
                        imageView.hidden = false;
                        BOOL circleProfilePictures = FBTweakValue(@"Post", @"General", @"Circle Profile Pictures", NO);
                        if (circleProfilePictures) {
                            imageView.image = [[UIImage imageNamed:@"inviteFriendPlaceholderCircular"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                        }
                        else {
                            imageView.image = [[UIImage imageNamed:@"inviteFriendPlaceholder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                        }
                        imageView.tintColor = [UIColor colorWithWhite:0.8f alpha:1];
                    }
                }
            }
            
            DefaultsRoomMembersTitle *membersTitle = [Session sharedInstance].defaults.room.membersTitle;
            if (room.attributes.summaries.counts.members) {
                NSInteger members = room.attributes.summaries.counts.members;
                [cell.membersLabel setTitle:[NSString stringWithFormat:@"%ld %@", members, members == 1 ? [membersTitle.singular lowercaseString] : [membersTitle.plural lowercaseString]] forState:UIControlStateNormal];
                cell.membersLabel.alpha = 1;
            }
            else {
                [cell.membersLabel setTitle:[NSString stringWithFormat:@"0 %@", [membersTitle.plural lowercaseString]] forState:UIControlStateNormal];
                cell.membersLabel.alpha = 0.5;
            }
            
            if (room.attributes.summaries.counts.posts) {
                NSInteger posts = (long)room.attributes.summaries.counts.posts;
                cell.postsCountLabel.text = [NSString stringWithFormat:@"%ld %@", posts, posts == 1 ? @"post" : @"posts"];
                cell.postsCountLabel.alpha = 1;
            }
            else {
                cell.postsCountLabel.text = @"0 posts";
                cell.postsCountLabel.alpha = 0.5;
            }
            
            if (cell.membersLabel.gestureRecognizers.count == 0 &&
                ([cell.room.attributes.context.status isEqualToString:ROOM_STATUS_MEMBER] ||
                !cell.room.attributes.status.visibility.isPrivate))
            {
                [cell.membersLabel bk_whenTapped:^{
                    if ([UIViewParentController(self).navigationController isKindOfClass:[ComplexNavigationController class]]) {
                        [[Launcher sharedInstance] openRoomMembersForRoom:self.parentObject];
                    }
                }];
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
            cell.tintColor = [[user.attributes.details.color lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [UIColor fromHex:user.attributes.details.color];
            
            if ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
                [cell.followButton updateStatus:USER_STATUS_ME];
            }
            else if (self.loading && user.attributes.context == nil) {
                [cell.followButton updateStatus:USER_STATUS_LOADING];
            }
            else {
                [cell.followButton updateStatus:user.attributes.context.status];
            }
            
            if (user.attributes.details.media.profilePicture && user.attributes.details.media.profilePicture.length > 0) {
                [cell.profilePicture sd_setImageWithURL:[NSURL URLWithString:user.attributes.details.media.profilePicture] placeholderImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                cell.profilePicture.backgroundColor = [UIColor clearColor];
            }
            else {
                if (user.identifier.length > 0) {
                    cell.profilePicture.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    cell.profilePicture.backgroundColor = [UIColor clearColor];
                }
                else {
                    cell.profilePicture.image = [UIImage new];
                    cell.profilePicture.backgroundColor = [cell.tintColor colorWithAlphaComponent:0.5];
                }
            }
            
            if (user.attributes.details.displayName.length > 0) {
                cell.textLabel.text = user.attributes.details.displayName;
            }
            else if (user.attributes.details.identifier.length > 0) {
                cell.textLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
            }
            else {
                cell.textLabel.text = @"Unkown User";
            }
    
            cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier]; // short bio
            
            //if (user.attributes.summaries.counts.members) {
            NSInteger stat;
            NSString *statLabel;
            if ([cell.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
                stat = 10;
                statLabel = @"following";
            }
            else {
                stat = 10;
                statLabel = (stat == 1) ? @"room" : @"rooms";
            }
            [cell.statActionButton setTitle:[NSString stringWithFormat:@"%ld %@", (long)stat, statLabel] forState:UIControlStateNormal];
            cell.statActionButton.alpha = (stat == 0) ? 0.5 : 1;
            
            //if (user.attributes.summaries.counts.posts) {
            if (true == 1) {
                cell.postsCountLabel.text = @"{x} posts";
                cell.postsCountLabel.alpha = 1;
            }
            else {
                cell.postsCountLabel.text = @"0 posts";
                cell.postsCountLabel.alpha = 0.5;
            }
            
            return cell;
        }
        else if (self.dataType == RSTableViewTypePost && [self.parentObject isKindOfClass:[Post class]]) {
            Post *post = self.parentObject;
            
            ExpandedPostCell *cell = [tableView dequeueReusableCellWithIdentifier:expandedPostCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ExpandedPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandedPostCellIdentifier];
            }
            
            cell.loading = self.loading;
            cell.post = post;
            
            cell.nameLabel.attributedText = [self attributedCreatorStringForPost:cell.post];
            
            cell.profilePicture.tintColor = [[cell.post.attributes.details.creator.attributes.details.color lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [UIColor fromHex:cell.post.attributes.details.creator.attributes.details.color];
            if (cell.profilePicture.gestureRecognizers.count == 0) {
                [cell.profilePicture bk_whenTapped:^{
                    if ([UIViewParentController(self).navigationController isKindOfClass:[ComplexNavigationController class]]) {
                        [[Launcher sharedInstance] openProfile:post.attributes.details.creator];
                    }
                }];
            }
            
            [cell.pictureView sd_setImageWithURL:[NSURL URLWithString:@"https://images.unsplash.com/photo-1538681105587-85640961bf8b?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=03f0a1a4e6f1a7291ecb256b6a237b68&auto=format&fit=crop&w=1000&q=80"]];
            
            if ([cell.pictureView gestureRecognizers].count == 0) {
                [cell.pictureView bk_whenTapped:^{
                    [self expandImageView:cell.pictureView];
                }];
            }
            
            return cell;
        }
    }
    else {
        // Content
        if (self.stream.posts.count <= indexPath.row) {
            if (self.stream.posts.count == 0) {
                // loading cell
                LoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[LoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:loadingCellIdentifier];
                }
                
                NSInteger postType = (indexPath.row + 2) % 3;
                cell.type = postType;
                cell.shimmerContainer.shimmering = true;
                
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
            BubblePostCell *cell = [tableView dequeueReusableCellWithIdentifier:bubbleReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[BubblePostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:bubbleReuseIdentifier];
            }
            
            if (self.stream.posts.count > indexPath.row) {
                NSError *error;
                cell.post = self.stream.posts[indexPath.row];
                
                if (error) {
                    NSLog(@"cell.post error: %@", error);
                }
                
                // --- LOAD DATA ---
                cell.textView.textView.text = cell.post.attributes.details.simpleMessage;
                
                cell.nameLabel.attributedText = [self attributedCreatorStringForPost:cell.post];
                
                // set username
                NSString *username = cell.post.attributes.details.creator.attributes.details.identifier;
                cell.usernameLabel.text = [NSString stringWithFormat:@"@%@", username];
                
                if (cell.post.attributes.details.creator.attributes.details.media.profilePicture.length > 0) {
                    [cell.profilePicture sd_setImageWithURL:[NSURL URLWithString:cell.post.attributes.details.creator.attributes.details.media.profilePicture]];
                }
                else {
                    cell.profilePicture.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    cell.profilePicture.tintColor = [[cell.post.attributes.details.creator.attributes.details.color lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [UIColor fromHex:cell.post.attributes.details.creator.attributes.details.color];
                }
                
                NSString *dateString = [NSDate mysqlDatetimeFormattedAsTimeAgo:cell.post.attributes.status.createdAt withForm:TimeAgoShortForm];
                NSString *dateStringSpacer = @"   ";
                NSString *repliesString = ((long)cell.post.attributes.summaries.replies.count == 0 ? @"Reply" : [NSString stringWithFormat:@"%ld replies", (long)cell.post.attributes.summaries.replies.count]);
                
                NSString *combinedDetailString = [NSString stringWithFormat:@"%@%@%@", dateString, dateStringSpacer, repliesString];
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:combinedDetailString];
                [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13.f weight:UIFontWeightSemibold] range:NSMakeRange(dateString.length+dateStringSpacer.length, repliesString.length)];
                [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.47 alpha:1] range:NSMakeRange(0, combinedDetailString.length)];
                cell.detailsLabel.attributedText = attributedString;
                
                if (cell.profilePicture.gestureRecognizers.count == 0) {
                    [cell.profilePicture bk_whenTapped:^{
                        if ([UIViewParentController(self).navigationController isKindOfClass:[ComplexNavigationController class]]) {
                            [[Launcher sharedInstance] openProfile:cell.post.attributes.details.creator];
                        }
                    }];
                }
                
                [cell.pictureView sd_setImageWithURL:[NSURL URLWithString:@"https://images.unsplash.com/photo-1538681105587-85640961bf8b?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=03f0a1a4e6f1a7291ecb256b6a237b68&auto=format&fit=crop&w=1000&q=80"]];
                
                if ([cell.pictureView gestureRecognizers].count == 0) {
                    [cell.pictureView bk_whenTapped:^{
                        [self expandImageView:cell.pictureView];
                    }];
                }
                
                BOOL isSparked = (cell.post.attributes.context.vote != nil);
                [cell setSparked:isSparked withAnimation:false];
            }
            
            cell.selectable = self.dataType != RSTableViewTypePost;
            
            [cell.pictureView sd_setImageWithURL:[NSURL URLWithString:@"https://media.giphy.com/media/RJPQ2EF3h0bok/giphy.gif"]];
            
            return cell;
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


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // header (used in Profiles, Rooms)
        if (self.dataType == RSTableViewTypeRoom && [self.parentObject isKindOfClass:[Room class]]) {
            Room *room = self.parentObject;
            
            CGFloat topPadding = 116;
            
            CGRect textLabelRect = [(room.attributes.details.title.length > 0 ? room.attributes.details.title : @"Unkown Room") boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:32.f weight:UIFontWeightHeavy]} context:nil];
            CGFloat roomTitleHeight = ceilf(textLabelRect.size.height);
            
            CGRect detailTextLabelRect = [room.attributes.details.theDescription boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16.f weight:UIFontWeightRegular]} context:nil];
            CGFloat roomDescriptionHeight = ceilf(room.attributes.details.theDescription.length) > 0 ? ceilf(detailTextLabelRect.size.height) + 4 : 0; // 2 = padding between title and description
            
            CGFloat roomPrimaryActionHeight = 40 + 14; // 14 = spacing between primary action and closest label (title or desciprtion)
            
            CGFloat statsViewHeight = 48 + (1 / [UIScreen mainScreen].scale); // 16 = height above
            
            return topPadding + roomTitleHeight + roomDescriptionHeight + roomPrimaryActionHeight + statsViewHeight; // 8 = section separator
        }
        else if (self.dataType == RSTableViewTypeProfile && [self.parentObject isKindOfClass:[User class]]) {
            User *user = self.parentObject;
            
            CGFloat topPadding = 116;

            CGRect textLabelRect = [(user.attributes.details.displayName.length > 0 ? user.attributes.details.displayName : @"User") boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:32.f weight:UIFontWeightHeavy]} context:nil];
            CGFloat userDisplayNameHeight = textLabelRect.size.height; // 18 padding underneath title+description
            
            CGRect usernameRect = [[NSString stringWithFormat:@"@%@", user.attributes.details.identifier] boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16.f weight:UIFontWeightMedium]} context:nil];
            CGFloat usernameHeight = usernameRect.size.height + 2; // 2 = padding between title and description
            
            CGFloat userPrimaryActionHeight = (user.identifier.length > 0 ? 40 : 0) + 14;
            
            CGFloat statsViewHeight = (user.identifier.length > 0) ? 48 + (1 / [UIScreen mainScreen].scale) : 0; // 16 = height above
            
            return topPadding + userDisplayNameHeight + usernameHeight + userPrimaryActionHeight + statsViewHeight;
        }
        else if (self.dataType == RSTableViewTypePost && [self.parentObject isKindOfClass:[Post class]]) {
            // prevent getting object at index beyond bounds of array
            Post *post = self.parentObject;
            
            // TODO: calculate height of namelabel in heightForRowAtIndexPath
            
            // name @username • 2hr
            CGFloat nameHeight = 16 + 2; // 2pt padding underneath
            CGFloat dateHeight = 15 + 14; //15 + 14; // 14pt padding underneath
            
            // message
            CGFloat contentWidth = self.frame.size.width - expandedPostContentOffset.left - 24;
            NSStringDrawingContext* context = [[NSStringDrawingContext alloc] init];
            CGRect textViewRect = [post.attributes.details.simpleMessage boundingRectWithSize:CGSizeMake(contentWidth - 12 - 12, 1200) options:(NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:expandedTextViewFont} context:context];
            CGFloat textViewHeight = ceilf(textViewRect.size.height) + 6 + 6;
            NSLog(@"textViewHeight: %f", textViewHeight);
            
            // image
            BOOL hasImage = FBTweakValue(@"Post", @"General", @"Show Image", NO); // postAtIndex.images != nil && postAtIndex.images.count > 0;
            CGFloat imageHeight = hasImage ? expandedImageHeightDefault + 10 : 0;
            
            if (hasImage) {
                UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:@"https://images.unsplash.com/photo-1538681105587-85640961bf8b?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=03f0a1a4e6f1a7291ecb256b6a237b68&auto=format&fit=crop&w=1000&q=80"];
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
                    imageHeight = imageHeight + 10;
                }
                else {
                    UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:@"https://images.unsplash.com/photo-1538681105587-85640961bf8b?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=03f0a1a4e6f1a7291ecb256b6a237b68&auto=format&fit=crop&w=1000&q=80"];
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
                        imageHeight = imageHeight + 10;
                    }
                }
            }
            
            // actions
            CGFloat actionsHeight = expandedActionsViewHeight + 10; // 10 = padding above actions view
            
            /* deatil button
            CGFloat detailHeight = (self.dataType != RSTableViewTypeRoom ? 16 + 8 : 0); // 4pt padding on top*/

            return expandedPostContentOffset.top + nameHeight + dateHeight + textViewHeight + imageHeight + actionsHeight + expandedPostContentOffset.bottom + (1 / [UIScreen mainScreen].scale); // 1 = line separator
        }
    }
    else if (indexPath.section == 1) {
        // content
        if (self.stream.posts.count > indexPath.row) {
            // prevent getting object at index beyond bounds of array
            Post *postAtIndex = self.stream.posts[indexPath.row];
            
            if ([postAtIndex.type isEqualToString:@"post"]) {
                // TODO: calculate height of namelabel in heightForRowAtIndexPath
                
                // name @username • 2hr
                CGFloat nameHeight = 16 + 4; // + 2; // 2pt padding underneath
                CGFloat usernameHeight = 0; //15 + 6; // 8pt padding underneath
                
                // message
                CGRect textViewRect = [postAtIndex.attributes.details.simpleMessage boundingRectWithSize:CGSizeMake(self.frame.size.width - postContentOffset.left - postTextViewInset.left - postTextViewInset.right - 24, 1200) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:textViewFont} context:nil];
                CGFloat textViewHeight = ceilf(textViewRect.size.height) + (postTextViewInset.top + postTextViewInset.bottom);
                
                // image
                BOOL hasImage = FBTweakValue(@"Post", @"General", @"Show Image", NO); // postAtIndex.images != nil && postAtIndex.images.count > 0;
                CGFloat imageHeight = hasImage ? [Session sharedInstance].defaults.post.imgHeight + 4 + 4 : 0; // 4 on top and 4 on bottom
                BOOL hasURLPreview = [postAtIndex requiresURLPreview];
                CGFloat urlPreviewHeight = !hasImage && hasURLPreview ? [Session sharedInstance].defaults.post.imgHeight + 4 + 4 : 0; // 4 on top and 4 on bottom
                
                // actions
                CGFloat actionsHeight = (hasImage ? 8 : 4) + 16; // 4 = padding between content and actions bar
                
                CGFloat postHeight = postContentOffset.top + nameHeight + usernameHeight + textViewHeight + imageHeight + urlPreviewHeight + actionsHeight + postContentOffset.bottom;
                
                return postHeight;
            }
        }
        else {
            if (self.stream.posts.count == 0) {
                NSInteger postType = (indexPath.row + 2) % 3;
                
                switch (postType) {
                    case 0:
                        return 95;
                    case 1:
                        return 116;
                    case 2:
                        return 283;
                        
                    default:
                        return 95;
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
        if (self.loading) {
            self.scrollEnabled = false;
        }
        else {
            self.scrollEnabled = true;
        }
        
        return self.loading ? 10 : self.stream.posts.count + ([self morePosts] || self.loadingMore ? 1 : 0);
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
    }
    else if (indexPath.section == 1 && self.dataType != RSTableViewTypePost) {
        if (self.stream.posts.count > indexPath.row) {
            // prevent getting object at index beyond bounds of array
            if ([self.stream.posts[indexPath.row].type isEqualToString:@"post"]) {
                Post *postAtIndex = self.stream.posts[indexPath.row];
                
                [[Launcher sharedInstance] openPost:postAtIndex];
            }
        }
    }
}
//@property (nonatomic) NSInteger lastSinceId;
- (BOOL)morePosts {
    if (self.stream.posts.count > 0) {
        Post *lastPost = self.stream.posts[self.stream.posts.count-1];
        NSLog(@"lastPost.identifier: %ld", (long)lastPost.identifier);
        NSLog(@"self.lastMaxId: %ld", (long)self.lastMaxId);
        if (lastPost.identifier != self.lastMaxId) {
            return true;
        }
    }
    
    return false;
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1 &&
       indexPath.row == self.stream.posts.count &&
       [self morePosts]) {
        if(indexPath.section == 1 && indexPath.row == self.stream.posts.count) {
            Post *lastPost = [self.stream.posts lastObject];
            self.lastMaxId = (NSInteger)lastPost.identifier;
            self.loadingMore = true;
            
            PaginationCell *paginationCell = (PaginationCell *)cell;
            if (!paginationCell.loading) {
                paginationCell.loading = true;
                paginationCell.spinner.hidden = false;
                [paginationCell.spinner startAnimating];
            }
            
            [self.paginationDelegate tableView:self didRequestNextPageWithMaxId:self.lastMaxId];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.dataType == RSTableViewTypeProfile ||
        self.dataType == RSTableViewTypePost ||
        self.dataType == RSTableViewTypeRoom) {
        return section == 0 ? 0 : 64; // 8 = spacing underneath
    }
    return 0;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        if ((self.loading || (!self.loading && self.stream.posts.count > 0)) &&
            (self.dataType == RSTableViewTypeProfile ||
            self.dataType == RSTableViewTypePost ||
            self.dataType == RSTableViewTypeRoom)) {
            UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 64)];
            
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 64)];
            [headerContainer addSubview:header];
                
            header.backgroundColor = [UIColor headerBackgroundColor];
            
            UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(21, 28, 24, 24)];
            icon.image = [[UIImage imageNamed:@"repliesIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            icon.contentMode = UIViewContentModeScaleAspectFit;
            icon.tintColor = [UIColor colorWithWhite:0.6f alpha:1];
            icon.layer.cornerRadius = icon.frame.size.height / 2;
            [header addSubview:icon];
            
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(66, icon.frame.origin.y, self.frame.size.width - 66 - 200, icon.frame.size.height)];
            if (self.dataType == RSTableViewTypeRoom) {
                title.text = @"Posts";
                
                if ([self.parentObject isKindOfClass:[Room class]]) {
                    Room *room = self.parentObject;
                    
                    UILabel *liveCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 200 - postContentOffset.right, title.frame.origin.y, 200, title.frame.size.height)];
                    liveCountLabel.text = [NSString stringWithFormat:@"%ld live", (long)room.attributes.summaries.counts.live];
                    liveCountLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
                    liveCountLabel.textColor = [UIColor colorWithDisplayP3Red:0.87 green:0.09 blue:0.09 alpha:1];
                    liveCountLabel.textAlignment = NSTextAlignmentRight;
                    [header addSubview:liveCountLabel];
                    
                    CGRect liveCountRect = [liveCountLabel.text boundingRectWithSize:CGSizeMake(liveCountLabel.frame.size.width, liveCountLabel.frame.size.height) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:liveCountLabel.font} context:nil];
                    
                    UIView *liveCountPulse = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - postContentOffset.right - liveCountRect.size.width - 10 - 6, liveCountLabel.frame.origin.y + (liveCountLabel.frame.size.height / 2) - 4.5, 9, 9)];
                    liveCountPulse.layer.cornerRadius = liveCountPulse.frame.size.height / 2;
                    liveCountPulse.layer.masksToBounds = true;
                    liveCountPulse.backgroundColor = liveCountLabel.textColor;
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
                title.text = [NSString stringWithFormat:@"%ld Replies", (long)post.attributes.summaries.counts.replies];
            }
            else {
                title.text = @"Posts";
            }
            title.textAlignment = NSTextAlignmentLeft;
            title.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
            title.textColor = [UIColor colorWithWhite:0.6f alpha:1];
            
            [header addSubview:title];
                
            UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, 1 / [UIScreen mainScreen].scale)];
            lineSeparator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
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

- (void)expandImageView:(UIImageView *)imageView {
    // Create image info
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
    imageInfo.image = imageView.image;
    imageInfo.referenceRect = imageView.frame;
    imageInfo.referenceView = imageView.superview;
    
    // Setup view controller
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                           initWithImageInfo:imageInfo
                                           mode:JTSImageViewControllerMode_Image
                                           backgroundStyle:JTSImageViewControllerBackgroundOption_None];
    UILongPressGestureRecognizer *longPressToSave = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        UIAlertController *shareOptions = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIImageWriteToSavedPhotosAlbum(imageViewer.image, nil, nil, nil);
        }];
        UIAlertAction *shareViaAction = [UIAlertAction actionWithTitle:@"Share via..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [shareOptions dismissViewControllerAnimated:YES completion:nil];
            
            //create a message
            NSArray *items = @[imageViewer.image];
            
            // build an activity view controller
            UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
            
            // and present it
            controller.modalPresentationStyle = UIModalPresentationPopover;
            [imageViewer presentViewController:controller animated:YES completion:nil];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [shareOptions addAction:saveAction];
        [shareOptions addAction:shareViaAction];
        [shareOptions addAction:cancelAction];
        [imageViewer presentViewController:shareOptions animated:YES completion:nil];
    }];
    [imageViewer.view addGestureRecognizer:longPressToSave];
    
    
    // Present the view controller.
    [imageViewer showFromViewController:UIViewParentController(self) transition:JTSImageViewControllerTransition_FromOriginalPosition];
}

- (NSAttributedString *)attributedCreatorStringForPost:(Post *)post {
    // set display name + room name combo
    NSString *displayName = post.attributes.details.creator.attributes.details.displayName != nil ? post.attributes.details.creator.attributes.details.displayName : @"Anonymous";
    
    Room *postedInRoom = post.attributes.status.postedIn;
    NSString *currentRoomIdentifier = @"";
    if ([UIViewParentController(self) isKindOfClass:[RoomViewController class]]) {
        currentRoomIdentifier = ((Room *)self.parentObject).identifier;
    }
    
    UIFont *font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    UIColor *color = [UIColor colorWithWhite:0.27f alpha:1];
    
    NSMutableAttributedString *creatorString = [[NSMutableAttributedString alloc] initWithString:displayName];
    [creatorString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, creatorString.length)];
    [creatorString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, creatorString.length)];
    
    if (postedInRoom != nil && ![postedInRoom.identifier isEqualToString:currentRoomIdentifier]) {
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@"  "];
        [spacer addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, spacer.length)];
        [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
        [creatorString appendAttributedString:spacer];
        
        // right arrow ▸
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"postedInTriangleIcon"];
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [creatorString appendAttributedString:attachmentString];
        
        // add another spacer
        [creatorString appendAttributedString:spacer];
        
        NSString *roomTitle = post.attributes.status.postedIn.attributes.details.title;
        NSMutableAttributedString *roomString = [[NSMutableAttributedString alloc] initWithString:roomTitle];
        [roomString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, roomString.length)];
        [roomString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, roomString.length)];
        [creatorString appendAttributedString:roomString];
    }
    
    return creatorString;
}

@end
