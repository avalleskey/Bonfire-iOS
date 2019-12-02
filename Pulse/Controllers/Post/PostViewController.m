//
//  PostViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "PostViewController.h"
#import "UINavigationItem+Margin.h"
#import "SimpleNavigationController.h"
#import "BFVisualErrorView.h"
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
#import "BFHeaderView.h"
#import "BFErrorViewCell.h"
@import Firebase;

@interface PostViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL loadingParentPosts;
@property (nonatomic) BOOL loadingReplies;
@property (nonatomic) BOOL loadingMore;

@property (nonatomic, strong) BFVisualError *visualError;
@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property (nonatomic, strong) SimpleNavigationController *launchNavVC;
@property (nonatomic, assign) NSMutableArray *conversation;
@property (nonatomic, strong) NSArray<Post *> *parentPosts;
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
static NSString * const errorViewCellIdentifier = @"errorViewCell";

static NSString * const paginationCellIdentifier = @"PaginationCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.launchNavVC = (SimpleNavigationController *)self.navigationController;
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
    NSString *themeCSS;
    if (self.post.attributes.postedIn != nil) {
        themeCSS = [self.post.attributes.postedIn.attributes.color lowercaseString];
    }
    else {
        themeCSS = [self.post.attributes.creator.attributes.color lowercaseString];
    }
    self.theme = [UIColor fromHex:themeCSS];
    
    [self setupTableView];
        
    if (self.post.identifier) {
        if (!self.isPreview) {
            [self setupComposeInputView];
        }
        
        if (![self canReply]) {
            self.composeInputView.hidden = true;
            [self hideComposeInputView];
        }
        
        if ([self hasParentPost]) {
            self.launchNavVC.onScrollLowerBound = -1;
            [self.launchNavVC childTableViewDidScroll:self.tableView];
        }
        
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

    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [self loadPost];
        [self styleOnAppear];
        
        if (self.isPreview) {
            self.composeInputView.hidden = true;
            [self hideComposeInputView];
        }
        
        if (![self.composeInputView isHidden]) {
            [self updateComposeInputViewFrame];
        }
    }
    else {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInCampView];
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
    
    if (self.showKeyboardOnOpen) {
        self.showKeyboardOnOpen = false;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.composeInputView.textView becomeFirstResponder];
        });
    }
}
- (void)styleOnAppear {
    self.tableView.frame = self.view.bounds;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
                
    self.shareUpsellView.frame = CGRectMake(self.shareUpsellView.frame.origin.x, self.composeInputView.frame.origin.y - self.shareUpsellView.frame.size.height, self.shareUpsellView.frame.size.width, self.shareUpsellView.frame.size.height);
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding + (![self.shareUpsellView isHidden] ? self.shareUpsellView.frame.size.height : 0), 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding + (![self.shareUpsellView isHidden] ? self.shareUpsellView.frame.size.height : 0), 0);
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.tableView];
    
    [self keyboardWillDismiss:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
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

- (void)updateComposeInputViewFrame {
    CGAffineTransform transformBefore = self.composeInputView.transform;
    self.composeInputView.transform = CGAffineTransformIdentity;
    
    CGFloat bottomPadding = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    
    CGFloat newComposeInputViewY = self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + ([self.composeInputView.textView isFirstResponder] ? bottomPadding : 0);
            
    self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, newComposeInputViewY, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    
    self.composeInputView.transform = transformBefore;
}

#pragma mark - NSNotificationCenter observers
#pragma mark ↳ Keyboard observers
- (void)keyboardWillShow:(NSNotification *)notification {
//    CGFloat parentPostHeight = [StreamPostCell heightForPost:self.parentPost showContext:true showActions:true];
//    [self.tableView setContentOffset:CGPointMake(0, parentPostHeight) animated:YES];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:true];
}
- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    _currentKeyboardFrame = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = _currentKeyboardFrame.size.height;
    
    [self updateComposeInputViewFrame];
    self.shareUpsellView.frame = CGRectMake(self.shareUpsellView.frame.origin.x, self.composeInputView.frame.origin.y - self.shareUpsellView.frame.size.height, self.shareUpsellView.frame.size.width, self.shareUpsellView.frame.size.height);
    
    [self updateContentInsets];
}
- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = (notification ? [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] : @(0.4));
    
    CGFloat newComposeInputViewY = self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height;
    
    [UIView animateWithDuration:[duration floatValue] delay:0 options:(notification ? [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 : UIViewAnimationOptionCurveEaseOut) animations:^{
        [self.composeInputView resize:false];
                        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, newComposeInputViewY, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
        
        [self updateContentInsets];
    } completion:^(BOOL finished) {
        //[self updateContentInsets];
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
        }
    }
}
- (void)postDeleted:(NSNotification *)notification {
    if (![notification.object isKindOfClass:[Post class]]) return;
    
    Post *post = (Post *)notification.object;
    
    BOOL refresh = false;
    if (post && [post.identifier isEqualToString:self.post.identifier]) {
        self.post = post;
        refresh = true;
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        Post *postInStream = [self.stream postWithId:post.identifier];
        if (postInStream) {
            [self.stream removePost:post];
            refresh = true;
        }
    }
    
    if (refresh) {
        [self.tableView reloadData];
    }
}
- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && tempPost.attributes.parent) {
        if ([tempPost.attributes.parent.identifier isEqualToString:self.post.identifier]) {
            // parent post
            self.visualError = nil;
            
            [self.stream addTempPost:tempPost];
            
            if (self.post.attributes.summaries.counts.replies == 0) {
                self.post.attributes.summaries.counts.replies++;
            }
            
            [self.tableView reloadData];
            
            [self updateContentInsets];
        }
        else {
            // could be a reply to a reply? let's check.
            [self.stream addTempSubReply:tempPost];

            [self.tableView reloadData];
            [self.tableView layoutIfNeeded];
            [self updateContentInsets];
        }
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSLog(@"☑️ newPostCompleted");
    
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
        
    if (post != nil && post.attributes.parent) {
        if ([post.attributes.parent.identifier isEqualToString:self.post.identifier]) {
            // reply
            self.visualError = nil;
            
            if ([self.stream postWithId:post.identifier]) {
                [self.stream removePost:post];
            }
            [self.stream updateTempPost:tempId withFinalPost:post];
            
            [UIView animateWithDuration:0 animations:^{
                [self.tableView reloadData];
                [self.tableView layoutIfNeeded];
                [self updateContentInsets];
            } completion:^(BOOL finished) {
//                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }];
        }
        else {
            // could be a reply to a reply? let's attempt
            if ([self.stream postWithId:post.identifier]) {
                [self.stream removePost:post];
            }
            
            [self.stream updateTempSubReply:tempId withFinalSubReply:post];
            
            [UIView animateWithDuration:0 animations:^{
                [self.tableView reloadData];
                [self.tableView layoutIfNeeded];
                [self updateContentInsets];
            } completion:nil];
        }
    }
}
- (void)newPostFailed:(NSNotification *)notification {
    // TODO: Allow tap to retry for posts
    Post *tempPost = notification.object;
    
    if (tempPost != nil && [tempPost.attributes.parent.identifier isEqualToString:self.post.identifier]) {
        // TODO: Check for image as well
        [self.stream removeTempPost:tempPost.tempId];
        
        [self.tableView reloadData];
    }
}

#pragma mark - Load post
- (BOOL)hasParentPost {
    return self.post.attributes.parent || self.post.attributes.thread.prevCursor.length > 0;
}
- (void)setupParentPostScrollIndicator {
    self.parentPostScrollIndicator = [[TappableView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 51 - 12, self.tableView.adjustedContentInset.top - 29 - 12, 61, 39)];
    self.parentPostScrollIndicator.backgroundColor = [[UIColor bonfireDetailColor] colorWithAlphaComponent:0.9];
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
        self.visualError  = nil;
        
        // fill in post info
        [self.tableView reloadData];
        [self.tableView layoutSubviews];
        
        [self getPost];
        
        [self loadPostReplies];
    }
    else {
        self.visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Post Not Found" description:@"We couldn't find the post\nyou were looking for" actionTitle:nil actionBlock:nil];
        
        [self.tableView reloadData];
        
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
                                
        BFContext *contextBefore = self.post.attributes.context;
        
        // first page
        NSError *postError;
        
        self.post = [[Post alloc] initWithDictionary:responseData error:&postError];
        
        NSLog(@"post error?? %@", postError);
        
        if (contextBefore && ![self.post isRemoved] && !self.post.attributes.context) {
            self.post.attributes.context = contextBefore;
        }
        
        // update reply ability using camp
        [self updateComposeInputView];
        
        // update the theme color (in case we didn't know the Camp/Profile color before
        [self updateTheme];
        
        self.visualError = nil;
        [self.tableView reloadData];
        
        if([self.tableView isHidden]) {
            [self loadPostReplies];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.tableView layoutIfNeeded];
            [self updateContentInsets];
        });
        
        if ([self hasParentPost] && !self.isPreview) {
            [self setupParentPostScrollIndicator];
            [self getParentPosts];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:self.post];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getCamp() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        
        [self hideComposeInputView];
        if (statusCode == 404) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PostDeleted" object:self.post];
        }
        else if (!self.post.attributes && self.parentPosts.count == 0 && self.stream.posts.count == 0) {
            self.visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Error Loading Post" description:@"Check your network settings and try again" actionTitle:nil actionBlock:nil];
        }
        
        self.loading = false;
        [self.tableView reloadData];
        
        self.launchNavVC.onScrollLowerBound = 12;
    }];
}
- (void)getParentPosts {
    if (![self hasParentPost]) {
        return;
    }
    
    self.launchNavVC.onScrollLowerBound = 12;
    
    // call this in order to handle the scroll down effect
    void (^reloadWithParentPosts)(void) = ^void() {
        // force on the main thread to make sure it updates without lag
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.tableView layoutIfNeeded];
//            [self updateContentInsets];
            
            if (self.tableView.contentOffset.y == -(self.tableView.adjustedContentInset.top)) {
                [self.tableView setContentOffset:CGPointMake(0, [self parentPostsHeight] - self.tableView.adjustedContentInset.top)];
                self.parentPostScrollIndicator.transform = CGAffineTransformMakeTranslation(0, 0);
            }
            
            [self updateContentInsets];
            
            self.tableView.scrollEnabled = true;
                       
           [self showParentPostScrollIndicator];
        });
    };
    
    if (self.post.attributes.thread.prevCursor.length > 0) {
        NSString *identifier = self.post.identifier;
        NSString *cursor = self.post.attributes.thread.prevCursor;
        
        BOOL useParentPostPrevCursor = self.post.attributes.parent && self.post.attributes.parent.attributes.thread.prevCursor;
        if (useParentPostPrevCursor) {
            identifier = self.post.attributes.parent.identifier;
            cursor = self.post.attributes.parent.attributes.thread.prevCursor;
        }
        
        NSString *url = [NSString stringWithFormat:@"posts/%@/thread", identifier];
        
        NSLog(@"url: %@", url);
        
        [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:@{@"cursor": cursor} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSMutableArray *responseData = [[NSMutableArray alloc] initWithArray:(NSArray *)responseObject[@"data"]];
            
            if ([responseData isKindOfClass:[NSArray class]] && responseData.count > 0) {
                // convert NSDictionary objects to Post objects (if able)
                [responseData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        Post *post = [[Post alloc] initWithDictionary:obj error:nil];
                        [responseData replaceObjectAtIndex:idx withObject:post];
                    }
                    else {
                        [responseData removeObject:obj];
                    }
                }];
                
                if (useParentPostPrevCursor) {
                    self.parentPosts = [@[self.post.attributes.parent] arrayByAddingObjectsFromArray:responseData];
                }
                else {
                    self.parentPosts = responseData;
                }
            }
            else {
                self.parentPosts = @[];
            }
            
            reloadWithParentPosts();
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"CampViewController / getCamp() - error: %@", error);
            
        }];
    }
    else {
        self.parentPosts = @[self.post.attributes.parent];
        
        reloadWithParentPosts();
    }
}
- (void)loadPostReplies {
    if ([self canViewPost]) {
        [self getRelatedPostsWithNextCursor:nil];
    }
    else {
        [self hideComposeInputView];
        
        ErrorViewType errorType = ErrorViewTypeGeneral;
        NSString *errorTitle = @"";
        NSString *errorDescription = @"";
        
        Camp *camp = self.post.attributes.postedIn;
        if (camp != nil) {
            if ([camp.attributes isSuspended] ||
                [camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_BLOCKED]) { // Camp has been blocked
                errorType = ErrorViewTypeBlocked;
                errorTitle = @"Post Not Available";
                errorDescription = @"This post is no longer available";
            }
            else if ([camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_BLOCKED]) { // blocked from Camp
                errorType = ErrorViewTypeBlocked;
                errorTitle = @"Blocked By Camp";
                errorDescription = @"Your account is blocked from creating and viewing posts in this Camp";
            }
            else if ([camp isPrivate]) { // not blocked, not member
                // private camp but not a member yet
                errorType = ErrorViewTypeLocked;
                errorTitle = @"Private Post";
                if (camp.attributes.title.length > 0) {
                    errorDescription = @"You must be a member to view this post";
                }
                else {
                    errorDescription = [NSString stringWithFormat:@"Request access to join the %@ Camp to view this post", camp.attributes.title];
                }
            }
            else {
                errorType = ErrorViewTypeNotFound;
                errorTitle = @"Post Not Found";
                errorDescription = @"We couldn’t find the post\nyou were looking for";
                
                [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.launchNavVC.rightActionView.alpha = 0;
                } completion:^(BOOL finished) {
                }];
            }
        }
        else {
            errorType = ErrorViewTypeNotFound;
            errorTitle = @"Post Not Found";
            errorDescription = @"We couldn’t find the post\nyou were looking for";
            
            [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.launchNavVC.rightActionView.alpha = 0;
            } completion:^(BOOL finished) {
            }];
        }
        
        // update error view
        self.loading = false;
        self.visualError = [BFVisualError visualErrorOfType:errorType title:errorTitle description:errorDescription actionTitle:nil actionBlock:nil];
        [self.tableView reloadData];
    }
}
- (void)setupPostHasBeenDeleted {
    self.post = nil;
    self.parentPosts = @[];
    [self hideComposeInputView];
    self.parentPostScrollIndicator.hidden = true;
    
    self.visualError = [BFVisualError visualErrorOfType:ErrorViewTypeGeneral title:nil description:@"This post has been deleted" actionTitle:nil actionBlock:nil];
    [self.tableView reloadData];
}
- (void)getRelatedPostsWithNextCursor:(NSString *)nextCursor {
    self.visualError = nil;
    [self.tableView reloadData];
    
    NSString *url = [NSString stringWithFormat:@"posts/%@/replies", self.post.identifier];
    if (!self.post.identifier || self.post.identifier.length == 0) {
        return;
    }

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
        
        self.visualError = nil;
        
        self.loading = false;
        self.loadingMore = false;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.tableView layoutIfNeeded];
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
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
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
    
    [self.tableView registerClass:[BFErrorViewCell class] forCellReuseIdentifier:errorViewCellIdentifier];
    
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
        return self.parentPosts.count;
    }
    else if (section == 1) {
        // expanded post
        BOOL showPost = self.post != nil &&
                        (self.post.attributes.createdAt.length > 0 ||
                         self.post.attributes.removedAt.length > 0);
        return showPost ? 1 : 0;
    }
    else if (section >= 2 && section < self.stream.posts.count + 2) {
        // don't show any replies if there isn't an expanded post yet
        if (self.post == nil || (self.post.attributes.createdAt.length == 0 && self.post.attributes.removedAt.length == 0)) return 0;
        
        NSInteger adjustedIndex = section - 2;
        
        Post *reply = self.stream.posts[adjustedIndex];
        CGFloat subReplies = reply.attributes.summaries.replies.count;
        
        // 0   : "hide replies"
        // 1-x : replies
        // x+1 : "view more replies"
        // x+2 : "add a reply..."
        
        BOOL showHideReplies = false;// (subReplies >= reply.attributes.summaries.counts.replies) && reply.attributes.summaries.counts.replies > 2;
        BOOL showViewMore = false;//(subReplies < reply.attributes.summaries.counts.replies);
        BOOL showAddReply = reply.attributes.summaries.replies.count > 0;
        
        NSInteger rows = 1 + (showHideReplies ? 1 : 0) + subReplies + (showViewMore ? 1 : 0) + (showAddReply ? 1 : 0);
        
        return rows;
    }
    else if (section == self.stream.posts.count + 2) {
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
        if (self.parentPosts.count > indexPath.row) {
            cell.post = self.parentPosts[indexPath.row];
        }
        
        if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
            [self didBeginDisplayingCell:cell];
        }
        
        cell.tag = indexPath.row;
        if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
            [cell.actionsView.replyButton bk_whenTapped:^{
                if (self.parentPosts.count > cell.tag) {
                    [Launcher openComposePost:self.post.attributes.postedIn inReplyTo:self.parentPosts[cell.tag] withMessage:nil media:nil quotedObject:nil];
                }
            }];
        }
        
        cell.lineSeparator.hidden = true;
        cell.bottomLine.hidden = false;
        cell.topLine.hidden = indexPath.row == 0;
        
        return cell;
    }
    else if (indexPath.section == 1) {
        // expanded post
        ExpandedPostCell *cell = [tableView dequeueReusableCellWithIdentifier:expandedPostReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ExpandedPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandedPostReuseIdentifier];
        }
        
        cell.tintColor = self.theme;
        cell.loading = self.loading;
        
        cell.post = self.post;
        
        if (![cell.post isRemoved]) {
            if (cell.actionsView.replyButton.gestureRecognizers == 0) {
                [cell.actionsView.replyButton bk_whenTapped:^{
                    //[self.composeInputView.textView becomeFirstResponder];
                    [Launcher openComposePost:self.post.attributes.postedIn inReplyTo:self.post withMessage:self.composeInputView.textView.text media:nil quotedObject:nil];
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

            if (cell.actionsView.alpha == 0.5 && !self.loading) {
                [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    cell.actionsView.alpha = 1;
                    cell.actionsView.replyButton.alpha = [self canReply] ? 1 : 0.5;
                } completion:nil];
            }
            else {
                cell.actionsView.alpha = self.loading ? 0.5 : 1;
                cell.actionsView.replyButton.alpha = [self canReply] || self.loading ? 1 : 0.5;
            }
            
            cell.actionsView.userInteractionEnabled = !self.loading;
            cell.actionsView.replyButton.userInteractionEnabled = [self canReply];
        }
        
        cell.topLine.hidden = ![self hasParentPost];
                
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
        
        BOOL showViewMore = false;//(subReplies < reply.attributes.summaries.counts.replies);
        BOOL showAddReply = reply.attributes.summaries.replies.count > 0;
        
        NSInteger firstSubReplyIndex = 1;
        
        if (indexPath.row == 0) {
            // parent post
            StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:parentPostReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:parentPostReuseIdentifier];
            }
            
            NSString *identifierBefore = cell.post.identifier;
            
            cell.showContext = false;
            cell.showCamptag = false;
            cell.hideActions = false;
            cell.post = reply;
            
            if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                [self didBeginDisplayingCell:cell];
            }
            
            cell.tag = adjustedIndex;
            if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
                [cell.actionsView.replyButton bk_whenTapped:^{
                    Post *post = self.stream.posts[cell.tag];

                    [self.composeInputView setReplyingTo:post];
                    [self.composeInputView.textView becomeFirstResponder];

                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:cell.tag+2] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                }];
            }
            
            cell.lineSeparator.hidden = (subReplies > 0 || showViewMore || showAddReply);
            cell.bottomLine.hidden = true;
            cell.topLine.hidden = true;
            
            return cell;
        }
        else if ((indexPath.row - firstSubReplyIndex) <  reply.attributes.summaries.replies.count) {
            NSInteger subReplyIndex = indexPath.row - firstSubReplyIndex;
            
            // reply
            ReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:postSubReplyReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postSubReplyReuseIdentifier];
            }
            
            cell.backgroundColor = [UIColor contentBackgroundColor];
            cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
            
            NSString *identifierBefore = cell.post.identifier;

            cell.levelsDeep = -1;
            NSLog(@"reply.attributes.summaries.replies[subReplyIndex]:: %@", reply.attributes.summaries.replies[subReplyIndex]);
            Post *subReply = reply.attributes.summaries.replies[subReplyIndex];
            cell.post = subReply;
                        
            if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                [self didBeginDisplayingCell:cell];
            }
            
            cell.lineSeparator.hidden = true;
            
            cell.selectable = YES;
            
            cell.topLevelReplyButton.tag = indexPath.section;

            [cell.topLevelReplyButton bk_whenTapped:^{
                [HapticHelper generateFeedback:FeedbackType_Selection];

                NSInteger adjustedIndex = cell.topLevelReplyButton.tag - 2;
                Post *cellPost = self.stream.posts[adjustedIndex];

                [self.composeInputView setReplyingTo:cellPost];
                [self.composeInputView.textView becomeFirstResponder];

                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:cell.topLevelReplyButton.tag] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }];
            
            return cell;
        }
        else if (showViewMore && indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex) {
            // "view more replies"
            ExpandThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:expandRepliesCellIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[ExpandThreadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandRepliesCellIdentifier];
            }
            cell.backgroundColor = [UIColor contentBackgroundColor];
            cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
            
            cell.levelsDeep = -1;
            
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
            
            cell.lineSeparator.hidden = true;
            
            return cell;
        }
        else if (showAddReply && indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex + (showViewMore ? 1 : 0)) {
            // "add a reply"
            AddReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:addReplyCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[AddReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addReplyCellIdentifier];
            }
            cell.backgroundColor = [UIColor contentBackgroundColor];
            cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
            
            NSString *username = reply.attributes.creator.attributes.identifier;
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Reply to @%@...", username] attributes:@{NSFontAttributeName: cell.addReplyButton.titleLabel.font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
            [attributedString setAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:cell.addReplyButton.titleLabel.font.pointSize weight:UIFontWeightSemibold]} range:[attributedString.string rangeOfString:[NSString stringWithFormat:@"@%@", username]]];
            [cell.addReplyButton setAttributedTitle:attributedString forState:UIControlStateNormal];
            
            cell.lineSeparator.hidden = false;
            cell.levelsDeep = -1;
            
            return cell;
        }
    }
    else if (indexPath.section == self.stream.posts.count + 2) {
        if (self.visualError) {
            BFErrorViewCell *cell = [tableView dequeueReusableCellWithIdentifier:errorViewCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[BFErrorViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:errorViewCellIdentifier];
            }
            
            cell.tintColor = self.view.tintColor;
            cell.visualError = self.visualError;
            
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.backgroundColor = [UIColor clearColor];
            cell.separator.hidden = true;
            
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
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)){
    if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[PostCell class]] &&
        ![[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[ExpandedPostCell class]]) {
        Post *post = ((PostCell *)[tableView cellForRowAtIndexPath:indexPath]).post;
        
        if (post) {
            NSMutableArray *actions = [NSMutableArray new];
            if ([post.attributes.context.post.permissions canReply]) {
                NSMutableArray *actions = [NSMutableArray new];
                UIAction *replyAction = [UIAction actionWithTitle:@"Reply" image:[UIImage systemImageNamed:@"arrowshape.turn.up.left"] identifier:@"reply" handler:^(__kindof UIAction * _Nonnull action) {
                    wait(0, ^{
                        [Launcher openComposePost:post.attributes.postedIn inReplyTo:post withMessage:nil media:nil  quotedObject:nil];
                    });
                }];
                [actions addObject:replyAction];
            }
            
            if (post.attributes.postedIn) {
                UIAction *openCamp = [UIAction actionWithTitle:@"Open Camp" image:[UIImage systemImageNamed:@"number"] identifier:@"open_camp" handler:^(__kindof UIAction * _Nonnull action) {
                    Camp *camp = [[Camp alloc] initWithDictionary:[post.attributes.postedIn toDictionary] error:nil];
                    
                    [Launcher openCamp:camp];
                }];
                [actions addObject:openCamp];
            }
            
            UIAction *shareViaAction = [UIAction actionWithTitle:@"Share via..." image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:@"share_via" handler:^(__kindof UIAction * _Nonnull action) {
                [Launcher sharePost:post];
            }];
            [actions addObject:shareViaAction];
            
            UIMenu *menu = [UIMenu menuWithTitle:@"" children:actions];
            
            PostViewController *postVC = [Launcher postViewControllerForPost:post];
            postVC.isPreview = true;
            
            UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:indexPath previewProvider:^(){return postVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
            return configuration;
        }
    }
    
    return nil;
}
- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    NSIndexPath *indexPath = (NSIndexPath *)configuration.identifier;
    
    [animator addCompletion:^{
        wait(0, ^{
            if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[PostCell class]]) {
                Post *post = ((PostCell *)[tableView cellForRowAtIndexPath:indexPath]).post;
                
                [Launcher openPost:post withKeyboard:false];
            }
        });
    }];
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    BOOL hasAnotherPage = self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.nextCursor != nil && [self.stream.pages lastObject].meta.paging.nextCursor.length > 0;
    return  1 + // parent posts
            1 + // expanded post
            (self.loading ? 1 : self.stream.posts.count + (hasAnotherPage || self.visualError ? 1 : 0));
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row < self.parentPosts.count) {
            return [StreamPostCell heightForPost:self.parentPosts[indexPath.row] showContext:true showActions:true minimizeLinks:false];
        }
        
        // loading ...
        return 0;
    }
    else if (indexPath.section == 1 && indexPath.row == 0 && (self.post.attributes.createdAt.length > 0 || self.post.attributes.removedAt.length > 0)) {
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
        
        BOOL showViewMore = false;//(subReplies < reply.attributes.summaries.counts.replies);
        BOOL showAddReply = reply.attributes.summaries.replies.count > 0;
        
        NSInteger firstSubReplyIndex = 1;
        
        if (indexPath.row == 0) {
            // BOOL showActions = (reply.attributes.summaries.replies.count == 0);
            return [StreamPostCell heightForPost:reply showContext:false showActions:true minimizeLinks:false];
        }
        else if ((indexPath.row - firstSubReplyIndex) < subReplies) {
            NSInteger subReplyIndex = indexPath.row - firstSubReplyIndex;
            Post *subReply = reply.attributes.summaries.replies[subReplyIndex];
            
            CGFloat height = [ReplyCell heightForPost:subReply levelsDeep:-1];
            if ((subReplyIndex == subReplies - 1) && !showViewMore && showAddReply) {
                // remove the bottom padding of the cell, since the add reply cell includes that padding
                height -= replyContentOffset.bottom;
            }
            
            return height;
        }
        else if (showViewMore && indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex) {
            // "view more replies"
            return [ExpandThreadCell height];
        }
        else if (showAddReply && indexPath.row == reply.attributes.summaries.replies.count + firstSubReplyIndex + (showViewMore ? 1 : 0)) {
            // "add a reply"
            return [AddReplyCell height];
        }
    }
    else if (indexPath.section - 2 == self.stream.posts.count) {
        if (self.visualError) {
            return [BFErrorViewCell heightForVisualError:self.visualError];
        }
        else {
            return 52;
        }
    }
    
    return 0;
}

