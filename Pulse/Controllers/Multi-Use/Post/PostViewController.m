//
//  PostViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "PostViewController.h"
#import <UINavigationItem+Margin.h>
#import "ComplexNavigationController.h"
#import "ErrorView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Launcher.h"
#import <JGProgressHUD/JGProgressHUD.h>
#import "UIColor+Palette.h"
#import "InsightsLogger.h"

#import "ExpandedPostCell.h"
#import "ReplyCell.h"
#import "MiniReplyCell.h"
#import "ExpandThreadCell.h"
#import "PaginationCell.h"

@interface PostViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL loadingMore;

@property (strong, nonatomic) ErrorView *errorView;
@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property (nonatomic, strong) NSMutableArray *posts;
@property (strong, nonatomic) ComplexNavigationController *launchNavVC;

@end

@implementation PostViewController

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const postReplyReuseIdentifier = @"postReply";
static NSString * const postSubReplyReuseIdentifier = @"postSubReply";
static NSString * const expandedPostReuseIdentifier = @"expandedPost";
static NSString * const addAReplyCellIdentifier = @"addAReplyCell";
static NSString * const expandRepliesCellIdentifier = @"expandRepliesCell";

static NSString * const paginationCellIdentifier = @"PaginationCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.launchNavVC = (ComplexNavigationController *)self.navigationController;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSString *themeCSS;
    if (self.post.attributes.status.postedIn != nil) {
        themeCSS = [self.post.attributes.status.postedIn.attributes.details.color lowercaseString];
    }
    else {
        themeCSS = [self.post.attributes.details.creator.attributes.details.color lowercaseString];
    }
    self.theme = [UIColor fromHex:[themeCSS isEqualToString:@"ffffff"]?@"222222":themeCSS];
    
    [self setupTableView];
    [self setupErrorView];
    
    self.manager = [HAWebService manager];
    
    if (self.post.identifier) {
        [self setupComposeInputView];
        
        self.loading = true;
    }
    
    self.view.tintColor = self.theme;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUpdated:) name:@"PostUpdated" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && tempPost.attributes.details.parent != 0) {
        if (tempPost.attributes.details.parent == self.post.identifier) {
            // parent post
            self.errorView.hidden = true;
            [self.stream addTempPost:tempPost];
        }
        else {
            // could be a reply to a reply? let's check.
            NSLog(@"wooooo!!!");
            [self.stream addTempSubReply:tempPost];
        }
        
        [self.tableView reloadData];
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    if (post != nil && post.attributes.details.parent != 0) {
        if (post.attributes.details.parent == self.post.identifier) {
            // parent post
            // TODO: Check for image as well
            self.errorView.hidden = true;
            [self.stream updateTempPost:tempId withFinalPost:post];
            
            [UIView animateWithDuration:0 animations:^{
                [self.tableView reloadData];
            } completion:^(BOOL finished) {
                //Do something after that...
                NSIndexPath* ipath = [NSIndexPath indexPathForRow:0 inSection:[self.tableView numberOfSections]-1];
                [self.tableView scrollToRowAtIndexPath:ipath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }];
            
            /*
             // update Post object
             PostSummaries *summaries = self.post.attributes.summaries == nil ? [[PostSummaries alloc] init] : self.post.attributes.summaries;
             //summaries.replies = summaries.replies == nil ? @[post] : [summaries.replies arrayByAddingObject:post];
             summaries.counts.replies = summaries.counts.replies + 1;
             self.post.attributes.summaries = summaries;
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:self.post];*/
        }
        else {
            // could be a reply to a reply? let's attempt
            [self.stream updateTempSubReply:tempId withFinalSubReply:post];
            
            [UIView animateWithDuration:0 animations:^{
                [self.tableView reloadData];
            } completion:^(BOOL finished) {
                NSArray<Post *> *posts = self.stream.posts;
                for (int i = 0; i < posts.count; i++) {
                    if (posts[i].identifier == post.attributes.details.parent) {
                        [self updateContentInsets];
                        
                        // scroll to this item!
                        NSInteger section = i + 1;
                        NSIndexPath* ipath = [NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:section]-1 inSection:section];
                        [self.tableView scrollToRowAtIndexPath:ipath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                        
                        break;
                    }
                }
            }];
        }
    }
}
// TODO: Allow tap to retry for posts
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && tempPost.attributes.details.parent == self.post.identifier && tempPost.attributes.details.parent != 0) {
        // TODO: Check for image as well
        [self.stream removeTempPost:tempPost.tempId];
        [self.tableView reloadData];
        self.errorView.hidden = (self.stream.posts.count != 0);
    }
}

