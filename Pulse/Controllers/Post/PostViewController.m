//
//  PostViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "PostViewController.h"
#import "SimpleNavigationController.h"
#import "BFVisualErrorView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "InsightsLogger.h"
#import "HAWebService.h"
#import "BFActivityIndicatorView.h"

#import "ExpandedPostCell.h"
#import "StreamPostCell.h"
#import "ReplyUpsellTableViewCell.h"
@import Firebase;

@interface PostViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL loadingParentPosts;
@property (nonatomic) BOOL loadingReplies;
@property (nonatomic) BOOL loadingMore;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property (nonatomic, strong) SimpleNavigationController *launchNavVC;

@property (nonatomic, strong) NSMutableArray *parentPosts;
@property (nonatomic, strong) BFActivityIndicatorView *parentPostSpinner;

@property (nonatomic, strong) NSArray * _Nullable replySuggestions;
@property (nonatomic, assign) NSMutableArray *conversation;

@property (nonatomic, strong) UIVisualEffectView *shareUpsellView;

@end

@implementation PostViewController

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const postReplyReuseIdentifier = @"postReply";
static NSString * const postSubReplyReuseIdentifier = @"postSubReply";
static NSString * const parentPostReuseIdentifier = @"parentPost";
static NSString * const expandedPostReuseIdentifier = @"expandedPost";
static NSString * const expandRepliesCellIdentifier = @"expandRepliesCell";
static NSString * const replyUpsellReuseIdentifier = @"replyUpsellCell";

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
    
    self.replySuggestions = @[];
    
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
//    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:true];
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
    if ([notification.object isKindOfClass:[Post class]]) {        
        Post *updatedPost = (Post *)notification.object;
        
        if (updatedPost == nil) return;
        
        BOOL newMuteStatus = updatedPost.attributes.context.post.muted;
        
        BOOL useNewMuteStatus = false;
        BOOL changes = false;
                
        if ([self.post.identifier isEqualToString:updatedPost.identifier] &&
            [self.post toDictionary] != [updatedPost toDictionary]) {
            if (newMuteStatus != self.post.attributes.context.post.muted) {
                useNewMuteStatus = true;
            }
            
            // set updated expanded post
            self.post = updatedPost;
            
            changes = true;
        }
        else {
            Post *replyWithId = [self.tableView.stream postWithId:updatedPost.identifier];
            if (replyWithId) {
                if ([replyWithId.identifier isEqualToString:updatedPost.identifier] &&
                    [replyWithId toDictionary] != [updatedPost toDictionary]) {
                    if (newMuteStatus != self.post.attributes.context.post.muted) {
                        useNewMuteStatus = true;
                    }
                    
                    changes = true; // actual changes handled by BFComponentTableView
                }
            }
            else if (self.parentPosts.count > 0) {
                // update parent posts
                DSimpleLog(@"self.parentPosts: %@", self.parentPosts);
                for (NSInteger i = 0; i < self.parentPosts.count; i++) {
                    Post *parentPost = self.parentPosts[i];
                    
                    DSimpleLog(@"parent post:: %@", parentPost.identifier);
                    
                    if ([parentPost.identifier isEqualToString:updatedPost.identifier] &&
                        [parentPost toDictionary] != [updatedPost toDictionary]) {
                        if (newMuteStatus != parentPost.attributes.context.post.muted) {
                            useNewMuteStatus = true;
                        }
                        
                        DSimpleLog(@"matching updated parent post:: %@", parentPost.identifier);
                        
                        [self.parentPosts replaceObjectAtIndex:i withObject:updatedPost];
                        
                        changes = true;
                    }
                }
            }
        }
        
        if (changes) {
            if (![[Launcher activeViewController] isEqual:self]) {
                [self.tableView reloadData];
            }
            
            if ([[Launcher activeViewController] isEqual:self] ||
                useNewMuteStatus) {
                if (![self.post.identifier isEqualToString:updatedPost.identifier] &&
                    useNewMuteStatus) {
                    self.post.attributes.context.post.muted = updatedPost.attributes.context.post.muted;
                }
                
                // loop through and update post objects
                for (UITableViewCell *cell in [self.tableView visibleCells]) {
                    if ([cell isKindOfClass:[PostCell class]]) {
                        PostCell *postCell = (PostCell  *)cell;
                        
                        if ([postCell.post.identifier isEqualToString:updatedPost.identifier]) {
                            // ID matches --> update
                            postCell.post = updatedPost;
                        }
                        else if (useNewMuteStatus) {
                            postCell.post.attributes.context.post.muted = updatedPost.attributes.context.post.muted;
                        }
                    }
                }
                
                if (useNewMuteStatus) {
                    self.post.attributes.context.post.muted = updatedPost.attributes.context.post.muted;

                    for (BFStreamComponent *component in self.tableView.stream.components) {
                        Post *post = component.post;
                        if (!post) continue;
                        
                        post.attributes.context.post.muted = updatedPost.attributes.context.post.muted;
                        [self.tableView.stream performEventType:PostStreamEventTypePostUpdated object:updatedPost];
                    }
                    
                    for (Post *post in self.parentPosts) {
                        post.attributes.context.post.muted = updatedPost.attributes.context.post.muted;
                    }
                }
            }
        }
    }
}
- (void)postDeleted:(NSNotification *)notification {
    if (![notification.object isKindOfClass:[Post class]]) return;
    
    Post *post = (Post *)notification.object;
    
    if (post && [post.identifier isEqualToString:self.post.identifier]) {
        self.post = post;
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}
- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;

    if (tempPost != nil && tempPost.attributes.parent) {
        if ([tempPost.attributes.parent.identifier isEqualToString:self.post.identifier] ||
            [tempPost.attributes.parentId isEqualToString:self.post.identifier]) {
            // parent post
            [self.tableView.stream addTempPost:tempPost];

            if (self.post.attributes.summaries.counts.replies == 0) {
                self.post.attributes.summaries.counts.replies++;
            }

            [self.tableView reloadData];
            [self.tableView layoutIfNeeded];
            
            self.replySuggestions = @[];
            
            [self updateContentInsets];
        }
        else if ([self.tableView.stream addTempSubReply:tempPost]) {
            [self.tableView reloadData];
            [self.tableView layoutIfNeeded];
            [self updateContentInsets];
        }
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSLog(@"☑️ newPostCompleted");

    NSDictionary *info = notification.object;
    Post *post = info[@"post"];

    if (post != nil && (post.attributes.parent.identifier || post.attributes.parentId)) {
        if ([post.attributes.parent.identifier isEqualToString:self.post.identifier] ||
            [post.attributes.parentId isEqualToString:self.post.identifier]) {
            [self.tableView.stream removeLoadedCursor:self.tableView.stream.prevCursor];
            [self getRepliesWithCursor:StreamPagingCursorTypePrevious];
        }
        else if ([self.tableView.stream performEventType:PostStreamEventTypePostUpdated object:post]) {
            [self.tableView reloadData];
            [self.tableView layoutIfNeeded];
            [self updateContentInsets];
        }
    }
}
- (void)newPostFailed:(NSNotification *)notification {
    // TODO: Allow tap to retry for posts
    Post *tempPost = notification.object;
    
    if (tempPost != nil && ([tempPost.attributes.parent.identifier isEqualToString:self.post.identifier] ||
                            [tempPost.attributes.parentId isEqualToString:self.post.identifier])) {
        [self.tableView.stream removeTempPost:tempPost.tempId];
        
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
        [self updateContentInsets];
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
        self.tableView.visualError  = nil;
        
        // fill in post info
        [self.tableView reloadData];
        [self.tableView layoutSubviews];
        
        [self getPost];
        
        [self loadPostReplies];
    }
    else {
        self.tableView.visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Post Not Found" description:@"We couldn't find the post\nyou were looking for" actionTitle:nil actionBlock:nil];
        
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
    
    [self loadParentPostsIfNeeded];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
                                
        BFContext *contextBefore = self.post.attributes.context;
        
        // first page
        self.post = [[Post alloc] initWithDictionary:responseData error:nil];
                
        if (contextBefore && ![self.post isRemoved] && !self.post.attributes.context) {
            self.post.attributes.context = contextBefore;
        }
        
        // update the theme color (in case we didn't know the Camp/Profile color before
        [self updateTheme];
        
        if (self.post.attributes.context && !self.tableView.loadingMore && self.tableView.stream.components.count == 0 && ![self canReply]) {
            self.tableView.visualError = [BFVisualError visualErrorOfType:ErrorViewTypeRepliesDisabled title:@"Post Replies Disabled" description:@"The creator of this post has disabled replies" actionTitle:nil actionBlock:nil];
        }
        else {
            self.tableView.visualError = nil;
        }
        [self.tableView reloadData];
        
        // update reply ability using camp
        [self updateComposeInputView];
        
        if ([self.tableView isHidden]) {
            [self loadPostReplies];
        }
        [self loadParentPostsIfNeeded];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.tableView layoutIfNeeded];
            [self updateContentInsets];
        });
                
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
        else if (!self.post.attributes && self.parentPosts.count == 0 && self.tableView.stream.components.count == 0) {
            self.tableView.visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Error Loading Post" description:@"Check your network settings and try again" actionTitle:nil actionBlock:nil];
        }
        
        self.loading = false;
        [self.tableView reloadData];
        
        self.launchNavVC.onScrollLowerBound = 12;
    }];
}
- (void)loadParentPostsIfNeeded {
    if ([self hasParentPost] && !self.isPreview && self.parentPosts.count == 0 && !self.loadingParentPosts) {
        [self setupParentPostScrollIndicator];
        [self getParentPosts];
    }
}
- (void)getParentPosts {
    if (![self hasParentPost]) {
        return;
    }
    
    self.launchNavVC.onScrollLowerBound = 12;
    
    // call this in order to handle the scroll down effect
    void (^reloadWithParentPosts)(void) = ^void() {
        self.parentPostSpinner.hidden = true;
        
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
        
        BOOL useParentPostPrevCursor = (self.post.attributes.parent || self.post.attributes.parentId.length > 0) && self.post.attributes.parent.attributes.thread.prevCursor;
        if (useParentPostPrevCursor) {
            identifier = (self.post.attributes.parent ? self.post.attributes.parent.identifier : self.post.attributes.parentId);
            cursor = self.post.attributes.parent.attributes.thread.prevCursor;
        }
        
        NSString *url = [NSString stringWithFormat:@"posts/%@/thread", identifier];
        
        NSLog(@"url: %@", url);
        
        self.parentPostSpinner.hidden = false;
        self.loadingParentPosts = true;
        [self.parentPostSpinner startAnimating];
        
        [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:@{@"prev_cursor": cursor} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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
                    self.parentPosts = [[@[self.post.attributes.parent] arrayByAddingObjectsFromArray:responseData] mutableCopy];
                }
                else {
                    self.parentPosts = responseData;
                }
            }
            else {
                self.parentPosts = [@[] mutableCopy];
            }
            
            reloadWithParentPosts();
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"CampViewController / getCamp() - error: %@", error);
            
        }];
    }
    else {
        self.parentPosts = [@[self.post.attributes.parent] mutableCopy];
        
        reloadWithParentPosts();
    }
}
- (void)loadPostReplies {
    if ([self canViewPost]) {
        [self getRepliesWithCursor:StreamPagingCursorTypeNone];
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
        self.tableView.visualError = [BFVisualError visualErrorOfType:errorType title:errorTitle description:errorDescription actionTitle:nil actionBlock:nil];
        [self.tableView reloadData];
    }
}
- (void)setupPostHasBeenDeleted {
    self.post = nil;
    self.parentPosts = [@[] mutableCopy];
    [self hideComposeInputView];
    self.parentPostScrollIndicator.hidden = true;
    
    self.tableView.visualError = [BFVisualError visualErrorOfType:ErrorViewTypeGeneral title:nil description:@"This post has been deleted" actionTitle:nil actionBlock:nil];
    [self.tableView reloadData];
}
- (void)getRepliesWithCursor:(StreamPagingCursorType)cursorType {
    self.tableView.visualError = nil;
    [self.tableView reloadData];
    
    NSString *url = [NSString stringWithFormat:@"posts/%@/replies", self.post.identifier];
    if (!self.post.identifier || self.post.identifier.length == 0) {
        return;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (cursorType == StreamPagingCursorTypeNext) {
        [params setObject:self.tableView.stream.nextCursor forKey:@"next_cursor"];
        NSLog(@"⬇️ load next cursor (%@)", self.tableView.stream.nextCursor);
    }
    else if (self.tableView.stream.prevCursor.length > 0) {
        [params setObject:self.tableView.stream.prevCursor forKey:@"prev_cursor"];
        NSLog(@"🔼 load previous cursor (%@)", self.tableView.stream.prevCursor);
    }
    
    if ([params objectForKey:@"prev_cursor"] ||
        [params objectForKey:@"next_cursor"]) {
        NSString *cursor = [params objectForKey:@"prev_cursor"] ? params[@"prev_cursor"] : params[@"next_cursor"];
        
        if ([self.tableView.stream hasLoadedCursor:cursor]) {
            return;
        }
        else {
            [self.tableView.stream addLoadedCursor:cursor];
        }
    }
    else if (cursorType == StreamPagingCursorTypePrevious) {
        cursorType = StreamPagingCursorTypeNone;
    }
    
    NSLog(@"📲: %@", url);
    NSLog(@"params: %@", params);
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.loading = false;
        
        NSInteger componentsBefore = self.tableView.stream.components.count;
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];

        if (page.data.count > 0) {
            if (page.meta.paging.replaceCache ||
                cursorType == StreamPagingCursorTypeNone) {
                [self.tableView.stream flush];
            }
            
            if (cursorType == StreamPagingCursorTypeNext) {
                [self.tableView.stream appendPage:page];
            }
            else {
                self.tableView.stream.tempComponents = [NSMutableArray<BFStreamComponent *><BFStreamComponent> new];
                
                [self.tableView.stream prependPage:page];
            }
            
            if (self.tableView.stream.components.count > 0) {
                self.tableView.visualError = nil;
            }
                        
            if (componentsBefore == 0 || cursorType != StreamPagingCursorTypeNext) {
                [self.tableView hardRefresh:false];
            }
            else {
                [self.tableView refreshAtBottom];
            }
        }
        else {
            [self.tableView hardRefresh:false];
        }
        
        if (cursorType == StreamPagingCursorTypeNext) {
            self.tableView.loadingMore = false;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.tableView layoutIfNeeded];
            [self updateContentInsets];
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"FeedViewController / getReplies() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loading = false;
        self.tableView.loadingMore = false;
        
        self.tableView.userInteractionEnabled = true;
        [self.tableView reloadData];
    }];
}