- (BFVisualError *)visualError {
    if (_visualError) {
        return _visualError;
    }
    else if (!self.loading && self.post.attributes.context && !self.loadingMore && self.stream.posts.count == 0 && ![self canReply]) {
        return [BFVisualError visualErrorOfType:ErrorViewTypeRepliesDisabled title:@"Post Replies Disabled" description:@"The creator of this post has disabled replies for this post" actionTitle:nil actionBlock:nil];
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return HALF_PIXEL;
    }
    
    return CGFLOAT_MIN;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HALF_PIXEL)];
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
        return;
    }
    
    if ([cell isKindOfClass:[ReplyCell class]]) {
        Post *post = ((ReplyCell *)cell).post;
        
        if (post.tempId) {
            cell.contentView.alpha = 0.5;

            [UIView animateWithDuration:0.5f delay:0.25f usingSpringWithDamping:0.9f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                cell.contentView.alpha = 1;
            } completion:nil];
        }
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
- (CGFloat)parentPostsHeight {
    if (self.parentPosts.count == 0) return 0;
    
    CGFloat height = 0;
    for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:0]; i++) {
        height += [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    return height;
}
- (CGFloat)replyPostsHeight {
    CGFloat height = 0;
    for (NSInteger s = 2; s < self.tableView.numberOfSections; s++) {
        height += [self tableView:self.tableView heightForHeaderInSection:s];
        for (NSInteger r = 0; r < [self.tableView numberOfRowsInSection:0]; r++) {
            height += [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:s]];
        }
        height += [self tableView:self.tableView heightForFooterInSection:s];
    }
    
    DLog(@"replyPostsHeight: %f", height);
    
    return height;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.tableView) {
        [self.launchNavVC childTableViewDidScroll:self.tableView];
        
        if ([self hasParentPost] && self.parentPostScrollIndicator.alpha == 1) {
            CGFloat contentOffset = scrollView.contentOffset.y;
            CGFloat parentPostsHeight = [self parentPostsHeight];
            CGFloat hideLine = parentPostsHeight - self.tableView.adjustedContentInset.top;
            
            if (contentOffset < parentPostsHeight - self.tableView.adjustedContentInset.top) {
                [self hideParentPostScrollIndicator];
            }
            else {
                // scroll with the content
                CGFloat amountBeyondHideLine = contentOffset - hideLine;
                self.parentPostScrollIndicator.transform = CGAffineTransformMakeTranslation(0, -amountBeyondHideLine);
            }
        }
        
        CGPoint fingerLocation = [scrollView.panGestureRecognizer locationInView:scrollView];
        CGPoint absoluteFingerLocation = [scrollView convertPoint:fingerLocation toView:self.view];

        if (_currentKeyboardHeight > 0 && scrollView.panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
            CGFloat bottomPadding = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
            
            CGFloat before = _currentKeyboardHeight;
            _currentKeyboardHeight = MAX(MIN(roundf([[UIScreen mainScreen] bounds].size.height - absoluteFingerLocation.y), _currentKeyboardFrame.size.height), bottomPadding);
            if (before == _currentKeyboardHeight) return;
            
            [self updateComposeInputViewFrame];
            [self updateContentInsets];
        }
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return textView.text.length + (text.length - range.length) <= [Session sharedInstance].defaults.post.maxLength;
}
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return true;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
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
        [self.composeInputView.textView resignFirstResponder];
        [self postMessage];
    }];
    [self.composeInputView.expandButton bk_whenTapped:^{
        [Launcher openComposePost:self.post.attributes.postedIn inReplyTo:(self.composeInputView.replyingTo?self.composeInputView.replyingTo:self.post) withMessage:self.composeInputView.textView.text media:nil quotedObject:nil];
    }];
    [self.composeInputView.replyingToLabel bk_whenTapped:^{
        // scroll to post you're replying to
        NSArray<Post *> *posts = self.stream.posts;
        for (NSInteger i = 0; i < posts.count; i++) {
            if (posts[i].identifier == self.composeInputView.replyingTo.identifier) {
                // scroll to this item!
                NSIndexPath* ipath = [NSIndexPath indexPathForRow:0 inSection:i+2];
                [self.tableView scrollToRowAtIndexPath:ipath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                
                break;
            }
        }
        
        [self updateContentInsets];
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.tintColor = [self.theme isEqual:[UIColor whiteColor]] ? [UIColor bonfirePrimaryColor] : self.theme;
    self.composeInputView.postButton.backgroundColor = self.composeInputView.tintColor;
    self.composeInputView.postButton.tintColor = [UIColor highContrastForegroundForBackground:self.composeInputView.postButton.backgroundColor];
}

- (void)composeInputViewReplyingToDidChange {
    NSLog(@"input view replying to did change");
    [self updateContentInsets];
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
        if (self.post.attributes.postedIn) {
            [BFAPI createPost:params postingIn:self.post.attributes.postedIn replyingTo:replyingTo attachments:nil];
        }
        else {
            [BFAPI createPost:params postingIn:nil replyingTo:replyingTo attachments:nil];
        }
        
        [self.composeInputView reset];
    }
}
- (void)updateComposeInputView {
    [self.composeInputView setMediaTypes:self.post.attributes.context.post.permissions.reply];

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
    if ([self.composeInputView isHidden]) {
        [self updateComposeInputViewFrame];
        self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        self.composeInputView.hidden = false;
        
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}
- (void)hideComposeInputView {
    if (![self.composeInputView isHidden]) {
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        } completion:^(BOOL finished) {
            self.composeInputView.hidden = true;
        }];
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
}

#pragma mark - Misc.
- (void)updateTheme {
    UIColor *theme;
    BOOL postedInCamp = self.post.attributes.postedIn != nil;
    if (postedInCamp) {
        theme = [UIColor fromHex:self.post.attributes.postedIn.attributes.color];
    }
    else {
        theme = [UIColor fromHex:self.post.attributes.creator.attributes.color];
    }
    
    self.theme = theme;
    self.view.tintColor = theme;
    self.navigationController.view.tintColor = theme;
    self.tableView.tintColor = theme;
    
    UIColor *themeAdjustedForDarkMode = [UIColor fromHex:[UIColor toHex:theme] adjustForOptimalContrast:true];
    [UIView animateWithDuration:0.35f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        if ([Launcher activeViewController] == self) {
            [self.launchNavVC updateBarColor:theme animated:false];
        }
        
        self.composeInputView.textView.tintColor = themeAdjustedForDarkMode;
        self.composeInputView.postButton.backgroundColor = themeAdjustedForDarkMode;
        self.composeInputView.postButton.tintColor = [UIColor highContrastForegroundForBackground:self.composeInputView.postButton.backgroundColor];
    } completion:^(BOOL finished) {
    }];
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
    Camp *camp = self.post.attributes.postedIn;
    if (camp) {
        BOOL canViewPost = camp.identifier != nil && // has an ID
        !camp.attributes.isSuspended && // Camp not blocked
        ![camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_BLOCKED];
        
        return canViewPost;
    }
    else {
        return true;
    }
    
    return false;
}
- (void)updateContentInsets {
    CGFloat bottomPadding = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    
    CGFloat newComposeInputViewY = (self.currentKeyboardHeight > 0 ? self.composeInputView.frame.origin.y + bottomPadding : self.view.frame.size.height + ([self.composeInputView isHidden] ? 0 : -self.composeInputView.frame.size.height + bottomPadding));
        
    CGFloat parentPostOffset = 0;
    if ([self hasParentPost]) {
        CGFloat expandedPostHeight = [ExpandedPostCell heightForPost:self.post width:[UIScreen mainScreen].bounds.size.width];
        CGFloat repliesHeight = [self replyPostsHeight];
        DLog(@"reply posts height:: %f", repliesHeight);
        
        CGFloat y1 = self.composeInputView.frame.origin.y - self.tableView.adjustedContentInset.top;
        DLog(@"self.composeInputView.frame.origin.y: %f", self.composeInputView.frame.origin.y);
        DLog(@"self.tableView.adjustedContentInset.top: %f", self.tableView.adjustedContentInset.top);
        
        DLog(@"y1: %f", y1);
        CGFloat y2 = expandedPostHeight + repliesHeight;
        DLog(@"y2: %f", y2);
        DSpacer();
        
        parentPostOffset = y1 - y2;
        parentPostOffset = MAX(0, parentPostOffset);
    }
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.view.frame.size.height - newComposeInputViewY + (self.composeInputView.replyingTo != nil ? self.composeInputView.replyingToLabel.frame.size.height : 0) + parentPostOffset + (![self.shareUpsellView isHidden] ? self.shareUpsellView.frame.size.height : 0), 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.height - newComposeInputViewY + (self.composeInputView.replyingTo != nil ? self.composeInputView.replyingToLabel.frame.size.height : 0) + (![self.shareUpsellView isHidden] ? self.shareUpsellView.frame.size.height : 0), 0);
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
        
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
        
        [self updateContentInsets];
    }
}