- (void)postUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[Post class]]) {
        Post *post = (Post *)notification.object;
        if (post.identifier == self.post.identifier) {
            // match
            self.post = post;
            [self.tableView reloadData];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.view.tag == 1) {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInRoomView];
    }
    else {
        self.view.tag = 1;
        [self loadPost];
        [self styleOnAppear];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
    
    if (self.showKeyboardOnOpen) {
        self.showKeyboardOnOpen = false;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.composeInputView.textView becomeFirstResponder];
        });
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.tableView];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)loadPost {
    if (self.post.identifier) {
        // fill in post info
        [self.tableView reloadData];
        
        [self getPostInfo];
        [self loadPostReplyContent];
    }
    else {
        // post not found
        self.tableView.hidden = true;
        self.errorView.hidden = false;
        
        [self.errorView updateTitle:@"Post Not Found"];
        [self.errorView updateDescription:@"We couldn’t find the post\nyou were looking for"];
        [self.errorView updateType:ErrorViewTypeNotFound];
        
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.launchNavVC.rightActionButton.alpha = 0;
        } completion:^(BOOL finished) {
        }];
    }
}
- (void)getPostInfo {
    [self.tableView reloadData];
    
    NSString *url;
    if (self.post.attributes.status.postedIn != nil) {
        // posted in a room
        url = [NSString stringWithFormat:@"%@/%@/rooms/%@/posts/%ld", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.post.attributes.status.postedIn.identifier, (long)self.post.identifier];
    }
    else {
        // posted on a profile
        url = [NSString stringWithFormat:@"%@/%@/users/%@/posts/%ld", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.post.attributes.details.creator.identifier, (long)self.post.identifier];
    }
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSDictionary *params = @{};
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
                
                self.errorView.hidden = true;
                
                // Determine whether posted to profile or Room
                BOOL requiresColorUpdate = false;
                
                BOOL postedInRoom = self.post.attributes.status.postedIn != nil;
                if (postedInRoom) {
                    requiresColorUpdate = (self.post.attributes.status.postedIn.attributes.details.color == nil);
                }
                else {
                    requiresColorUpdate = (self.post.attributes.details.creator.attributes.details.color == nil);
                }
                
                PostContext *contextBefore = self.post.attributes.context;
                
                // first page
                NSError *postError;
                self.post = [[Post alloc] initWithDictionary:responseData error:&postError];
                
                if (contextBefore && self.post.attributes.context == nil) {
                    self.post.attributes.context = contextBefore;
                }
                
                // update the theme color (in case we didn't know the Room/Profile color before
                if (requiresColorUpdate) {
                    [self updateTheme];
                }
                
                if (postError) {
                    NSLog(@"postError; %@", postError);
                }
                
                [self.tableView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomViewController / getRoom() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                // self.errorView.hidden = false;
                
                NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
                NSInteger statusCode = httpResponse.statusCode;
                
                if (statusCode == 404) {
                    self.errorView.hidden = false;
                    self.post = nil;
                    [self hideComposeInputView];
                    self.launchNavVC.rightActionButton.alpha = 0;
                    
                    [self.errorView updateType:ErrorViewTypeGeneral];
                    [self.errorView updateTitle:nil];
                    [self.errorView updateDescription:@"This post has been deleted"];
                }
                else {
                    // [self.errorView updateType:ErrorViewTypeGeneral];
                    // [self.errorView updateTitle:@"Error Loading Post"];
                    // [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
                }
                
                self.loading = false;
                /*self.tableView.loading = false;
                self.tableView.loadingMore = false;
                self.tableView.error = true;*/
                [self.tableView reloadData];
                
                [self positionErrorView];
            }];
        }
    }];
}
- (void)loadPostReplyContent {
    if ([self canViewPost]) {
        [self showComposeInputView];
        
        [self getRepliesWithNextCursor:nil];
    }
    else {
        [self hideComposeInputView];
        
        self.errorView.hidden = false;
        
        self.loading = false;
        /*self.tableView.loading = false;
        self.tableView.loadingMore = false;*/
        [self.tableView reloadData];
        
        Room *room = self.post.attributes.status.postedIn;
        if (room != nil) {
            !room.attributes.status.isBlocked && // Room not blocked
            ![room.attributes.context.status isEqualToString:ROOM_STATUS_BLOCKED] && // User blocked by Room
            (!room.attributes.status.visibility.isPrivate || // (public room OR
             [room.attributes.context.status isEqualToString:ROOM_STATUS_MEMBER]);
            if (room.attributes.status.isBlocked) { // Room has been blocked
                [self.errorView updateTitle:@"Post Not Available"];
                [self.errorView updateDescription:@"This post is no longer available"];
                [self.errorView updateType:ErrorViewTypeBlocked];
            }
            else if ([room.attributes.context.status isEqualToString:ROOM_STATUS_BLOCKED]) { // blocked from Room
                [self.errorView updateTitle:@"Blocked By Camp"];
                [self.errorView updateDescription:@"Your account is blocked from creating and viewing posts in this Camp"];
                [self.errorView updateType:ErrorViewTypeBlocked];
            }
            else if (room.attributes.status.visibility.isPrivate) { // not blocked, not member
                // private room but not a member yet
                [self.errorView updateTitle:@"Private Post"];
                if (room.attributes.details.title.length > 0) {
                    [self.errorView updateDescription:@"You must be a member to view this post"];
                }
                else {
                    [self.errorView updateDescription:[NSString stringWithFormat:@"Request access to join the %@ Camp to view this post", room.attributes.details.title]];
                }
                [self.errorView updateType:ErrorViewTypeLocked];
            }
            else {
                self.tableView.hidden = true;
                self.errorView.hidden = false;
                
                [self.errorView updateTitle:@"Post Not Found"];
                [self.errorView updateDescription:@"We couldn’t find the post\nyou were looking for"];
                [self.errorView updateType:ErrorViewTypeNotFound];
                
                [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.launchNavVC.rightActionButton.alpha = 0;
                } completion:^(BOOL finished) {
                }];
            }
        }
        else {
            self.tableView.hidden = true;
            self.errorView.hidden = false;
            
            [self.errorView updateTitle:@"Post Not Found"];
            [self.errorView updateDescription:@"We couldn’t find the post\nyou were looking for"];
            [self.errorView updateType:ErrorViewTypeNotFound];
            
            [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.launchNavVC.rightActionButton.alpha = 0;
            } completion:^(BOOL finished) {
            }];
        }
        
        [self positionErrorView];
    }
}
- (void)showComposeInputView {
    if (self.composeInputView.isHidden) {
        self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        self.composeInputView.hidden = false;
        
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}
- (void)hideComposeInputView {
    if (!self.composeInputView.isHidden) {
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        } completion:^(BOOL finished) {
            self.composeInputView.hidden = true;
        }];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        // expanded post
        return self.post == nil ? 0 : 1;
    }
    else if (section <= self.stream.posts.count) {
        Post *reply = self.stream.posts[section-1];
        CGFloat subReplies = reply.attributes.summaries.replies.count;
        
        // 0   : "hide replies"
        // 1-x : replies
        // x+1 : "view more replies"
        // x+2 : "add a reply..."
        
        BOOL showHideReplies = (subReplies >= reply.attributes.summaries.counts.replies) && reply.attributes.summaries.counts.replies > 2;
        BOOL showViewMore = (subReplies < reply.attributes.summaries.counts.replies);
        BOOL showAddReply = false;
        
        NSInteger rows = 1 + (showHideReplies ? 1 : 0) + subReplies + (showViewMore ? 1 : 0) + (showAddReply ? 1 : 0);
        
        NSLog(@"NUMBER OF ROWS (section %ld) :: %ld", section, rows);
        NSLog(@"showHideReplies: %@", showHideReplies ? @"YES" : @"NO");
        NSLog(@"showViewMore: %@", showViewMore ? @"YES" : @"NO");
        NSLog(@"showAddReply: %@", showAddReply ? @"YES" : @"NO");
        NSLog(@"–––––––");
        
        return rows;
    }
    else if (section == self.stream.posts.count + 1) {
        // assume it's a pagination cell
        return 1;
    }
    
    return 0;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSLog(@"NUMBER OF SECTIONS :: %ld", 1 + self.stream.posts.count);
    BOOL hasAnotherPage = self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.next_cursor != nil && [self.stream.pages lastObject].meta.paging.next_cursor.length > 0;
    return 1 + (self.loading ? 1 : self.stream.posts.count + (hasAnotherPage ? 1 : 0));
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // expanded post
        ExpandedPostCell *cell = [tableView dequeueReusableCellWithIdentifier:expandedPostReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ExpandedPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandedPostReuseIdentifier];
        }
        
        cell.loading = self.loading;
        
        cell.post = self.post;
        
        if (cell.actionsView.replyButton.gestureRecognizers == 0) {
            [cell.actionsView.replyButton bk_whenTapped:^{
                [self.composeInputView.textView becomeFirstResponder];
            }];
        }
        
        if (!cell.loading) {
            [cell.activityView start];
        }
        
        if (cell.post.identifier != 0) {
            // [self didBeginDisplayingCell:cell]; // self.tableview didBegin...
            // TODO: Move this to RSTableView class
        }
        
        return cell;
    }
    else if (indexPath.section < (self.stream.posts.count + 1)) { // offset by 1 due to expanded post on the top
        // determine if it's a reply or sub-reply
        Post *reply = self.stream.posts[indexPath.section-1];
        CGFloat subReplies = reply.attributes.summaries.replies.count;
        // 0       : actual reply
        // 1       : --- "hide replies"
        // 2-(x+1) : --- replies
        // (x+1)+1 : --- "view more replies"
        // (x+1)+2 : --- "add a reply..."
        
        BOOL showHideReplies = (subReplies >= reply.attributes.summaries.counts.replies) && reply.attributes.summaries.counts.replies > 2;
        BOOL showViewMore = (subReplies < reply.attributes.summaries.counts.replies);
        BOOL showAddReply = false;
        
        NSInteger firstSubReplyIndex = 1 + (showHideReplies ? 1 : 0);
        
        if (indexPath.row == 0) {
            // reply
            ReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:postReplyReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postReplyReuseIdentifier];
            }
            
            NSInteger identifierBefore = cell.post.identifier;
            
            cell.post = reply;
            
            if (cell.post.identifier != 0 && identifierBefore == cell.post.identifier) {
                //[self didBeginDisplayingCell:cell];
            }
            
            cell.lineSeparator.hidden = true;
            // cell.detailsType = DetailsViewTypeNone;
            
            if (cell.detailReplyButton.gestureRecognizers.count == 0) {
                [cell.detailReplyButton bk_whenTapped:^{
                    [self.composeInputView setReplyingTo:cell.post];
                    [self.composeInputView.textView becomeFirstResponder];
                    
                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                }];
            }
            
            return cell;
        }
        else if (showHideReplies && indexPath.row == 1) {
            // "hide replies"
            ExpandThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:expandRepliesCellIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[ExpandThreadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandRepliesCellIdentifier];
            }
            
            cell.textLabel.text = @"Hide replies";
            cell.tag = 1;
            
            return cell;
        }
        else if ((indexPath.row - firstSubReplyIndex) <  reply.attributes.summaries.replies.count) {
            NSInteger subReplyIndex = indexPath.row - firstSubReplyIndex;
            
            // sub reply
            MiniReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:postSubReplyReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[MiniReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postSubReplyReuseIdentifier];
            }
            
            NSInteger identifierBefore = cell.post.identifier;
            
            Post *subReply = reply.attributes.summaries.replies[subReplyIndex];
            cell.post = subReply;
                        
            if (cell.post.identifier != 0 && identifierBefore == cell.post.identifier) {
                //[self didBeginDisplayingCell:cell];
            }
            
            return cell;
        }
        else if (showViewMore && indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex) {
            // "view more replies"
            ExpandThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:expandRepliesCellIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[ExpandThreadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandRepliesCellIdentifier];
            }
            
            BOOL hasExistingSubReplies = reply.attributes.summaries.replies.count != 0;
            cell.textLabel.text = [NSString stringWithFormat:@"View%@ replies (%ld)", (hasExistingSubReplies ? @" more" : @""), (long)reply.attributes.summaries.counts.replies - reply.attributes.summaries.replies.count];
            
            if (hasExistingSubReplies) {
                // view more replies
                cell.tag = 2;
            }
            else {
                // start replies chain
                cell.tag = 3;
            }
            
            return cell;
        }
        else if (showAddReply && indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex + (showViewMore ? 1 : 0)) {
            // "add a reply"
            
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
    blankCell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1*indexPath.row];
    return blankCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        // expanded post
        return [ExpandedPostCell heightForPost:self.post];
    }
    else if (indexPath.section - 1 < self.stream.posts.count) {
        Post *reply = self.stream.posts[indexPath.section-1];
        CGFloat subReplies = reply.attributes.summaries.replies.count;
        // 0       : actual reply
        // 1       : --- "hide replies"
        // 2-(x+1) : --- replies
        // (x+1)+1 : --- "view more replies"
        // (x+1)+2 : --- "add a reply..."
        
        BOOL showHideReplies = (subReplies >= reply.attributes.summaries.counts.replies) && reply.attributes.summaries.counts.replies > 2;
        BOOL showViewMore = (subReplies < reply.attributes.summaries.counts.replies);
        BOOL showAddReply = false;
        
        NSInteger firstSubReplyIndex = 1 + (showHideReplies ? 1 : 0);
        
        if (indexPath.row == 0) {
            return [ReplyCell heightForPost:reply];
        }
        else if (showHideReplies && indexPath.row == 1) {
            // "hide replies"
            return CONVERSATION_EXPAND_CELL_HEIGHT;
        }
        else if ((indexPath.row - firstSubReplyIndex) <  reply.attributes.summaries.replies.count) {
            NSInteger subReplyIndex = indexPath.row - firstSubReplyIndex;
            Post *subReply = reply.attributes.summaries.replies[subReplyIndex];
            return [MiniReplyCell heightForPost:subReply];
        }
        else if (showViewMore && indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex) {
            // "view more replies"
            return CONVERSATION_EXPAND_CELL_HEIGHT;
        }
        else if (showAddReply && indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex + (showViewMore ? 1 : 0)) {
            // "add a reply"
            return CONVERSATION_ADD_REPLY_CELL_HEIGHT;
        }
    }
    else if (indexPath.section - 1 == self.stream.posts.count) {
        return 52;
    }
    
    return 0; // TODO: Switch to 0
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[ExpandThreadCell class]]) {
        Post *reply = self.stream.posts[indexPath.section-1];
        if (cell.tag == 1) {
            // hide replies
            [self.stream clearSubRepliesForPost:reply];
            
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexPath.section, 1)] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else if (cell.tag == 2) {
            // "view more replies" -- append to existing subreplies
            [self getSubRepliesToReply:reply];
        }
        else if (cell.tag == 3) {
            // "view replies" -- start fresh
            [self getSubRepliesToReply:reply];
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if([cell isKindOfClass:[PaginationCell class]]) {
        if (!self.loadingMore && self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.next_cursor != nil && [self.stream.pages lastObject].meta.paging.next_cursor.length > 0) {
            self.loadingMore = true;
            [self getRepliesWithNextCursor:[self.stream.pages lastObject].meta.paging.next_cursor];
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
    
    [InsightsLogger.sharedInstance openPostInsight:post.identifier seenIn:InsightSeenInPostView];
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

- (void)getSubRepliesToReply:(Post *)reply {
    NSInteger nextCursor = (reply.attributes.summaries.replies.count > 0 ? reply.attributes.summaries.replies[0].identifier : 0);
    
    NSString *url;
    if (self.post.attributes.status.postedIn != nil) {
        // posted in a room
        url = [NSString stringWithFormat:@"%@/%@/rooms/%@/posts/%ld/replies", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.post.attributes.status.postedIn.identifier, (long)reply.identifier];
    }
    else {
        // posted on a profile
        url = [NSString stringWithFormat:@"%@/%@/users/%@/posts/%ld/replies", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.post.attributes.details.creator.identifier, (long)reply.identifier];
    }
    NSLog(@"📲: %@", url);
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSDictionary *params = @{}; // (nextCursor != 0 ? @{@"cursor": [NSNumber numberWithInteger:nextCursor]} : @{});
            
            NSLog(@"params: %@", params);
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"PostViewController / getSubRepliesToReply() success! ✅");
                if ([responseObject isKindOfClass:[NSDictionary class]] && [responseObject objectForKey:@"data"] && ((NSArray *)responseObject[@"data"]).count > 0) {
                    BOOL addSubReplies = [self.stream addSubReplies:responseObject[@"data"] toPost:reply];
                    
                    if (addSubReplies)
                        [self.tableView reloadData];
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"FeedViewController / getReplies() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            }];
        }
    }];
}

