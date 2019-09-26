//
//  PostViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "PostViewController.h"
#import "UINavigationItem+Margin.h"
#import "SimpleNavigationController.h"
#import "ErrorView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "InsightsLogger.h"
#import "HAWebService.h"

#import "ExpandedPostCell.h"
#import "StreamPostCell.h"
#import "ReplyCell.h"
#import "AddReplyCell.h"
#import "ExpandThreadCell.h"
#import "PaginationCell.h"
@import Firebase;

@interface PostViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL loadingMore;

@property (nonatomic, strong) ErrorView *errorView;
@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property (nonatomic, strong) SimpleNavigationController *launchNavVC;
@property (nonatomic, assign) NSMutableArray *conversation;
@property (nonatomic, strong) UIActivityIndicatorView *parentPostSpinner;

@property (nonatomic, strong) UIVisualEffectView *shareUpsellView;

@end

@implementation PostViewController

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const postReplyReuseIdentifier = @"postReply";
static NSString * const postSubReplyReuseIdentifier = @"postSubReply";
static NSString * const parentPostReuseIdentifier = @"parentPost";
static NSString * const expandedPostReuseIdentifier = @"expandedPost";
static NSString * const addReplyCellIdentifier = @"addReplyCell";
static NSString * const expandRepliesCellIdentifier = @"expandRepliesCell";

