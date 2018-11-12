//
//  RSTableView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/4/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RSTableView.h"
#import "LauncherNavigationViewController.h"
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
- (void)setDataType:(int)dataType {
    if (_dataType != dataType) {
        _dataType = dataType;
        [self refresh];
    }
}
    
//Getter method
- (int)dataType {
    return _dataType;
}

- (void)refresh {
    [self reloadData];
    
    if (!self.loading && !self.loadingMore && self.data.count == 0 && self.dataType != tableCategoryFeed) {
        self.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    }
    else {
        self.backgroundColor = [UIColor whiteColor];
    }
}


- (void)setup {
    self.loading = true;
    self.loadingMore = false;
    self.backgroundColor = [UIColor clearColor];
    self.delegate = self;
    self.dataSource = self;
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.separatorColor = [UIColor colorWithWhite:0.85f alpha:1];
    
    [self registerClass:[ExpandedPostCell class] forCellReuseIdentifier:expandedPostCellIdentifier];
    [self registerClass:[PostCell class] forCellReuseIdentifier:reuseIdentifier];
    [self registerClass:[BubblePostCell class] forCellReuseIdentifier:bubbleReuseIdentifier];
    
    [self registerClass:[RoomHeaderCell class] forCellReuseIdentifier:roomHeaderCellIdentifier];
    [self registerClass:[ProfileHeaderCell class] forCellReuseIdentifier:profileHeaderCellIdentifier];
    [self registerClass:[RoomSuggestionsListCell class] forCellReuseIdentifier:suggestionsCellIdentifier];
    [self registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    
    [self registerClass:[LoadingCell class] forCellReuseIdentifier:loadingCellIdentifier];
    [self registerClass:[PaginationCell class] forCellReuseIdentifier:paginationCellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUpdated:) name:@"postUpdated" object:nil];
}