- (void)updateTheme {
    UIColor *theme;
    
    BOOL postedInRoom = self.post.attributes.status.postedIn != nil;
    if (postedInRoom) {
        theme = [UIColor fromHex:self.post.attributes.status.postedIn.attributes.details.color];
    }
    else {
        theme = [UIColor fromHex:self.post.attributes.details.creator.attributes.details.color];
    }
    
    [self.launchNavVC updateBarColor:theme withAnimation:1 statusBarUpdateDelay:0];
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.composeInputView.textView.tintColor = theme;
        self.composeInputView.postButton.backgroundColor = theme;
        self.composeInputView.addMediaButton.tintColor = theme;
    } completion:^(BOOL finished) {
    }];
    
    self.theme = theme;
    self.view.tintColor = self.theme;
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Error loading replies" description:@"Tap to try again" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        NSError *postError;
        self.post = [[Post alloc] initWithDictionary:[self.post toDictionary] error:&postError];
        
        if (postError || // room has error OR
            [self canViewPost]) { // no error and can view posts
            self.errorView.hidden = true;
            
            [self loadPost];
            [self loadPostReplyContent];
        }
    }];
}
- (BOOL)canViewPost {
    Room *room = self.post.attributes.status.postedIn;
    if (room) {
        BOOL canViewPost = room.identifier != nil && // has an ID
                            !room.attributes.status.isBlocked && // Room not blocked
                            ![room.attributes.context.status isEqualToString:ROOM_STATUS_BLOCKED];
        
        return canViewPost;
    }
    else {
        return true;
    }
    
    return false;
}