static NSString * const paginationCellIdentifier = @"PaginationCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.launchNavVC = (SimpleNavigationController *)self.navigationController;
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
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
        
    if (self.post.identifier) {
        [self setupComposeInputView];
        //[self setupShareUpsellView];
        
        self.loading = true;
    }
    
    self.view.tintColor = self.theme;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUpdated:) name:@"PostUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:@"PostDeleted" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Conversation" screenClass:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.view.tag == 1) {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInCampView];
    }
    else {
        self.view.tag = 1;
        [self loadPost];
        [self styleOnAppear];
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
    
    if (self.showKeyboardOnOpen) {
        self.showKeyboardOnOpen = false;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.composeInputView.textView becomeFirstResponder];
        });
    }
    
    if (![self.composeInputView isFirstResponder]) {
        [self.composeInputView.textView becomeFirstResponder];
        [self.composeInputView.textView resignFirstResponder];
    }
}
- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.bounds.size.width, collapsed_inputViewHeight);
    self.shareUpsellView.frame = CGRectMake(self.shareUpsellView.frame.origin.x, self.composeInputView.frame.origin.y - self.shareUpsellView.frame.size.height, self.shareUpsellView.frame.size.width, self.shareUpsellView.frame.size.height);
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding + 12 + (![self.shareUpsellView isHidden] ? self.shareUpsellView.frame.size.height : 0), 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding + (![self.shareUpsellView isHidden] ? self.shareUpsellView.frame.size.height : 0), 0);
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.tableView];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - NSNotificationCenter observers
#pragma mark ↳ Keyboard observers
- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat newComposeInputViewY = self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, newComposeInputViewY, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    self.shareUpsellView.frame = CGRectMake(self.shareUpsellView.frame.origin.x, self.composeInputView.frame.origin.y - self.shareUpsellView.frame.size.height, self.shareUpsellView.frame.size.width, self.shareUpsellView.frame.size.height);
    
    [self updateContentInsets];
}
- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        [self.composeInputView resize:false];
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.composeInputView.frame.size.height, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
        self.shareUpsellView.frame = CGRectMake(self.shareUpsellView.frame.origin.x, self.composeInputView.frame.origin.y - self.shareUpsellView.frame.size.height, self.shareUpsellView.frame.size.width, self.shareUpsellView.frame.size.height);
    } completion:^(BOOL finished) {
        [self updateContentInsets];
    }];
}
#pragma mark ↳ Post changes
- (void)postUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[Post class]] && ![notification.object isEqual:self.post]) {
        Post *post = (Post *)notification.object;
        if ([post.identifier isEqualToString:self.post.identifier]) {
            NSLog(@"update that ish");
            // match
            self.post = post;
            
            CGPoint offset = self.tableView.contentOffset;
            [self.tableView reloadData];
            [self.tableView layoutIfNeeded]; // Force layout so things are updated before resetting the contentOffset.
            [self.tableView setContentOffset:offset];
        }
    }
}
- (void)postDeleted:(NSNotification *)notification {
    if (![notification.object isKindOfClass:[Post class]]) return;
    
    Post *post = notification.object;
    
    if ([post.identifier isEqualToString:self.post.identifier] || [post.identifier isEqualToString:self.post.attributes.details.parentId]) {
        [self setupPostHasBeenDeleted];
    }
    
    BOOL removePost = false;
    BOOL refresh = false;
    
    Post *postInStream = [self.stream postWithId:post.identifier];
    if (postInStream) {
        removePost = true;
        refresh = true;
    }
    
    if (removePost) [self.stream removePost:post];
    if (refresh) {
        [self.tableView reloadData];
    }
}
- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && tempPost.attributes.details.parentId.length > 0) {
        if ([tempPost.attributes.details.parentId isEqualToString:self.post.identifier]) {
            // parent post
            self.errorView.hidden = true;
            [self.stream addTempPost:tempPost];
            
            if (self.post.attributes.summaries.counts.replies == 0) {
                self.post.attributes.summaries.counts.replies++;
            }
        }
        else {
            // could be a reply to a reply? let's check.
            [self.stream addTempSubReply:tempPost];
        }
        
        [self.tableView reloadData];
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSLog(@"☑️ newPostCompleted");
    
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
        
    if (post != nil && post.attributes.details.parentId != 0) {
        if (post.attributes.details.parentId == self.post.identifier) {
            // reply
            self.errorView.hidden = true;
            [self.stream updateTempPost:tempId withFinalPost:post];
            
            [UIView animateWithDuration:0 animations:^{
                [self.tableView reloadData];
                [self.tableView layoutIfNeeded];
                [self updateContentInsets];
            } completion:^(BOOL finished) {
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    NSIndexPath* ipath = [NSIndexPath indexPathForRow:0 inSection:[self.tableView numberOfSections]-1];
//                    [self.tableView scrollToRowAtIndexPath:ipath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//                });
            }];
        }
        else {
            // could be a reply to a reply? let's attempt
            [self.stream updateTempSubReply:tempId withFinalSubReply:post];
            
            /*
            NSIndexPath* ipath;
            NSArray<Post *> *posts = self.stream.posts;
            for (NSInteger i = 0; i < posts.count; i++) {
                if (posts[i].identifier == post.attributes.details.parentId) {
                    // scroll to this item!
                    NSInteger section = i + 2;
                    ipath = [NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:section]-1 inSection:section];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.tableView scrollToRowAtIndexPath:ipath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                    });
                    
                    break;
                }
            }*/
            
            [UIView animateWithDuration:0 animations:^{
                [self.tableView reloadData];
                [self.tableView layoutIfNeeded];
                [self updateContentInsets];
            } completion:^(BOOL finished) {
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    [self.tableView scrollToRowAtIndexPath:ipath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//                });
            }];
        }
    }
}
- (void)newPostFailed:(NSNotification *)notification {
    // TODO: Allow tap to retry for posts
    Post *tempPost = notification.object;
    
    if (tempPost != nil && [tempPost.attributes.details.parentId isEqualToString:self.post.identifier] && tempPost.attributes.details.parentId.length > 0) {
        // TODO: Check for image as well
        [self.stream removeTempPost:tempPost.tempId];
        if (self.post.attributes.summaries.counts.replies > 0 && self.stream.posts.count == 0) {
            self.post.attributes.summaries.counts.replies = 0;
        }
        
        [self.tableView reloadData];
        self.errorView.hidden = (self.stream.posts.count != 0);
    }
}

#pragma mark - Load post
- (BOOL)hasParentPost {
    NSLog(@"has parent post ? %@", self.post.attributes.details.parentId);
    return (self.post.attributes.details.parentId.length > 0);
}
- (void)getParentPost {
    self.parentPostSpinner.hidden = false;
    
    NSString *url = [NSString stringWithFormat:@"posts/%@", self.post.attributes.details.parentId];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.parentPostSpinner.hidden = true;
        
        NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
        
        // force on the main thread to make sure it updates without lag
        [UIView animateWithDuration:0 animations:^{
            self.parentPost = [[Post alloc] initWithDictionary:responseData error:nil];
            [self.tableView reloadData];
            [self.tableView layoutIfNeeded];
            [self updateContentInsets];
            if (self.tableView.contentOffset.y == -(self.tableView.adjustedContentInset.top)) {
                [self.tableView setContentOffset:CGPointMake(0, [StreamPostCell heightForPost:self.parentPost showContext:true showActions:true] - self.tableView.adjustedContentInset.top)];
                self.parentPostScrollIndicator.transform = CGAffineTransformMakeTranslation(0, 0);
            }
        } completion:^(BOOL finished) {
            self.tableView.scrollEnabled = true;
            
            [self showParentPostScrollIndicator];
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"PostViewController / getParentPost() - error: %@", error);
        self.tableView.scrollEnabled = true;
        self.parentPostSpinner.hidden = true;
    }];
}
- (void)setupParentPostScrollIndicator {
    self.parentPostScrollIndicator = [[TappableView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 51 - 12, self.tableView.adjustedContentInset.top - 29 - 12, 61, 39)];
    self.parentPostScrollIndicator.backgroundColor = [[UIColor contentBackgroundColor] colorWithAlphaComponent:0.9];
    self.parentPostScrollIndicator.layer.cornerRadius = self.parentPostScrollIndicator.frame.size.height / 2;
    self.parentPostScrollIndicator.layer.masksToBounds = true;
    [self.parentPostScrollIndicator bk_whenTapped:^{
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    }];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"parentPostScrollIndicator"]];
    imageView.tintColor = [UIColor bonfireSecondaryColor];
    imageView.frame = CGRectMake(self.parentPostScrollIndicator.frame.size.width / 2 - (imageView.image.size.width / 2), self.parentPostScrollIndicator.frame.size.height / 2 - (imageView.image.size.height / 2), imageView.image.size.width, imageView.image.size.height);
    imageView.contentMode = UIViewContentModeCenter;
    imageView.userInteractionEnabled = false;
    [self.parentPostScrollIndicator addSubview:imageView];
    
    self.parentPostScrollIndicator.alpha = 0;
    [self.view addSubview:self.parentPostScrollIndicator];
}
- (void)showParentPostScrollIndicator {
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.parentPostScrollIndicator.frame = CGRectMake(self.parentPostScrollIndicator.frame.origin.x, self.tableView.adjustedContentInset.top + 12 - 6, self.parentPostScrollIndicator.frame.size.width, self.parentPostScrollIndicator.frame.size.height);
        self.parentPostScrollIndicator.alpha = 1;
    } completion:nil];
}
- (void)hideParentPostScrollIndicator {
    [UIView animateWithDuration:0.8f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.parentPostScrollIndicator.frame = CGRectMake(self.parentPostScrollIndicator.frame.origin.x, self.tableView.adjustedContentInset.top - self.parentPostScrollIndicator.frame.size.height - 12, self.parentPostScrollIndicator.frame.size.width, self.parentPostScrollIndicator.frame.size.height);
        self.parentPostScrollIndicator.alpha = 0;
    } completion:nil];
}
- (void)loadPost {
    if (self.post.identifier.length > 0) {
        // fill in post info
        [self.tableView reloadData];
        [self.tableView layoutSubviews];
        
        [self getPost];
        [self loadPostReplies];
    }
    else {
        // post not found
        self.tableView.hidden = true;
        
        self.errorView.hidden = false;
        
        [self.errorView updateType:ErrorViewTypeNotFound title:@"Post Not Found" description:@"We couldn't find the post\nyou were looking for" actionTitle:nil actionBlock:nil];
        
        [self positionErrorView];
        
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.launchNavVC.rightActionView.alpha = 0;
        } completion:^(BOOL finished) {
        }];
    }
}
- (void)getPost {
    [self.tableView reloadData];
    [self.tableView layoutSubviews];
    
    NSString *url = [NSString stringWithFormat:@"posts/%@", self.post.identifier];
    
    NSLog(@"url: %@", url);
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
        
        self.errorView.hidden = true;
                        
        BFContext *contextBefore = self.post.attributes.context;
        
        // first page
        NSError *postError;
        
        self.post = [[Post alloc] initWithDictionary:responseData error:&postError];
        
        if (contextBefore && !self.post.attributes.context) {
            self.post.attributes.context = contextBefore;
        }
        
        // update reply ability using camp
        [self updateComposeInputView];
        
        // update the theme color (in case we didn't know the Camp/Profile color before
        [self updateTheme];
        [self.tableView reloadData];
        
        if([self.tableView isHidden]) {
            [self loadPostReplies];
        }
        
        if ([self hasParentPost]) {
            [self setupParentPostScrollIndicator];
            [self getParentPost];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:self.post];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getCamp() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        
        if (statusCode == 404) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PostDeleted" object:self.post];
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
    }];
}
- (void)loadPostReplies {
    if ([self canViewPost]) {
        [self getRelatedPostsWithNextCursor:nil];
    }
    else {
        [self hideComposeInputView];
        
        self.errorView.hidden = false;
        
        self.loading = false;
        /*self.tableView.loading = false;
        self.tableView.loadingMore = false;*/
        [self.tableView reloadData];
        
        Camp *camp = self.post.attributes.status.postedIn;
        if (camp != nil) {
            !camp.attributes.status.isBlocked && // Camp not blocked
            ![camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_BLOCKED] && // User blocked by Camp
            (!camp.attributes.status.visibility.isPrivate || // (public camp OR
             [camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER]);
            if (camp.attributes.status.isBlocked) { // Camp has been blocked
                [self.errorView updateTitle:@"Post Not Available"];
                [self.errorView updateDescription:@"This post is no longer available"];
                [self.errorView updateType:ErrorViewTypeBlocked];
            }
            else if ([camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_BLOCKED]) { // blocked from Camp
                [self.errorView updateTitle:@"Blocked By Camp"];
                [self.errorView updateDescription:@"Your account is blocked from creating and viewing posts in this Camp"];
                [self.errorView updateType:ErrorViewTypeBlocked];
            }
            else if (camp.attributes.status.visibility.isPrivate) { // not blocked, not member
                // private camp but not a member yet
                [self.errorView updateTitle:@"Private Post"];
                if (camp.attributes.details.title.length > 0) {
                    [self.errorView updateDescription:@"You must be a member to view this post"];
                }
                else {
                    [self.errorView updateDescription:[NSString stringWithFormat:@"Request access to join the %@ Camp to view this post", camp.attributes.details.title]];
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
                    self.launchNavVC.rightActionView.alpha = 0;
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
                self.launchNavVC.rightActionView.alpha = 0;
            } completion:^(BOOL finished) {
            }];
        }
        
        [self positionErrorView];
    }
}
- (void)setupPostHasBeenDeleted {
    self.post = nil;
    self.parentPost = nil;
    [self hideComposeInputView];
    self.launchNavVC.rightActionView.alpha = 0;
    
    self.errorView.hidden = false;
    
    [self.errorView updateType:ErrorViewTypeGeneral title:nil description:@"This post has been deleted" actionTitle:nil actionBlock:nil];
    
    [self positionErrorView];
    
    [self.tableView reloadData];
}
- (void)getRelatedPostsWithNextCursor:(NSString *)nextCursor {
    self.errorView.hidden = true;
    self.tableView.hidden = false;
    
    NSString *url = [NSString stringWithFormat:@"posts/%@/replies", self.post.identifier];

    NSLog(@"📲: %@", url);
    
    NSDictionary *params = nextCursor ? @{@"cursor": nextCursor} : @{};
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // NSLog(@"CommonTableViewController / getReplies() success! ✅");
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
        if (page.data.count > 0) {
            if (!nextCursor) {
                self.stream = [[PostStream alloc] init];
            }
            [self.stream appendPage:page];
        }
        
        self.errorView.hidden = true;
        
        self.loading = false;
        self.loadingMore = false;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self updateContentInsets];
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"FeedViewController / getReplies() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loading = false;
        self.loadingMore = false;
        
        self.tableView.userInteractionEnabled = true;
        [self.tableView reloadData];
    }];
}