- (void)postUpdated:(NSNotification *)notification {
    Post *post = notification.object;
    
    NSLog(@"post that's updated: %@", post);
    
    if (post != nil) {
        // new post appears valid
        BOOL changes = false;
        
        // check self.data
        for (int i = 0; i < self.data.count; i++) {
            NSError *error;
            Post *p = [[Post alloc] initWithDictionary:self.data[i] error:&error];
            if (!error) {
                // object at index is a post
                if (p.identifier == post.identifier) {
                    // same post
                    changes = true;
                    [self.data replaceObjectAtIndex:i withObject:[post toDictionary]];
                }
            }
        }
        
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
            NSLog(@"💫 changes made");
            
            NSLog(@"parent controller: %@", UIViewParentController(self));
            if (![UIViewParentController(self).navigationController.topViewController isKindOfClass:[UIViewParentController(self) class]]) {
                [self reloadData];
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && self.parentObject) {
        // Header (used in Profiles, Rooms, Post Details)
        if (self.dataType == tableCategoryRoom && [self.parentObject isKindOfClass:[Room class]]) {
            Room *room = self.parentObject;
            
            RoomHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:roomHeaderCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[RoomHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:roomHeaderCellIdentifier];
            }
            cell.room = room;
            cell.tintColor = self.superview.tintColor;
            
            if (room.attributes.status.isBlocked) {
                [cell.followButton updateStatus:STATUS_ROOM_BLOCKED];
            }
            else {
                [cell.followButton updateStatus:room.attributes.context.status];
            }
            
            cell.nameLabel.text = room.attributes.details.title > 0 ? room.attributes.details.title : @"Unkown Room";
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
                    if (room.attributes.summaries.members.count > i) {
                        imageView.hidden = false;
                        
                        NSError *userError;
                        User *userForImageView = [[User alloc] initWithDictionary:(NSDictionary *)room.attributes.summaries.members[i] error:&userError];
                        
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
                        imageView.image = [[UIImage imageNamed:@"inviteFriendPlaceholder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                        imageView.tintColor = [UIColor colorWithWhite:0.8f alpha:1];
                    }
                }
            }
            
            NSInteger members = room.attributes.summaries.counts.members;
            DefaultsRoomMembersTitle *membersTitle = [Session sharedInstance].defaults.room.membersTitle;
            [cell.membersLabel setTitle:[NSString stringWithFormat:@"%ld %@", members, members == 1 ? [membersTitle.singular lowercaseString] : [membersTitle.plural lowercaseString]] forState:UIControlStateNormal];
            
            NSInteger posts = (long)room.attributes.summaries.counts.posts;
            cell.postsCountLabel.text = [NSString stringWithFormat:@"%ld %@", posts, posts == 1 ? @"post" : @"posts"];
            
            if (cell.membersLabel.gestureRecognizers.count == 0) {
                [cell.membersLabel bk_whenTapped:^{
                    if ([UIViewParentController(self).navigationController isKindOfClass:[LauncherNavigationViewController class]]) {
                        [(LauncherNavigationViewController *)UIViewParentController(self).navigationController  openRoomMembersForRoom:room];
                    }
                }];
            }
            
            return cell;
        }
        else if (self.dataType == tableCategoryProfile && [self.parentObject isKindOfClass:[User class]]) {
            User *user = self.parentObject;
            
            ProfileHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:profileHeaderCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ProfileHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:profileHeaderCellIdentifier];
            }
            
            cell.user = user;
            cell.tintColor = [[user.attributes.details.color lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [self colorFromHexString:user.attributes.details.color];
            
            if (user.attributes.details.media.profilePicture && user.attributes.details.media.profilePicture.length > 0) {
                [cell.profilePicture sd_setImageWithURL:[NSURL URLWithString:user.attributes.details.media.profilePicture] placeholderImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            }
            else {
                cell.profilePicture.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            
            cell.textLabel.text = user.attributes.details.displayName > 0 ? user.attributes.details.displayName : @"User";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier]; // short bio
            
            NSLog(@"profile user.identifier: %@", user.identifier);
            if ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
                [cell.followButton setTitle:@"Edit Profile" forState:UIControlStateNormal];
                if (cell.followButton.gestureRecognizers.count == 0) {
                    [cell.followButton bk_whenTapped:^{
                        NSLog(@"edit profile");
                        if ([UIViewParentController(self).navigationController isKindOfClass:[LauncherNavigationViewController class]]) {
                            [(LauncherNavigationViewController *)UIViewParentController(self).navigationController openEditProfile];
                        }
                    }];
                }
            }
            else {
                [cell.followButton setImage:[[UIImage imageNamed:@"plusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                [cell.followButton setTitle:[Session sharedInstance].defaults.profile.followVerb forState:UIControlStateNormal];
                if (cell.followButton.gestureRecognizers.count == 0) {
                    [cell.followButton bk_whenTapped:^{
                        /*cell.followButton.active = !cell.followButton.active;
                        
                        [cell pushFollowState];
                        [cell updateFollowState];*/
                    }];
                }
            }
            
            return cell;
        }
        else if (self.dataType == tableCategoryPost && [self.parentObject isKindOfClass:[Post class]]) {
            Post *post = self.parentObject;
            
            ExpandedPostCell *cell = [tableView dequeueReusableCellWithIdentifier:expandedPostCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ExpandedPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandedPostCellIdentifier];
            }
            
            cell.loading = self.loading;
            cell.post = post;
            
            cell.profilePicture.tintColor = [[cell.post.attributes.details.creator.attributes.details.color lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [self colorFromHexString:cell.post.attributes.details.creator.attributes.details.color];
            if (cell.profilePicture.gestureRecognizers.count == 0) {
                [cell.profilePicture bk_whenTapped:^{
                    if ([UIViewParentController(self).navigationController isKindOfClass:[LauncherNavigationViewController class]]) {
                        NSLog(@"open profile");
                        [(LauncherNavigationViewController *)UIViewParentController(self).navigationController  openProfile:post.attributes.details.creator];
                    }
                }];
            }
            
            cell.postDetailsButton.hidden = false;
            if (cell.postDetailsButton.gestureRecognizers.count == 0) {
                [cell.postDetailsButton bk_whenTapped:^{
                    if ([UIViewParentController(self).navigationController isKindOfClass:[LauncherNavigationViewController class]]) {
                        if ([self.parentObject isKindOfClass:[Room class]]) {
                            Room *room = self.parentObject;
                            
                            [(LauncherNavigationViewController *)UIViewParentController(self).navigationController  openRoom:room];
                        }
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
        if (self.data.count <= indexPath.row) {
            if (self.data.count == 0) {
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
                
                cell.loading = true;
                cell.spinner.hidden = false;
                [cell.spinner startAnimating];
                
                cell.userInteractionEnabled = false;
                
                return cell;
            }
        }
        else if ([self.data[indexPath.row][@"type"] isEqualToString:@"post"]) {
            BubblePostCell *cell = [tableView dequeueReusableCellWithIdentifier:bubbleReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[BubblePostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:bubbleReuseIdentifier];
            }
            
            if (self.data.count > indexPath.row) {
                NSError *error;
                cell.post = [[Post alloc] initWithDictionary:self.data[indexPath.row] error:&error];
                
                if (error) {
                    NSLog(@"cell.post error: %@", error);
                }
                
                // --- LOAD DATA ---
                cell.textView.textView.text = cell.post.attributes.details.simpleMessage;
                NSString *displayName = cell.post.attributes.details.creator.attributes.details.displayName != nil ? cell.post.attributes.details.creator.attributes.details.displayName : @"Anonymous";
                NSString *username = cell.post.attributes.details.creator.attributes.details.identifier;
                NSString *greyText = [NSString stringWithFormat:@"@%@", username];
                
                NSMutableAttributedString *combinedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", displayName, greyText]];
                [combinedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.2f alpha:1] range:NSMakeRange(0, displayName.length)];
                [combinedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.f weight:UIFontWeightBold] range:NSMakeRange(0, displayName.length)];
                [combinedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.6f alpha:1] range:NSMakeRange(displayName.length + 1, greyText.length)];
                [combinedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.f weight:UIFontWeightRegular] range:NSMakeRange(displayName.length + 1, greyText.length)];
                
                cell.nameLabel.attributedText = combinedString;
                if (cell.post.attributes.details.creator.attributes.details.media.profilePicture.length > 0) {
                    [cell.profilePicture sd_setImageWithURL:[NSURL URLWithString:cell.post.attributes.details.creator.attributes.details.media.profilePicture]];
                }
                else {
                    cell.profilePicture.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    cell.profilePicture.tintColor = [[cell.post.attributes.details.creator.attributes.details.color lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [self colorFromHexString:cell.post.attributes.details.creator.attributes.details.color];
                }
                //[self.actionsView.commentsButton setTitle:[NSString stringWithFormat:@"%ld", (long)self.post.attributes.summaries.counts.comments] forState:UIControlStateNormal];
                
                Room *postRoom = cell.post.attributes.status.postedIn;
                Room *parentRoom = self.parentObject;
                if (self.dataType == tableCategoryRoom && self.parentObject && [postRoom.identifier isEqualToString:parentRoom.identifier]) {
                    // boom match
                    [cell.postDetailsButton setTitle:[NSString stringWithFormat:@"%@", ((long)cell.post.attributes.summaries.replies.count == 0 ? @"Reply" : [NSString stringWithFormat:@"%ld replies", (long)cell.post.attributes.summaries.replies.count])] forState:UIControlStateNormal];
                }
                else {
                    [cell.postDetailsButton setTitle:[NSString stringWithFormat:@"%@ · %@", cell.post.attributes.status.postedIn.attributes.details.title, ((long)cell.post.attributes.summaries.replies.count == 0 ? @"Reply" : [NSString stringWithFormat:@"%ld replies", (long)cell.post.attributes.summaries.replies.count])] forState:UIControlStateNormal];
                }
                
                cell.dateLabel.text = [NSDate mysqlDatetimeFormattedAsTimeAgo:cell.post.attributes.status.createdAt];
                
                if (cell.profilePicture.gestureRecognizers.count == 0) {
                    [cell.profilePicture bk_whenTapped:^{
                        NSLog(@"load profile");
                        
                        NSLog(@"self.parentcontroller: %@", UIViewParentController(self));
                        NSLog(@"nva controller: %@", UIViewParentController(self).navigationController);
                        if ([UIViewParentController(self).navigationController isKindOfClass:[LauncherNavigationViewController class]]) {
                            [(LauncherNavigationViewController *)UIViewParentController(self).navigationController  openProfile:cell.post.attributes.details.creator];
                        }
                    }];
                    
                    if (self.dataType != tableCategoryPost && cell.postDetailsButton.gestureRecognizers.count == 0) {
                        [cell.postDetailsButton bk_whenTapped:^{
                            if ([UIViewParentController(self).navigationController isKindOfClass:[LauncherNavigationViewController class]]) {
                                if ([self.parentObject isKindOfClass:[Room class]]) {
                                    Room *room = self.parentObject;
                                    
                                    [(LauncherNavigationViewController *)UIViewParentController(self).navigationController  openRoom:room];
                                }
                            }
                        }];
                    }
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
            
            if (self.dataType == tableCategoryPost) {
                cell.postDetailsButton.hidden = true;
            }
            else {
                cell.postDetailsButton.hidden = false;
            }
            
            cell.selectable = self.dataType != tableCategoryPost;
            
            return cell;
            
            
            /*
             
            PostCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[PostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
            }
            
            if (self.data.count > indexPath.row) {
                NSError *error;
                cell.post = [[Post alloc] initWithDictionary:self.data[indexPath.row] error:&error];
                
                if (error) {
                    NSLog(@"cell.post error: %@", error);
                }
                
                // --- LOAD DATA ---
                cell.textView.textView.text = cell.post.attributes.details.message;
                NSString *displayName = cell.post.attributes.details.creator.attributes.details.displayName != nil ? cell.post.attributes.details.creator.attributes.details.displayName : @"Anonymous";
                NSString *username = cell.post.attributes.details.creator.attributes.details.identifier;
                NSString *greyText = [NSString stringWithFormat:@"@%@", username];
                
                NSMutableAttributedString *combinedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", displayName, greyText]];
                [combinedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.2f alpha:1] range:NSMakeRange(0, displayName.length)];
                [combinedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.f weight:UIFontWeightBold] range:NSMakeRange(0, displayName.length)];
                [combinedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.6f alpha:1] range:NSMakeRange(displayName.length + 1, greyText.length)];
                [combinedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.f weight:UIFontWeightRegular] range:NSMakeRange(displayName.length + 1, greyText.length)];
                
                cell.nameLabel.attributedText = combinedString;
                if (cell.post.attributes.details.creator.attributes.details.media.profilePicture.length > 0) {
                    [cell.profilePicture sd_setImageWithURL:[NSURL URLWithString:cell.post.attributes.details.creator.attributes.details.media.profilePicture]];
                }
                else {
                    cell.profilePicture.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    cell.profilePicture.tintColor = [[cell.post.attributes.details.creator.attributes.details.color lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [self colorFromHexString:cell.post.attributes.details.creator.attributes.details.color];
                }
                //[self.actionsView.commentsButton setTitle:[NSString stringWithFormat:@"%ld", (long)self.post.attributes.summaries.counts.comments] forState:UIControlStateNormal];
                
                Room *postRoom = cell.post.attributes.status.postedIn;
                Room *parentRoom = self.parentObject;
                if (self.dataType == tableCategoryRoom && self.parentObject && [postRoom.identifier isEqualToString:parentRoom.identifier]) {
                    // boom match
                    [cell.postDetailsButton setTitle:[NSString stringWithFormat:@"%@", ((long)cell.post.attributes.summaries.replies.count == 0 ? @"Reply" : [NSString stringWithFormat:@"%ld replies", (long)cell.post.attributes.summaries.replies.count])] forState:UIControlStateNormal];
                }
                else {
                    [cell.postDetailsButton setTitle:[NSString stringWithFormat:@"%@ · %@", cell.post.attributes.status.postedIn.attributes.details.title, ((long)cell.post.attributes.summaries.replies.count == 0 ? @"Reply" : [NSString stringWithFormat:@"%ld replies", (long)cell.post.attributes.summaries.replies.count])] forState:UIControlStateNormal];
                }
                
                cell.dateLabel.text = [NSDate mysqlDatetimeFormattedAsTimeAgo:cell.post.attributes.status.createdAt];
                
                if (cell.profilePicture.gestureRecognizers.count == 0) {
                    [cell.profilePicture bk_whenTapped:^{
                        NSLog(@"load profile");
                        
                        NSLog(@"self.parentcontroller: %@", UIViewParentController(self));
                        NSLog(@"nva controller: %@", UIViewParentController(self).navigationController);
                        if ([UIViewParentController(self).navigationController isKindOfClass:[LauncherNavigationViewController class]]) {
                            [(LauncherNavigationViewController *)UIViewParentController(self).navigationController  openProfile:cell.post.attributes.details.creator];
                        }
                    }];
                    
                    if (self.dataType != tableCategoryPost && cell.postDetailsButton.gestureRecognizers.count == 0) {
                        [cell.postDetailsButton bk_whenTapped:^{
                            if ([UIViewParentController(self).navigationController isKindOfClass:[LauncherNavigationViewController class]]) {
                                if ([self.parentObject isKindOfClass:[Room class]]) {
                                    Room *room = self.parentObject;
                                    
                                    [(LauncherNavigationViewController *)UIViewParentController(self).navigationController  openRoom:room];
                                }
                            }
                        }];
                    }
                }
                
                [cell.pictureView sd_setImageWithURL:[NSURL URLWithString:@"https://images.unsplash.com/photo-1538681105587-85640961bf8b?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=03f0a1a4e6f1a7291ecb256b6a237b68&auto=format&fit=crop&w=1000&q=80"]];
                
                [cell setSparked:false withAnimation:false];
                
                if ([cell.pictureView gestureRecognizers].count == 0) {
                    [cell.pictureView bk_whenTapped:^{
                        [self expandImageView:cell.pictureView];
                    }];
                }
            }
            
            if (self.dataType == tableCategoryPost) {
                cell.postDetailsButton.hidden = true;
            }
            else {
                cell.postDetailsButton.hidden = false;
            }
            
            cell.selectable = self.dataType != tableCategoryPost;
            
            return cell;*/
        }
        else if ([self.data[indexPath.row][@"type"] isEqualToString:@"room_suggestions"]) {
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
        if (self.dataType == tableCategoryRoom && [self.parentObject isKindOfClass:[Room class]]) {
            Room *room = self.parentObject;
            
            CGFloat topPadding = 116;
            
            CGRect textLabelRect = [(room.attributes.details.title.length > 0 ? room.attributes.details.title : @"Unkown Room") boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:34.f weight:UIFontWeightHeavy]} context:nil];
            CGFloat roomTitleHeight = ceilf(textLabelRect.size.height);
            
            CGRect detailTextLabelRect = [room.attributes.details.theDescription boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16.f weight:UIFontWeightRegular]} context:nil];
            CGFloat roomDescriptionHeight = ceilf(room.attributes.details.theDescription.length) > 0 ? ceilf(detailTextLabelRect.size.height) + 4 : 0; // 2 = padding between title and description
            
            CGFloat roomPrimaryActionHeight = 40 + 14; // 14 = spacing between primary action and closest label (title or desciprtion)
            
            CGFloat statsViewHeight = 48 + (1 / [UIScreen mainScreen].scale); // 16 = height above
            
            return topPadding + roomTitleHeight + roomDescriptionHeight + roomPrimaryActionHeight + statsViewHeight; // 8 = section separator
        }
        else if (self.dataType == tableCategoryProfile && [self.parentObject isKindOfClass:[User class]]) {
            User *user = self.parentObject;
            
            CGFloat topPadding = 24;
            CGFloat profilePictureHeight = 72;
            CGRect textLabelRect = [(user.attributes.details.displayName.length > 0 ? user.attributes.details.displayName : @"User") boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:28.f weight:UIFontWeightHeavy]} context:nil];
            CGFloat userDisplayNameHeight = textLabelRect.size.height; // 18 padding underneath title+description
            
            CGRect usernameRect = [[NSString stringWithFormat:@"@%@", user.attributes.details.identifier] boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16.f weight:UIFontWeightRegular]} context:nil];
            CGFloat usernameHeight = user.identifier.length > 0 ? usernameRect.size.height + 2 : 0; // 2 = padding between title and description
            
            CGFloat userPrimaryActionHeight = 48;
            
            return topPadding + profilePictureHeight + 12 + userDisplayNameHeight + usernameHeight + 18 + userPrimaryActionHeight + 8 + (1 / [UIScreen mainScreen].scale);
        }
        else if (self.dataType == tableCategoryPost && [self.parentObject isKindOfClass:[Post class]]) {
            // prevent getting object at index beyond bounds of array
            NSError *error;
            Post *post = self.parentObject;
            NSLog(@"error: %@", error.userInfo);
            
            // message
            CGFloat contentWidth = self.frame.size.width - expandedPostContentOffset.left - expandedPostContentOffset.right;
            CGRect textViewRect = [post.attributes.details.message boundingRectWithSize:CGSizeMake(contentWidth - 24, 1200) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:expandedTextViewFont} context:nil];
            CGFloat textViewHeight = roundf(textViewRect.size.height);
            
            // image
            BOOL hasImage = false; // postAtIndex.images != nil && postAtIndex.images.count > 0;
            CGFloat imageHeight = hasImage ? expandedImageHeightDefault + 10 : 0;
            
            if (hasImage) {
                UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:@"https://images.unsplash.com/photo-1538681105587-85640961bf8b?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=03f0a1a4e6f1a7291ecb256b6a237b68&auto=format&fit=crop&w=1000&q=80"];
                if (diskImage) {
                    // disk image!
                    NSLog(@"disk image!");
                    CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
                    imageHeight = roundf(contentWidth * heightToWidthRatio);
                    
                    if (imageHeight < 100) {
                        NSLog(@"too small muchacho");
                        imageHeight = 100;
                    }
                    if (imageHeight > 600) {
                        NSLog(@"too big muchacho");
                        imageHeight = 600;
                    }
                    imageHeight = imageHeight + 10;
                }
                else {
                    UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:@"https://images.unsplash.com/photo-1538681105587-85640961bf8b?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=03f0a1a4e6f1a7291ecb256b6a237b68&auto=format&fit=crop&w=1000&q=80"];
                    if (memoryImage) {
                        NSLog(@"memory image!");
                        CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
                        imageHeight = roundf(contentWidth * heightToWidthRatio);
                        
                        if (imageHeight < 100) {
                            NSLog(@"too small muchacho");
                            imageHeight = 100;
                        }
                        if (imageHeight > 600) {
                            NSLog(@"too big muchacho");
                            imageHeight = 600;
                        }
                        imageHeight = imageHeight + 10;
                    }
                }
            }
            
            // actions
            CGFloat actionsHeight = expandedActionsViewHeight + 10; // 10 = padding above actions view
            
            /* deatil button
            CGFloat detailHeight = (self.dataType != tableCategoryRoom ? 16 + 8 : 0); // 4pt padding on top*/

            return expandedTextViewYPos + (textViewHeight+12) + imageHeight + actionsHeight + expandedPostContentOffset.bottom + (1 / [UIScreen mainScreen].scale); // 1 = line separator
        }
    }
    else if (indexPath.section == 1) {
        // content
        if (self.data.count > indexPath.row) {
            // prevent getting object at index beyond bounds of array
            NSError *error;
            Post *postAtIndex = [[Post alloc] initWithDictionary:self.data[indexPath.row] error:&error];
            //NSLog(@"post @ index: %@", error.userInfo);
            
            if ([postAtIndex.type isEqualToString:@"post"]) {
                // name @username • 2hr
                CGFloat nameHeight = 16 + 6; // 6pt padding underneath
                
                // message
                CGRect textViewRect = [postAtIndex.attributes.details.simpleMessage boundingRectWithSize:CGSizeMake(self.frame.size.width - postContentOffset.left - postContentOffset.right, 1200) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:textViewFont} context:nil];
                CGFloat textViewHeight = ceilf(textViewRect.size.height);
                
                // image
                BOOL hasImage = false; // postAtIndex.images != nil && postAtIndex.images.count > 0;
                CGFloat imageHeight = hasImage ? [Session sharedInstance].defaults.post.imgHeight + 6 : 0;
                BOOL hasURLPreview = [postAtIndex requiresURLPreview];
                CGFloat urlPreviewHeight = !hasImage && hasURLPreview ? [Session sharedInstance].defaults.post.imgHeight + 6 : 0;
                
                // actions
                CGFloat actionsHeight = 0; // 4 + actionsViewHeight;
                
                // deatil button
                CGFloat detailHeight = 0;// (self.dataType != tableCategoryPost ? 14 + 4 : 0); // 4pt padding on top
                
                CGFloat postHeight = postContentOffset.top + nameHeight + (textViewHeight+12) + imageHeight + urlPreviewHeight + actionsHeight + detailHeight + postContentOffset.bottom;
                
                return postHeight;
            }
            
            /*
            NSError *error;
            Post *postAtIndex = [[Post alloc] initWithDictionary:self.data[indexPath.row] error:&error];
            //NSLog(@"post @ index: %@", error.userInfo);
            
            if ([postAtIndex.type isEqualToString:@"post"]) {
                // name @username • 2hr
                CGFloat nameHeight = 16 + 2; // 2pt padding underneath
                
                // message
                CGRect textViewRect = [postAtIndex.attributes.details.message boundingRectWithSize:CGSizeMake(self.frame.size.width - postContentOffset.left - postContentOffset.right, 1200) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:textViewFont} context:nil];
                CGFloat textViewHeight = ceilf(textViewRect.size.height);
                
                // image
                BOOL hasImage = false; // postAtIndex.images != nil && postAtIndex.images.count > 0;
                CGFloat imageHeight = hasImage ? postImageHeight + 6 : 0;
                // actions
                CGFloat actionsHeight = 0; // 4 + actionsViewHeight;
                
                // deatil button
                CGFloat detailHeight = 0;// (self.dataType != tableCategoryPost ? 14 + 4 : 0); // 4pt padding on top

                CGFloat postHeight = postContentOffset.top + nameHeight + textViewHeight + imageHeight + actionsHeight + detailHeight + postContentOffset.bottom;
                CGFloat minHeight = postContentOffset.top + 40 + postContentOffset.bottom;
                
                return (postHeight > minHeight) ? postHeight : minHeight;
            }
             */
        }
        else {
            if (self.data.count == 0) {
                NSInteger postType = (indexPath.row + 2) % 3;
                
                switch (postType) {
                    case 0:
                        return 80;
                    case 1:
                        return 101;
                    case 2:
                        return 226;
                        
                    default:
                        return 83;
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
        if (self.dataType == tableCategoryRoom ||
            self.dataType == tableCategoryProfile ||
            self.dataType == tableCategoryPost) {
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
        
        return self.loading ? 10 : self.data.count + ([self morePosts] || self.loadingMore ? 1 : 0);
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
    }
    else if (indexPath.section == 1 && self.dataType != tableCategoryPost) {
        if (self.data.count > indexPath.row) {
            // prevent getting object at index beyond bounds of array
            if ([self.data[indexPath.row][@"type"] isEqualToString:@"post"]) {
                Post *postAtIndex = [[Post alloc] initWithDictionary:self.data[indexPath.row] error:nil];
                
                if ([UIViewParentController(self).navigationController isKindOfClass:[LauncherNavigationViewController class]]) {
                    [(LauncherNavigationViewController *)UIViewParentController(self).navigationController  openPost:postAtIndex];
                }
            }
        }
    }
}
//@property (nonatomic) NSInteger lastSinceId;
- (BOOL)morePosts {
    if (self.data.count > 0) {
        NSError *error;
        Post *lastPost = [[Post alloc] initWithDictionary:self.data[self.data.count-1] error:&error];
        
        if (!error) {
            if (lastPost.identifier != self.lastSinceId) {
                return true;
            }
        }
    }
    
    return false;
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1 &&
       indexPath.row == self.data.count &&
       [self morePosts]) {
        if(indexPath.section == 1 && indexPath.row == self.data.count) {
            NSError *error;
            Post *lastPost = [[Post alloc] initWithDictionary:self.data[self.data.count-1] error:&error];
            if (!error) {
                self.lastSinceId = lastPost.identifier;
                self.loadingMore = true;
                
                NSLog(@"load more posts... with since id: %ld", (long)self.lastSinceId);
                
                PaginationCell *paginationCell = (PaginationCell *)cell;
                if (!paginationCell.loading) {
                    paginationCell.loading = true;
                    paginationCell.spinner.hidden = false;
                    [paginationCell.spinner startAnimating];
                }
                
                [self.paginationDelegate tableView:self didRequestNextPageWithSinceId:self.lastSinceId];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.dataType == tableCategoryProfile ||
        self.dataType == tableCategoryPost ||
        self.dataType == tableCategoryRoom) {
        return section == 0 ? 0 : 64; // 8 = spacing underneath
    }
    return 0;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        if ((self.loading || (!self.loading && self.data.count > 0)) &&
            (self.dataType == tableCategoryProfile ||
            self.dataType == tableCategoryPost ||
            self.dataType == tableCategoryRoom)) {
            UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 64)];
            
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 64)];
            [headerContainer addSubview:header];
                
            header.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
            
            UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(20, 28, 24, 24)];
            icon.image = [[UIImage imageNamed:@"repliesIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            icon.contentMode = UIViewContentModeScaleAspectFit;
            icon.tintColor = [UIColor colorWithWhite:0.6f alpha:1];
            icon.layer.cornerRadius = icon.frame.size.height / 2;
            [header addSubview:icon];
            
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(62, icon.frame.origin.y, self.frame.size.width - 62 - 200, icon.frame.size.height)];
            if (self.dataType == tableCategoryRoom) {
                title.text = @"Trending";
                
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
            else if (self.dataType == tableCategoryProfile) {
                title.text = @"Recent Posts";
            }
            else if (self.dataType == tableCategoryPost) {
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
    return 0;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)expandImageView:(UIImageView *)imageView {
    NSLog(@"expand image view!");
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

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    if (hexString != nil && hexString.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        return [UIColor colorWithDisplayP3Red:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }
    else {
        return [UIColor colorWithWhite:0.2f alpha:1];
    }
}

@end