- (void)setupComposeInputView {
    self.composeInputView = [[ComposeInputView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 52, self.view.frame.size.width, 190)];
    self.composeInputView.parentViewController = self;
    self.composeInputView.maxImages = 1;

    [self.composeInputView bk_whenTapped:^{
        if (![self.composeInputView isActive]) {
            [self.composeInputView setActive:true];
        }
    }];
    [self.composeInputView.postButton bk_whenTapped:^{
        [self postMessage];
    }];
    [self.composeInputView.expandButton bk_whenTapped:^{
        [[Launcher sharedInstance] openComposePost:self.post.attributes.status.postedIn inReplyTo:self.post withMessage:self.composeInputView.textView.text media:self.composeInputView.media];
    }];
    [self.composeInputView.replyingToLabel bk_whenTapped:^{
        // scroll to post you're replying to
        NSArray<Post *> *posts = self.stream.posts;
        for (int i = 0; i < posts.count; i++) {
            if (posts[i].identifier == self.composeInputView.replyingTo.identifier) {
                // scroll to this item!
                NSIndexPath* ipath = [NSIndexPath indexPathForRow:0 inSection:i+1];
                [self.tableView scrollToRowAtIndexPath:ipath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                
                break;
            }
        }
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.textView.delegate = self;
    self.composeInputView.tintColor = [self.theme isEqual:[UIColor whiteColor]] ? [UIColor colorWithWhite:0.2f alpha:1] : self.theme;
    self.composeInputView.postButton.backgroundColor = self.composeInputView.tintColor;
    self.composeInputView.addMediaButton.tintColor = self.composeInputView.tintColor;
    
    // self.tableView.inputView = self.composeInputView;
}
- (void)textViewDidChange:(UITextView *)textView {
    if ([textView isEqual:self.composeInputView.textView]) {
        [self.composeInputView resize:false];
        
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        CGFloat bottomPadding = window.safeAreaInsets.bottom;
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + bottomPadding, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
        
        if (textView.text.length > 0) {
            [self.composeInputView showPostButton];
        }
        else {
            [self.composeInputView hidePostButton];
        }
    }
}
- (void)postMessage {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *message = self.composeInputView.textView.text;
    if (message.length > 0) {
        [params setObject:message forKey:@"message"];
    }
    if (self.composeInputView.media.count > 0) {
        [params setObject:self.composeInputView.media forKey:@"images"];
    }
    
    if ([params objectForKey:@"message"] || [params objectForKey:@"images"]) {
        // meets min. requirements
        Post *replyingTo = (self.composeInputView.replyingTo != nil) ? self.composeInputView.replyingTo : self.post;
        if (self.post.attributes.status.postedIn) {
            [[Session sharedInstance] createPost:params postingIn:self.post.attributes.status.postedIn replyingTo:replyingTo];
        }
        else {
            [[Session sharedInstance] createPost:params postingIn:nil replyingTo:replyingTo];
        }
        
        self.composeInputView.textView.text = @"";
        [self.composeInputView hidePostButton];
        self.composeInputView.media = [[NSMutableArray alloc] init];
        [self.composeInputView hideMediaTray];
        [self.composeInputView setReplyingTo:nil];
    }
}

- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.bounds.size.width, collapsed_inputViewHeight);
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding + 12, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding, 0);
}