#pragma mark - Table view
- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.width, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 70, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.refreshControl = nil;
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.tintColor = self.theme;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    
    [self.tableView registerClass:[StreamPostCell class] forCellReuseIdentifier:parentPostReuseIdentifier];
    [self.tableView registerClass:[ExpandedPostCell class] forCellReuseIdentifier:expandedPostReuseIdentifier];
    [self.tableView registerClass:[StreamPostCell class] forCellReuseIdentifier:postReplyReuseIdentifier];
    [self.tableView registerClass:[ReplyCell class] forCellReuseIdentifier:postSubReplyReuseIdentifier];
    [self.tableView registerClass:[AddReplyCell class] forCellReuseIdentifier:addReplyCellIdentifier];
    
    [self.tableView registerClass:[ExpandThreadCell class] forCellReuseIdentifier:expandRepliesCellIdentifier];
    [self.tableView registerClass:[PaginationCell class] forCellReuseIdentifier:paginationCellIdentifier];
    
    self.stream = [[PostStream alloc] init];
    [self.stream setTempPostPosition:PostStreamOptionTempPostPositionTop];
    
    [self.view addSubview:self.tableView];
    
    self.parentPostSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.parentPostSpinner.color = [UIColor bonfireSecondaryColor];
    self.parentPostSpinner.frame = CGRectMake(self.view.frame.size.width / 2 - (self.parentPostSpinner.frame.size.width / 2), (-1 * self.parentPostSpinner.frame.size.height) - 16, self.parentPostSpinner.frame.size.width, self.parentPostSpinner.frame.size.height);
    self.parentPostSpinner.hidden = true;
    [self.tableView addSubview:self.parentPostSpinner];
}