#pragma mark - Table view
- (void)setupTableView {
    self.tableView = [[BFComponentTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.extendedDelegate = self;
    self.tableView.stream.detailLevel = BFComponentDetailLevelSome;
    self.tableView.loadingStyle = BFComponentTableViewLoadingStyleSpinner;
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
    [self.tableView registerClass:[ReplyUpsellTableViewCell class] forCellReuseIdentifier:replyUpsellReuseIdentifier];
        
    [self.tableView.stream setTempPostPosition:PostStreamOptionTempPostPositionTop];
    
    [self.view addSubview:self.tableView];
    
    self.parentPostSpinner = [[BFActivityIndicatorView alloc] init];
    self.parentPostSpinner.color = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.5];
    self.parentPostSpinner.frame = CGRectMake(self.view.frame.size.width / 2 - (self.parentPostSpinner.frame.size.width / 2), (-1 * 60), self.parentPostSpinner.frame.size.width, 60);
    self.parentPostSpinner.hidden = true;
    [self.tableView addSubview:self.parentPostSpinner];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, -HALF_PIXEL, self.view.frame.size.width, HALF_PIXEL)];
    separator.backgroundColor = [UIColor tableViewSeparatorColor];
    [self.tableView addSubview:separator];
}

#pragma mark ↳ Table view data source
- (BOOL)canReply {
    return [_post.attributes.context.post.permissions canReply];
}
- (BOOL)isPostIncomplete {
    return (self.post.attributes.creator.attributes.displayName.length == 0);
}
- (BOOL)showReplyUpsell {
    return !self.loading && [self canReply] && self.replySuggestions && self.replySuggestions.count > 0;
}
- (CGFloat)numberOfRowsInFirstSection {
    return [self isPostIncomplete] ? 0 : (self.parentPosts.count + 1 + ([self showReplyUpsell] ? 1 : 0));
}