- (void)getRepliesWithNextCursor:(NSString *)nextCursor {
    if ([nextCursor isEqualToString:@""]) {
        self.loading = false;
        
        /*self.tableView.loading = false;
        self.tableView.loadingMore = false;*/
        
        [self.tableView reloadData];
        
        return;
    }
    
    self.errorView.hidden = true;
    self.tableView.hidden = false;
    
    NSString *url;

    if (self.post.attributes.status.postedIn != nil) {
        // posted in a room
        url = [NSString stringWithFormat:@"%@/%@/rooms/%@/posts/%ld/replies", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.post.attributes.status.postedIn.identifier, (long)self.post.identifier];
    }
    else {
        // posted on a profile
        url = [NSString stringWithFormat:@"%@/%@/users/%@/posts/%ld/replies", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.post.attributes.details.creator.identifier, (long)self.post.identifier];
    }
    NSLog(@"📲: %@", url);

    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            
            NSDictionary *params = nextCursor ? @{@"cursor": nextCursor} : @{};
            
            if (nextCursor) {
                NSLog(@"FETCH MORE REPLIES");
            }
            
            // NSLog(@"params: %@", params);
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // NSLog(@"CommonTableViewController / getReplies() success! ✅");
                PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
                if (page.data.count == 0) {
                    // self.tableView.reachedBottom = true;
                }
                else {
                    [self.stream appendPage:page];
                }
                
                self.errorView.hidden = true;
                
                self.loading = false;
                self.loadingMore = false;
                
                [self.tableView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"FeedViewController / getReplies() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.loading = false;
                self.loadingMore = false;
                
                self.tableView.userInteractionEnabled = true;
                [self.tableView reloadData];
            }];
        }
    }];
}
- (void)positionErrorView {
    ExpandedPostCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat heightOfHeader = headerCell.frame.size.height;
    self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 64, self.errorView.frame.size.width, self.errorView.frame.size.height);
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 72, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.refreshControl = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.tintColor = self.theme;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    [self.tableView registerClass:[ReplyCell class] forCellReuseIdentifier:postReplyReuseIdentifier];
    [self.tableView registerClass:[MiniReplyCell class] forCellReuseIdentifier:postSubReplyReuseIdentifier];
    [self.tableView registerClass:[ExpandedPostCell class] forCellReuseIdentifier:expandedPostReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:addAReplyCellIdentifier];
    [self.tableView registerClass:[ExpandThreadCell class] forCellReuseIdentifier:expandRepliesCellIdentifier];
    [self.tableView registerClass:[PaginationCell class] forCellReuseIdentifier:paginationCellIdentifier];
    
    self.stream = [[PostStream alloc] init];
    [self.stream setTempPostPosition:PostStreamOptionTempPostPositionBottom];
    
    [self.view addSubview:self.tableView];
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.stream.posts.count > 0) {
        [self getRepliesWithNextCursor:[self.stream.pages lastObject].meta.paging.next_cursor];
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    UIView *tapToDismissView = [self.view viewWithTag:888];
    
    /*if (!tapToDismissView) {
        tapToDismissView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height)];
        tapToDismissView.tag = 888;
        tapToDismissView.alpha = 0;
        tapToDismissView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.75];
        
        [self.view insertSubview:tapToDismissView aboveSubview:self.tableView];
    }
    
    self.tableView.scrollEnabled = false;
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        tapToDismissView.alpha = 1;
    } completion:nil];
    
    
    [tapToDismissView bk_whenTapped:^{
        [textView resignFirstResponder];
    }];*/
    UISwipeGestureRecognizer *swipeDownGesture = [[UISwipeGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        [textView resignFirstResponder];
    }];
    swipeDownGesture.direction = UISwipeGestureRecognizerDirectionDown;
    [tapToDismissView addGestureRecognizer:swipeDownGesture];
    
    return true;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    UIView *tapToDismissView = [self.view viewWithTag:888];
    
    /*
    if (self.loading) {
        self.tableView.scrollEnabled = false;
    }
    else {
        self.tableView.scrollEnabled = true;
    }*/
    
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        tapToDismissView.alpha = 0;
    } completion:^(BOOL finished) {
        [tapToDismissView removeFromSuperview];
    }];
    
    return true;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat newComposeInputViewY = self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, newComposeInputViewY, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    
    [self updateContentInsets];
}