#pragma mark ↳ Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        // parent post
        return self.parentPost == nil ? 0 : 1;
    }
    else if (section == 1) {
        // expanded post
        BOOL showPost = self.post != nil && self.post.attributes.status.createdAt.length > 0;
        return showPost ? 1 : 0;
    }
    else if (section < self.stream.posts.count + 2) {
        // don't show any replies if there isn't an expanded post yet
        if (self.post == nil || self.post.attributes.status.createdAt.length == 0) return 0;
        
        NSInteger adjustedIndex = section - 2;
        
        Post *reply = self.stream.posts[adjustedIndex];
        CGFloat subReplies = reply.attributes.summaries.replies.count;
        
        // 0   : "hide replies"
        // 1-x : replies
        // x+1 : "view more replies"
        // x+2 : "add a reply..."
        
        BOOL showHideReplies = false;// (subReplies >= reply.attributes.summaries.counts.replies) && reply.attributes.summaries.counts.replies > 2;
        BOOL showViewMore = (subReplies < reply.attributes.summaries.counts.replies);
        BOOL showAddReply = reply.attributes.summaries.replies.count > 0;
        
        NSInteger rows = 1 + (showHideReplies ? 1 : 0) + subReplies + (showViewMore ? 1 : 0) + (showAddReply ? 1 : 0);
        
        return rows;
    }
    else if (section == self.stream.posts.count + 2) {
        // assume it's a pagination cell
        return 1;
    }
    
    return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // parent post
        StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:parentPostReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:parentPostReuseIdentifier];
        }
        
        NSString *identifierBefore = cell.post.identifier;
        
        cell.showContext = true;
        cell.showCamptag = true;
        cell.hideActions = false;
        cell.post = self.parentPost;
        
        if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
            [self didBeginDisplayingCell:cell];
        }
        
        if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
            [cell.actionsView.replyButton bk_whenTapped:^{
                [Launcher openComposePost:cell.post.attributes.status.postedIn inReplyTo:cell.post withMessage:nil media:nil];
            }];
        }
        
        cell.lineSeparator.hidden = false;
        
        return cell;
    }
    else if (indexPath.section == 1 && self.post.attributes.status.createdAt.length > 0) {
        // expanded post
        ExpandedPostCell *cell = [tableView dequeueReusableCellWithIdentifier:expandedPostReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ExpandedPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandedPostReuseIdentifier];
        }
        
        cell.tintColor = self.theme;
        cell.loading = self.loading;
        
        cell.post = self.post;
        
        if (cell.actionsView.replyButton.gestureRecognizers == 0) {
            [cell.actionsView.replyButton bk_whenTapped:^{
                //[self.composeInputView.textView becomeFirstResponder];
                [Launcher openComposePost:self.post.attributes.status.postedIn inReplyTo:self.post withMessage:self.composeInputView.textView.text media:nil];
            }];
        }
        
        if (!cell.loading) {
            if ((int)[cell.activityView currentViewTag] == (int)PostActivityViewTagAddReply && self.stream.posts.count > 0) {
                [cell.activityView next];
            }
            else if (!cell.activityView.active) {
                [cell.activityView start];
            }
        }
        
        cell.actionsView.replyButton.alpha = [self canReply] || cell.loading ? 1 : 0.5;
        cell.actionsView.replyButton.userInteractionEnabled = [self canReply];
                
        return cell;
    }
    else if (indexPath.section < (self.stream.posts.count + 2)) { // offset by 1 due to expanded post on the top
        NSInteger adjustedIndex = indexPath.section - 2;
        
        // determine if it's a reply or sub-reply
        Post *reply = self.stream.posts[adjustedIndex];
        CGFloat subReplies = reply.attributes.summaries.replies.count;
        // 0       : actual reply
        // 1       : --- "hide replies"
        // 2-(x+1) : --- replies
        // (x+1)+1 : --- "view more replies"
        // (x+1)+2 : --- "add a reply..."
        
        BOOL showViewMore = (subReplies < reply.attributes.summaries.counts.replies);
        BOOL showAddReply = reply.attributes.summaries.replies.count > 0;
        
        NSInteger firstSubReplyIndex = 1;
        
        if (indexPath.row == 0) {
            StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:postReplyReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postReplyReuseIdentifier];
            }
            
            NSString *identifierBefore = cell.post.identifier;
            
            cell.showContext = false;
            cell.showCamptag = false;
            cell.post = reply;
            
            [cell.actionsView setSummaries:reply.attributes.summaries];
            
            if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                [self didBeginDisplayingCell:cell];
            }
            
            if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
                [cell.actionsView.replyButton bk_whenTapped:^{
                    [self.composeInputView setReplyingTo:cell.post];
                    [self.composeInputView.textView setText:[NSString stringWithFormat:@"@%@ ", cell.post.attributes.details.creator.attributes.details.identifier]];
                    [self.composeInputView.textView becomeFirstResponder];
                    
                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                }];
            }
            
            cell.lineSeparator.hidden = reply.attributes.summaries.replies.count > 0 || showViewMore || showAddReply;
            
            return cell;
        }
        else if ((indexPath.row - firstSubReplyIndex) <  reply.attributes.summaries.replies.count) {
            NSInteger subReplyIndex = indexPath.row - firstSubReplyIndex;
            
            // reply
            ReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:postSubReplyReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postSubReplyReuseIdentifier];
            }
            
            NSString *identifierBefore = cell.post.identifier;
            
            Post *subReply = reply.attributes.summaries.replies[subReplyIndex];
            cell.post = subReply;
            
            if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                [self didBeginDisplayingCell:cell];
            }
            