//- (void)setParentPost:(Post *)parentPost {
//    if (parentPost != _parentPost) {
//        _parentPost = parentPost;
//
//        //[self buildConversation];
//    }
//}
//
//- (void)buildConversation {
//    NSMutableArray *conversation = [NSMutableArray array];
//
//    NSMutableArray *posts = [NSMutableArray array];
//    if (self.parentPost) {
//        [posts addObject:self.parentPost];
//    }
//    if (self.post) {
//        [posts addObject:self.post];
//    }
//
////    for (Post *post in posts) {
////        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
////        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
////
////        NSDate *datePosted = [formatter dateFromString:post.attributes.createdAt];
//////        FIRTextMessage *message = [[FIRTextMessage alloc]
//////                                   initWithText:post.attributes.simpleMessage
//////                                   timestamp:datePosted.timeIntervalSince1970
//////                                   userID:post.attributes.creator.identifier
//////                                   isLocalUser:[post.attributes.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]];
//////        [conversation addObject:message];
////    }
//
//    self.conversation = conversation;
//
//    [self determineAutoReplies];
//}
//
//- (void)determineAutoReplies {
////    if ([self.conversation count] == 0) return;
////
////    FIRNaturalLanguage *naturalLanguage = [FIRNaturalLanguage naturalLanguage];
////    FIRSmartReply *smartReply = [naturalLanguage smartReply];
////    [smartReply suggestRepliesForMessages:self.conversation completion:^(FIRSmartReplySuggestionResult * _Nullable result, NSError * _Nullable error) {
////        if (error || !result) {
////           return;
////        }
////        if (result.status == FIRSmartReplyResultStatusNotSupportedLanguage) {
////           // The conversation's language isn't supported, so the
////           // the result doesn't contain any suggestions.
////        } else if (result.status == FIRSmartReplyResultStatusSuccess) {
////           // Successfully suggested smart replies.
////           for (FIRSmartReplySuggestion *suggestion in result.suggestions) {
////               NSLog(@"Suggested reply: %@", suggestion.text);
////           }
////        }
////    }];
//}

@end