- (void)updateContentInsets {
    CGFloat bottomPadding = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    
    CGFloat newComposeInputViewY = self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + bottomPadding;
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.view.frame.size.height - newComposeInputViewY - bottomPadding + (self.composeInputView.replyingTo != nil ? self.composeInputView.replyingToLabel.frame.size.height : 0), 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.height - newComposeInputViewY - bottomPadding + (self.composeInputView.replyingTo != nil ? self.composeInputView.replyingToLabel.frame.size.height : 0), 0);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        [self.composeInputView resize:false];
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.composeInputView.frame.size.height, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
        
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding + 12 + (self.composeInputView.replyingTo != nil ? self.composeInputView.replyingToLabel.frame.size.height : 0), 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding, 0);
    } completion:nil];
}

- (void)openPostActions {
    // Three Categories of Post Actions
    // 1) Any user
    // 2) Creator
    // 3) Admin
    BOOL isCreator     = ([self.post.attributes.details.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]);
    BOOL isRoomAdmin   = false;
    
    // Page action can be shown on
    // A) Any page
    // B) Inside Room
    BOOL insideRoom    = false; // compare ID of post room and active room

    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 1.A.* -- Any user, any page, any following state
    BOOL hasiMessage = [MFMessageComposeViewController canSendText];
    if (hasiMessage) {        
        UIAlertAction *shareOniMessage = [UIAlertAction actionWithTitle:@"Share on iMessage" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"share on iMessage");
            
            NSString *url;
            if (self.post.attributes.status.postedIn != nil) {
                // posted in a room
                url = [NSString stringWithFormat:@"https://bonfire.com/rooms/%@/posts/%ld", self.post.attributes.status.postedIn.identifier, (long)self.post.identifier];
            }
            else {
                // posted on a profile
                url = [NSString stringWithFormat:@"https://bonfire.com/users/%@/posts/%ld", self.post.attributes.details.creator.identifier, (long)self.post.identifier];
            }
            
            NSString *message = [NSString stringWithFormat:@"%@  %@", self.post.attributes.details.message, url];
            [[Launcher sharedInstance] shareOniMessage:message image:nil];
        }];
        [actionSheet addAction:shareOniMessage];
    }
    
    // 1.A.* -- Any user, any page, any following state
    UIAlertAction *sharePost = [UIAlertAction actionWithTitle:@"Share via..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share post");
        
        [[Launcher sharedInstance] sharePost:self.post];
    }];
    [actionSheet addAction:sharePost];
    
    // 2.A.* -- Creator, any page, any following state
    // TODO: Hook this up to a JSON default
    
    // Turn off Quick Fix for now and introduce later
    /*
    if (isCreator) {
        UIAlertAction *editPost = [UIAlertAction actionWithTitle:@"Quick Fix" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"quick fix");
            // confirm action
        }];
        [actionSheet addAction:editPost];
    }*/
    
    // 1.B.* -- Any user, outside room, any following state
    if (!insideRoom) {
        UIAlertAction *openRoom = [UIAlertAction actionWithTitle:@"Open Camp" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"open camp");
            
            NSError *error;
            Room *room = [[Room alloc] initWithDictionary:[self.post.attributes.status.postedIn toDictionary] error:&error];
            
            [[Launcher sharedInstance] openRoom:room];
        }];
        [actionSheet addAction:openRoom];
    }
    
    // !2.A.* -- Not Creator, any page, any following state
    if (!isCreator) {
        UIAlertAction *reportPost = [UIAlertAction actionWithTitle:@"Report Post" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"report post");
            // confirm action
            UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Report Post" message:@"Are you sure you want to report this post?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *confirmDeletePost = [UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"confirm report post");
                [[Session sharedInstance] reportPost:self.post.identifier completion:^(BOOL success, id responseObject) {
                    NSLog(@"reported post!");
                }];
            }];
            [confirmDeletePostActionSheet addAction:confirmDeletePost];
            
            UIAlertAction *cancelDeletePost = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"cancel report post");
            }];
            [confirmDeletePostActionSheet addAction:cancelDeletePost];
            
            [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
        }];
        [actionSheet addAction:reportPost];
    }
    
    // 2|3.A.* -- Creator or room admin, any page, any following state
    if (isCreator || isRoomAdmin) {
        UIAlertAction *deletePost = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [actionSheet dismissViewControllerAnimated:YES completion:nil];
            NSLog(@"delete post");
            // confirm action
            UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Delete Post" message:@"Are you sure you want to delete this post?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *confirmDeletePost = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
                HUD.textLabel.text = @"Deleting...";
                HUD.vibrancyEnabled = false;
                HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
                HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
                [HUD showInView:self.navigationController.view animated:YES];
    
                NSLog(@"confirm delete post");
                [[Session sharedInstance] deletePost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        NSLog(@"deleted post!");
                        
                        // update room object
                        Room *postedInRoom = self.post.attributes.status.postedIn;
                        if (postedInRoom) {
                            postedInRoom.attributes.summaries.counts.posts = postedInRoom.attributes.summaries.counts.posts - 1;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:postedInRoom];
                            // update post object
                            self.post.attributes.status.postedIn = postedInRoom;
                        }
                        
                        // success
                        [HUD dismissAfterDelay:0];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if (self.navigationController) {
                                [self.launchNavVC popViewControllerAnimated:YES];
                                
                                [self.launchNavVC goBack];
                            }
                            else {
                                [self dismissViewControllerAnimated:YES completion:nil];
                            }
                        });
                    }
                    else {
                        HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
                        HUD.textLabel.text = @"Error Deleting";
                        
                        [HUD dismissAfterDelay:1.f];
                    }
                }];
            }];
            [confirmDeletePostActionSheet addAction:confirmDeletePost];
            
            UIAlertAction *cancelDeletePost = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"cancel delete post");
            }];
            [confirmDeletePostActionSheet addAction:cancelDeletePost];
            
            [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
        }];
        [actionSheet addAction:deletePost];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel");
    }];
    [actionSheet addAction:cancel];
    
    [UIViewParentController(self) presentViewController:actionSheet animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    //    if (textView == self.composeInputView.composeTextView){
    //        if ([text isEqualToString:@"\n"]) {
    //            return NO;
    //        }
    //    }
    //
    //    if (self.composeInputView.preventTyping) {
    //        NSLog(@"prevent typing");
    //
    //    }
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