//            if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
//                [cell.actionsView.replyButton bk_whenTapped:^{
//                    [self.composeInputView setReplyingTo:reply];
//                    [self.composeInputView.replyingToLabel setTitle:[NSString stringWithFormat:@"Replying to @%@", cell.post.attributes.details.creator.attributes.details.identifier] forState:UIControlStateNormal];
//                    [self.composeInputView.textView setText:[NSString stringWithFormat:@"@%@ ", cell.post.attributes.details.creator.attributes.details.identifier]];
//                    [self.composeInputView.textView becomeFirstResponder];
//                    
//                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//                    
//                    // [Launcher openPost:cell.post withKeyboard:YES];
//                }];
//            }
            
            cell.topCell = (subReplyIndex == 0);
            cell.bottomCell = (indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex - 1) && !showViewMore && !showAddReply;
            
            cell.lineSeparator.hidden = !cell.bottomCell;
            
            cell.selectable = YES;
            
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
            cell.textLabel.textColor = [UIColor bonfirePrimaryColor];
            
            if (hasExistingSubReplies) {
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
        else if (showAddReply && indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex + (showViewMore ? 1 : 0)) {
            // "add a reply"
            AddReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:addReplyCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[AddReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addReplyCellIdentifier];
            }
            
            NSString *username = reply.attributes.details.creator.attributes.details.identifier;
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Reply to @%@...", username] attributes:@{NSFontAttributeName: cell.addReplyLabel.font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
            [attributedString setAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:cell.addReplyLabel.font.pointSize weight:UIFontWeightSemibold]} range:[attributedString.string rangeOfString:[NSString stringWithFormat:@"@%@", username]]];
            cell.addReplyLabel.attributedText = attributedString;
            
            return cell;
        }
    }
    else if (indexPath.section == self.stream.posts.count + 2) {
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
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    BOOL hasAnotherPage = self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.nextCursor != nil && [self.stream.pages lastObject].meta.paging.nextCursor.length > 0;
    return  1 + // parent post
            1 + // expanded post
            (self.loading ? 1 : self.stream.posts.count + (hasAnotherPage ? 1 : 0)); // replies
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        if (self.parentPost) {
            return [StreamPostCell heightForPost:self.parentPost showContext:true showActions:true];
        }
        
        // loading ...
        return 0;
    }
    else if (indexPath.section == 1 && indexPath.row == 0 && self.post.attributes.status.createdAt.length > 0) {
        // expanded post
        // returns 0 if incomplete (occurs when loading from identifier)
        return [ExpandedPostCell heightForPost:self.post width:[UIScreen mainScreen].bounds.size.width];
    }
    else if (indexPath.section - 2 < self.stream.posts.count) {
        Post *reply = self.stream.posts[indexPath.section-2];
        CGFloat subReplies = reply.attributes.summaries.replies.count;
        // 0       : actual reply
        // 1       : --- "hide replies"
        // 2-(x+1) : --- replies
        // (x+1)+1 : --- "view more replies"
        // (x+1)+2 : --- "add a reply..."
        
        BOOL showViewMore = (subReplies < reply.attributes.summaries.counts.replies);
        BOOL showAddReply = reply.attributes.summaries.replies.count > 0;
        
        NSInteger firstSubReplyIndex = 1;
        
        if (indexPath.row == 0) {
            // BOOL showActions = (reply.attributes.summaries.replies.count == 0);
            return [StreamPostCell heightForPost:reply showContext:false showActions:true];
        }
        else if ((indexPath.row - firstSubReplyIndex) <  reply.attributes.summaries.replies.count) {
            NSInteger subReplyIndex = indexPath.row - firstSubReplyIndex;
            Post *subReply = reply.attributes.summaries.replies[subReplyIndex];
            return [ReplyCell heightForPost:subReply];
        }
        else if (showViewMore && indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex) {
            // "view more replies"
            return CONVERSATION_EXPAND_CELL_HEIGHT;
        }
        else if (showAddReply && indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex + (showViewMore ? 1 : 0)) {
            // "add a reply"
            return [AddReplyCell height];
        }
    }
    else if (indexPath.section - 2 == self.stream.posts.count) {
        return 52;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (section == 0) ? (1 / [UIScreen mainScreen].scale) : CGFLOAT_MIN;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        separator.backgroundColor = [UIColor tableViewSeparatorColor];
        return separator;
    }
    return [[UIView alloc] initWithFrame:CGRectZero];
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Post *post;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[ExpandedPostCell class]]) return;
    
    if ([cell isKindOfClass:[StreamPostCell class]] || [cell isKindOfClass:[ReplyCell class]]) {
        if (!((PostCell *)cell).post) return;
        
        post = ((PostCell *)cell).post;
    }
    if ([cell isKindOfClass:[ExpandThreadCell class]]) {
        post = self.stream.posts[indexPath.section-2];
    }
    if ([cell isKindOfClass:[AddReplyCell class]]) {
        Post *postReplyingTo = self.stream.posts[indexPath.section-2];
        
        [self.composeInputView setReplyingTo:postReplyingTo];
        [self.composeInputView.textView becomeFirstResponder];
        
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if([cell isKindOfClass:[PaginationCell class]]) {
        if (!self.loadingMore && self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.nextCursor != nil && [self.stream.pages lastObject].meta.paging.nextCursor.length > 0) {
            self.loadingMore = true;
            [self getRelatedPostsWithNextCursor:[self.stream.pages lastObject].meta.paging.nextCursor];
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
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.tableView) {
        if (self.parentPost && self.parentPostScrollIndicator.alpha == 1) {
            CGFloat contentOffset = scrollView.contentOffset.y;
            CGFloat postHeight = [StreamPostCell heightForPost:self.parentPost showContext:true showActions:true];
            CGFloat hideLine = postHeight - self.tableView.adjustedContentInset.top;
            
            if (contentOffset < postHeight - self.tableView.adjustedContentInset.top) {
                [self hideParentPostScrollIndicator];
            }
            else {
                // scroll with the content
                CGFloat amountBeyondHideLine = contentOffset - hideLine;
                self.parentPostScrollIndicator.transform = CGAffineTransformMakeTranslation(0, -amountBeyondHideLine);
            }
        }
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return textView.text.length + (text.length - range.length) <= [Session sharedInstance].defaults.post.maxLength.soft;
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

#pragma mark - Compose input view
- (void)setupComposeInputView {
    self.composeInputView = [[ComposeInputView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 52, self.view.frame.size.width, 190)];
    self.composeInputView.delegate = self;
    self.composeInputView.parentViewController = self;
    self.composeInputView.media.maxImages = 1;
    self.composeInputView.textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [self.composeInputView bk_whenTapped:^{
        if (![self.composeInputView isActive]) {
            [self.composeInputView setActive:true];
        }
    }];
    [self.composeInputView.postButton bk_whenTapped:^{
        [self postMessage];
    }];
    [self.composeInputView.expandButton bk_whenTapped:^{
        [Launcher openComposePost:self.post.attributes.status.postedIn inReplyTo:self.post withMessage:self.composeInputView.textView.text media:@[]];
    }];
    [self.composeInputView.replyingToLabel bk_whenTapped:^{
        // scroll to post you're replying to
        NSArray<Post *> *posts = self.stream.posts;
        for (NSInteger i = 0; i < posts.count; i++) {
            if (posts[i].identifier == self.composeInputView.replyingTo.identifier) {
                // scroll to this item!
                NSIndexPath* ipath = [NSIndexPath indexPathForRow:0 inSection:i+1];
                [self.tableView scrollToRowAtIndexPath:ipath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                
                break;
            }
        }
        
        [self updateContentInsets];
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.tintColor = [self.theme isEqual:[UIColor whiteColor]] ? [UIColor bonfirePrimaryColor] : self.theme;
    self.composeInputView.postButton.backgroundColor = self.composeInputView.tintColor;
    self.composeInputView.addMediaButton.tintColor = self.composeInputView.tintColor;
    
    // self.tableView.inputView = self.composeInputView;
}

- (void)postMessage {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *message = self.composeInputView.textView.text;
    if (message.length > 0) {
        [params setObject:[Post trimString:message] forKey:@"message"];
    }
    if (self.composeInputView.media.objects.count > 0) {
        [params setObject:self.composeInputView.media forKey:@"media"];
    }
    
    if ([params objectForKey:@"message"] || [params objectForKey:@"media"]) {
        // meets min. requirements
        Post *replyingTo = (self.composeInputView.replyingTo != nil) ? self.composeInputView.replyingTo : self.post;
        if (self.post.attributes.status.postedIn) {
            [BFAPI createPost:params postingIn:self.post.attributes.status.postedIn replyingTo:replyingTo];
        }
        else {
            [BFAPI createPost:params postingIn:nil replyingTo:replyingTo];
        }
        
        [self.composeInputView reset];
    }
}
- (void)updateComposeInputView {
    Camp *camp = self.post.attributes.status.postedIn;
    
    if (camp) {
        [self.composeInputView setMediaTypes:camp.attributes.context.camp.permissions.reply];
    }
    else {
        [self.composeInputView setMediaTypes:@[BFMediaTypeText, BFMediaTypeImage, BFMediaTypeGIF]];
    }

    if ([self canReply]) {
        [self showComposeInputView];
        [self.composeInputView updatePlaceholders];
    }
    else {
        [self hideComposeInputView];
    }
}
- (BOOL)canReply {
    return [self.post.attributes.context.post.permissions canReply];
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

#pragma mark - Message Compose View Controller Delegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Misc.
- (void)updateTheme {
    UIColor *theme;
    
    BOOL postedInCamp = self.post.attributes.status.postedIn != nil;
    if (postedInCamp) {
        theme = [UIColor fromHex:self.post.attributes.status.postedIn.attributes.details.color];
    }
    else {
        theme = [UIColor fromHex:self.post.attributes.details.creator.attributes.details.color];
    }
    if (self.launchNavVC.topViewController == self) {
        [self.launchNavVC updateBarColor:theme animated:true];
    }
    
    NSLog(@"updateTheme:: %@", [UIColor toHex:theme]);
    
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
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100)];
    [self.errorView updateType:ErrorViewTypeNotFound title:@"Error loading replies" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
        NSError *postError;
        self.post = [[Post alloc] initWithDictionary:[self.post toDictionary] error:&postError];
        
        if (postError || // camp has error OR
            [self canViewPost]) { // no error and can view posts
            self.errorView.hidden = true;
            
            [self loadPost];
            [self loadPostReplies];
        }
    }];
    [self positionErrorView];
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}
- (void)setupShareUpsellView {
    self.shareUpsellView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    self.shareUpsellView.frame = CGRectMake(0, self.composeInputView.frame.origin.y - 62, self.view.frame.size.width, 62);
    self.shareUpsellView.backgroundColor = [self.tableView.backgroundColor colorWithAlphaComponent:0.8];
    self.shareUpsellView.layer.masksToBounds = false;
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    [self.shareUpsellView.contentView addSubview:lineSeparator];
    
    UILabel *shareThisPost = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, 140, self.shareUpsellView.frame.size.height)];
    shareThisPost.text = @"Share this Post";
    shareThisPost.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
    shareThisPost.textColor = [UIColor bonfirePrimaryColor];
    [self.shareUpsellView.contentView addSubview:shareThisPost];
    
    [self.view insertSubview:self.shareUpsellView belowSubview:self.composeInputView];
}
- (BOOL)canViewPost {
    Camp *camp = self.post.attributes.status.postedIn;
    if (camp) {
        BOOL canViewPost = camp.identifier != nil && // has an ID
        !camp.attributes.status.isBlocked && // Camp not blocked
        ![camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_BLOCKED];
        
        return canViewPost;
    }
    else {
        return true;
    }
    
    return false;
}
- (void)positionErrorView {
    ExpandedPostCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat heightOfHeader = headerCell.frame.size.height;
    self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 48, self.errorView.frame.size.width, self.errorView.frame.size.height);
}
- (void)updateContentInsets {
    CGFloat topPadding = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    CGFloat bottomPadding = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    
    CGFloat newComposeInputViewY = (self.currentKeyboardHeight > 0 ? self.composeInputView.frame.origin.y + topPadding : self.view.frame.size.height - self.composeInputView.frame.size.height +   bottomPadding);
    
    CGFloat parentPostOffset = 0;
    
    if (self.parentPost) {
        BOOL requiresParentPostPadding = true; //(self.tableView.contentSize.height < self.tableView.frame.size.height - self.tableView.adjustedContentInset.top - self.tableView.adjustedContentInset.bottom);
        
        CGFloat parentPostHeight = [StreamPostCell heightForPost:self.parentPost showContext:true showActions:true];
        CGFloat expandedPostHeight = [ExpandedPostCell heightForPost:self.post width:[UIScreen mainScreen].bounds.size.width];
        CGFloat repliesHeight = self.tableView.contentSize.height - parentPostHeight - expandedPostHeight;
        
        // NSLog(@"requiresParentPostPadding: %@", requiresParentPostPadding ? @"YES" : @"NO");
        parentPostOffset = requiresParentPostPadding ? (self.composeInputView.frame.origin.y - expandedPostHeight - repliesHeight - self.tableView.adjustedContentInset.top) : 0;
        parentPostOffset = (parentPostOffset > 0 ? parentPostOffset : 0);
    }
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.view.frame.size.height - newComposeInputViewY + (self.composeInputView.replyingTo != nil ? self.composeInputView.replyingToLabel.frame.size.height : 0) + parentPostOffset + (![self.shareUpsellView isHidden] ? self.shareUpsellView.frame.size.height : 0), 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.height - newComposeInputViewY + (self.composeInputView.replyingTo != nil ? self.composeInputView.replyingToLabel.frame.size.height : 0) + (![self.shareUpsellView isHidden] ? self.shareUpsellView.frame.size.height : 0), 0);
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
        
        //[self buildConversation];
    }
}