- (UITableViewCell *)cellForRowInFirstSection:(NSInteger)row {
    if (row < self.parentPosts.count) {
        // parent post
        StreamPostCell *cell = [self.tableView dequeueReusableCellWithIdentifier:parentPostReuseIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        
        if (cell == nil) {
            cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:parentPostReuseIdentifier];
        }
        
        NSString *identifierBefore = cell.post.identifier;
        
        cell.showContext = false;
        cell.showPostedIn = false;
        cell.post = self.parentPosts[row];
        
        if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
            [self.tableView didBeginDisplayingCell:cell];
        }
        
        cell.tag = row;
        if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
            [cell.actionsView.replyButton bk_whenTapped:^{
                Post *post = self.parentPosts[cell.tag];

                [self.composeInputView setReplyingTo:post];
                [self.composeInputView.textView becomeFirstResponder];

                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:cell.tag+2] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }];
        }
        
        cell.lineSeparator.hidden = true;
        cell.bottomLine.hidden = false;
        cell.topLine.hidden = (row == 0);
        
        return cell;
    }
    else if (row == self.parentPosts.count) {
        // expanded post
        ExpandedPostCell *cell = [self.tableView dequeueReusableCellWithIdentifier:expandedPostReuseIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        
        if (cell == nil) {
            cell = [[ExpandedPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandedPostReuseIdentifier];
        }
        
        cell.tintColor = self.theme;
        cell.loading = self.tableView.loading;
        
        cell.post = self.post;
        
        if (![cell.post isRemoved]) {
            if (cell.actionsView.replyButton.gestureRecognizers == 0) {
                [cell.actionsView.replyButton bk_whenTapped:^{
                    //[self.composeInputView.textView becomeFirstResponder];
                    [Launcher openComposePost:self.post.attributes.postedIn inReplyTo:self.post withMessage:self.composeInputView.textView.text media:nil quotedObject:nil];
                }];
            }
            
            if (!cell.loading) {
                if ((int)[cell.activityView currentViewTag] == (int)PostActivityViewTagAddReply && self.tableView.stream.components.count > 0) {
                    [cell.activityView next];
                }
                else if (!cell.activityView.active) {
                    [cell.activityView start];
                }
            }

            BOOL hasContext = cell.post.attributes.context != nil;
            
            BOOL temporary = cell.post.tempId.length > 0;
            
            BOOL canReply = hasContext && !_post.attributes.creatorBot && [self canReply] && !temporary;
            BOOL canShare = ![_post.attributes.postedIn isPrivate] && !temporary;
            BOOL canVote = hasContext && !_loading;
            
            cell.actionsView.replyButton.userInteractionEnabled = canReply;
            cell.actionsView.shareButton.userInteractionEnabled = canShare;
            cell.actionsView.voteButton.userInteractionEnabled = canVote;
            
            if (cell.actionsView.tag == 1 && hasContext) {
                cell.actionsView.tag = 0;
                [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    cell.actionsView.replyButton.alpha = [cell.actionsView.replyButton isUserInteractionEnabled] ? 1 : 0.5;
                    cell.actionsView.voteButton.alpha = [cell.actionsView.voteButton isUserInteractionEnabled] ? 1 : 0.5;
                    cell.actionsView.shareButton.alpha = [cell.actionsView.shareButton isUserInteractionEnabled] ? 1 : 0.5;
                } completion:nil];
            }
            else {
                cell.actionsView.tag = 1;
                cell.actionsView.replyButton.alpha = [cell.actionsView.replyButton isUserInteractionEnabled] ? 1 : 0.5;
                cell.actionsView.voteButton.alpha = [cell.actionsView.voteButton isUserInteractionEnabled] ? 1 : 0.5;
                cell.actionsView.shareButton.alpha = [cell.actionsView.shareButton isUserInteractionEnabled] ? 1 : 0.5;
            }
        }
        
        cell.topLine.hidden = ![self hasParentPost];
                
        return cell;
    }
    else if (row == self.parentPosts.count + 1) {
        // add reply upsell cell
        ReplyUpsellTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:replyUpsellReuseIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        
        if (cell == nil) {
            cell = [[ReplyUpsellTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:replyUpsellReuseIdentifier];
        }
        
        cell.collapsed = (self.tableView.stream.components.count > 0);
        
        cell.tintColor = self.theme;
        [cell setSuggestionTappedAction:^(NSString * _Nonnull text) {
            [HapticHelper generateFeedback:FeedbackType_Selection];
            
            self.composeInputView.textView.text = text;
            [self.composeInputView textViewDidChange:self.composeInputView.textView];
            [self.composeInputView.textView becomeFirstResponder];
        }];
        [cell setSuggestions:self.replySuggestions];
        
        return cell;
    }
    
    return nil;
}

- (void)tableView:(nonnull id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.tableView.stream.nextCursor.length > 0 && ![self.tableView.stream hasLoadedCursor:self.tableView.stream.nextCursor]) {
        [self getRepliesWithCursor:StreamPagingCursorTypeNext];
    }
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

- (CGFloat)heightForRowInFirstSection:(NSInteger)row {
    if (row < self.parentPosts.count) {
        return [StreamPostCell heightForPost:self.parentPosts[row] showContext:false showActions:true minimizeLinks:false];
    }
    else if (row == self.parentPosts.count) {
        // expanded post
        return [ExpandedPostCell heightForPost:self.post width:[UIScreen mainScreen].bounds.size.width];
    }
    else if (row == self.parentPosts.count + 1) {
        if (self.tableView.stream.components.count > 0) {
            return [ReplyUpsellTableViewCell collapsedHeight];
        }
        else {
            return [ReplyUpsellTableViewCell height];
        }
    }
    
    return 0;
}

- (void)didSelectRowInFirstSection:(NSInteger)row {
    Post *post;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    if ([cell isKindOfClass:[ExpandedPostCell class]]) return;
    
    if ([cell isKindOfClass:[StreamPostCell class]]) {
        if (!((PostCell *)cell).post) return;
        
        post = ((PostCell *)cell).post;
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

- (CGFloat)parentPostsHeight {
    if (self.parentPosts.count == 0) return 0;
    
    CGFloat height = 0;
    for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:0] - 1; i++) {
        height += [self.tableView tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    return height;
}
- (CGFloat)replyPostsHeight {
    CGFloat height = 0;
    
    if ([self.tableView numberOfRowsInSection:0] > self.parentPosts.count + 1) {
        height += [self heightForRowInFirstSection:self.parentPosts.count+1];
    }
    
    height += [self.tableView tableView:self.tableView heightForHeaderInSection:1];
    for (NSInteger r = 0; r < [self.tableView numberOfRowsInSection:1]; r++) {
        height += [self.tableView tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:1]];
    }
    height += [self.tableView tableView:self.tableView heightForFooterInSection:1];

    DLog(@"replyPostsHeight: %f", height);
    
    return height;
}
- (void)tableViewDidScroll:(UITableView *)tableView {
    if (tableView == self.tableView) {
        [self.launchNavVC childTableViewDidScroll:self.tableView];
        
        if ([self hasParentPost] && self.parentPostScrollIndicator.alpha == 1) {
            CGFloat contentOffset = tableView.contentOffset.y;
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
    self.composeInputView.theme = self.theme;
    self.composeInputView.defaultPlaceholder = @"Add a reply...";
    [self.composeInputView updatePlaceholders];
    
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
    
    [self.view addSubview:self.composeInputView];
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
- (void)showComposeInputView {
    if ([self isPreview]) {
        return;
    }
    
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
    UIColor *theme = [UIColor fromHex:self.post.themeColor];
    
    self.theme = theme;
    self.view.tintColor = theme;
    self.navigationController.view.tintColor = theme;
    self.tableView.tintColor = theme;
    
    [UIView animateWithDuration:0.35f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]] && self.navigationController.topViewController == self) {
            [(SimpleNavigationController *)self.navigationController updateBarColor:theme animated:false];
        }
        
        self.composeInputView.theme = theme;
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
        
        CGFloat y1 = self.composeInputView.frame.origin.y - self.tableView.adjustedContentInset.top;
        
        CGFloat y2 = expandedPostHeight + repliesHeight;
        
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

- (void)setLoading:(BOOL)loading {
    if (loading != _loading) {
        _loading = loading;
        
        self.tableView.loading = loading;
        
        if (!loading && [self allDoneLoading]) {
            [self buildConversation];
        }
    }
}
- (void)setLoadingParentPosts:(BOOL)loadingParentPosts {
    if (loadingParentPosts != _loadingParentPosts) {
        _loadingParentPosts = loadingParentPosts;
        
        if (!loadingParentPosts && [self allDoneLoading]) {
            [self buildConversation];
        }
    }
}

- (BOOL)allDoneLoading {
    return !self.loading && !self.loadingParentPosts;
}

- (void)buildConversation {
    NSMutableArray *conversation = [NSMutableArray array];

    NSMutableArray *posts = [NSMutableArray array];
    if (self.parentPosts && self.parentPosts.count > 0) {
        [posts addObjectsFromArray:self.parentPosts];
    }
    if (self.post) {
        [posts addObject:self.post];
    }

    for (Post *post in posts) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];

        NSDate *datePosted = [formatter dateFromString:post.attributes.createdAt];
        FIRTextMessage *message = [[FIRTextMessage alloc]
                                   initWithText:post.attributes.simpleMessage
                                   timestamp:datePosted.timeIntervalSince1970
                                   userID:post.attributes.creator.identifier
                                   isLocalUser:[post.attributes.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]];
        [conversation addObject:message];
    }

    self.conversation = conversation;

    [self determineAutoReplies];
}

- (void)determineAutoReplies {
    if (self.conversation.count == 0) return;

    FIRNaturalLanguage *naturalLanguage = [FIRNaturalLanguage naturalLanguage];
    FIRSmartReply *smartReply = [naturalLanguage smartReply];
    [smartReply suggestRepliesForMessages:self.conversation completion:^(FIRSmartReplySuggestionResult * _Nullable result, NSError * _Nullable error) {
        NSMutableArray *mutableSuggestions = [NSMutableArray new];
        
        if (!error && result) {
            if (result.status == FIRSmartReplyResultStatusSuccess) {
               // Successfully suggested smart replies.
               for (FIRSmartReplySuggestion *suggestion in result.suggestions) {
                   DLog(@"Suggested reply: %@", suggestion.text);
                   [mutableSuggestions addObject:suggestion.text];
               }
            }
        }
                
        NSArray *words = [self.post.attributes.message componentsSeparatedByString:@" "];
        
        if (mutableSuggestions.count > 0) {
            NSDictionary *emojis = @{
                @"lit": @"🔥",
                @"100": @"💯",
                @"love": @"❤️",
                @"mind blown": @"🤯",
                @"bonfire": @"🔥",
                @"goals": @"🙌",
                @"congrats": @"🎉",
                @"thinking": @"🤔",
                @"haha": @"😂",
                @"lol": @"😂",
                @"lmao": @"😂"
            };
            
            NSString *emoji;
            for (NSString *string in [emojis allKeys]) {
                if ([words containsObject:string]) {
                    emoji = emojis[string];
                    break;
                }
            }
            if (!emoji) {
                NSArray *randomEmojis = @[@"🙏", @"🔥", @"🥺", @"😇", @"🤔", @"❤️", @"💯", @"👀", @"🤩", @"😂"];
                NSUInteger rnd = arc4random() % [randomEmojis count];
                emoji = [randomEmojis objectAtIndex:rnd];
            }
            
            if (![mutableSuggestions containsObject:emoji]) {
                [mutableSuggestions insertObject:emoji atIndex:0];
            }
        }
        
        wait(0.1, ^{
            self.replySuggestions = mutableSuggestions;
        });
    }];
}

- (void)setReplySuggestions:(NSArray *)replySuggestions {
    if (replySuggestions != _replySuggestions) {
        NSInteger numberOfRowsInFirstSection_before = [self.tableView numberOfRowsInSection:0];
        
        _replySuggestions = replySuggestions;
        
        NSInteger numberOfRowsInFirstSection_after = [self numberOfRowsInFirstSection];
        
        if (numberOfRowsInFirstSection_before == 0 ||
            numberOfRowsInFirstSection_after == 0) return;
        
        if (numberOfRowsInFirstSection_before > numberOfRowsInFirstSection_after) {
            // remove
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.parentPosts.count+1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else if (numberOfRowsInFirstSection_before < numberOfRowsInFirstSection_after) {
            // add
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.parentPosts.count+1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else if (numberOfRowsInFirstSection_after == self.parentPosts.count + 2) {
            // reload
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.parentPosts.count+1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
    }
}

@end