- (void)setParentPost:(Post *)parentPost {
    if (parentPost != _parentPost) {
        _parentPost = parentPost;
        
        //[self buildConversation];
    }
}

- (void)buildConversation {
    NSMutableArray *conversation = [NSMutableArray array];
    
    NSMutableArray *posts = [NSMutableArray array];
    if (self.parentPost) {
        [posts addObject:self.parentPost];
    }
    if (self.post) {
        [posts addObject:self.post];
    }
    
//    for (Post *post in posts) {
//        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
//
//        NSDate *datePosted = [formatter dateFromString:post.attributes.status.createdAt];
////        FIRTextMessage *message = [[FIRTextMessage alloc]
////                                   initWithText:post.attributes.details.simpleMessage
////                                   timestamp:datePosted.timeIntervalSince1970
////                                   userID:post.attributes.details.creator.identifier
////                                   isLocalUser:[post.attributes.details.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]];
////        [conversation addObject:message];
//    }
    
    self.conversation = conversation;
    
    [self determineAutoReplies];
}

- (void)determineAutoReplies {
//    if ([self.conversation count] == 0) return;
//
//    FIRNaturalLanguage *naturalLanguage = [FIRNaturalLanguage naturalLanguage];
//    FIRSmartReply *smartReply = [naturalLanguage smartReply];
//    [smartReply suggestRepliesForMessages:self.conversation completion:^(FIRSmartReplySuggestionResult * _Nullable result, NSError * _Nullable error) {
//        if (error || !result) {
//           return;
//        }
//        if (result.status == FIRSmartReplyResultStatusNotSupportedLanguage) {
//           // The conversation's language isn't supported, so the
//           // the result doesn't contain any suggestions.
//        } else if (result.status == FIRSmartReplyResultStatusSuccess) {
//           // Successfully suggested smart replies.
//           for (FIRSmartReplySuggestion *suggestion in result.suggestions) {
//               NSLog(@"Suggested reply: %@", suggestion.text);
//           }
//        }
//    }];
}

@end
