//
//  LinkConversationsViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "LinkConversationsViewController.h"
#import "UINavigationItem+Margin.h"
#import "SimpleNavigationController.h"
#import "BFVisualErrorView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "InsightsLogger.h"
#import "HAWebService.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>

#import "LinkPostCell.h"
#import "StreamPostCell.h"
#import "ReplyCell.h"
#import "AddReplyCell.h"
#import "ExpandThreadCell.h"
#import "PaginationCell.h"
#import "BFAlertController.h"
#import "PrivacySelectorTableViewController.h"
@import Firebase;

@interface LinkConversationsViewController () <PrivacySelectorDelegate> {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL loadingMore;

@property (nonatomic, strong) BFVisualErrorView *errorView;
@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property (nonatomic, assign) NSMutableArray *conversation;
@property (nonatomic, strong) UIActivityIndicatorView *parentPostSpinner;

@end

@implementation LinkConversationsViewController

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const postReplyReuseIdentifier = @"postReply";
static NSString * const postSubReplyReuseIdentifier = @"postSubReply";
static NSString * const parentPostReuseIdentifier = @"parentPost";
static NSString * const linkPostReuseIdentifier = @"linkPost";
static NSString * const addReplyCellIdentifier = @"addReplyCell";
static NSString * const expandRepliesCellIdentifier = @"expandRepliesCell";

static NSString * const paginationCellIdentifier = @"PaginationCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
        
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
        
    [self setupTableView];
    [self setupErrorView];
    
    self.view.tintColor = self.theme;
    [self.imagePreviewView viewWithTag:10].backgroundColor = self.view.tintColor;
        
    if (self.link) {
        if (!self.isPreview) {
            [self setupComposeInputView];
        }
        
        self.loading = true;
        [self loadLink];
    }
    
    // TODO: Update these methods
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Conversation" screenClass:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        if (self.isPreview) {
            self.composeInputView.hidden = true;
            [self hideComposeInputView];
        }
        
        [self styleOnAppear];
    }
    else {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInCampView];
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
}
- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.bounds.size.width, collapsed_inputViewHeight);
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, self.composeInputView.frame.size.height - bottomPadding + 12, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding, 0);
    
    //[self.imagePreviewView viewWithTag:10].backgroundColor = self.theme;
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
    _currentKeyboardFrame = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = _currentKeyboardFrame.size.height;
        
    [self updateComposeInputViewFrame];
    [self updateContentInsets];
}
- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        [self.composeInputView resize:false];
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.composeInputView.frame.size.height, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    } completion:^(BOOL finished) {
        [self updateContentInsets];
    }];
}
#pragma mark ↳ Post changes
- (void)postUpdated:(NSNotification *)notification {
    // TODO: implement proper method
//    if ([notification.object isKindOfClass:[Post class]] && ![notification.object isEqual:self.post]) {
//        Post *post = (Post *)notification.object;
//        if ([post.identifier isEqualToString:self.post.identifier]) {
//            NSLog(@"update that ish");
//            // match
//            self.post = post;
//
//            CGPoint offset = self.tableView.contentOffset;
//            [self.tableView reloadData];
//            [self.tableView layoutIfNeeded]; // Force layout so things are updated before resetting the contentOffset.
//            [self.tableView setContentOffset:offset];
//        }
//    }
}
- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    // TODO: implement proper method
    if (tempPost != nil && [tempPost.attributes.attachments.link.identifier isEqualToString:self.link.identifier]) {
        //        self.errorView.hidden = true;
        //
        //        [self.bf_tableView.stream addTempPost:tempPost];
        //        [self.bf_tableView refreshAtTop];
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController setProgress:0.7 animated:YES];
        }
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    if (post != nil && [post.attributes.attachments.link.identifier isEqualToString:self.link.identifier]) {
        // TODO: Check for image as well
        [self.tableView.stream removeLoadedCursor:self.tableView.stream.prevCursor];
        
        [self.tableView.stream removeTempPost:tempId];
                
        [self getPostsWithCursor:StreamPagingCursorTypePrevious];
        
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController setProgress:1 animated:YES hideOnCompletion:true];
        }
    }
}
- (void)newPostFailed:(NSNotification *)notification {
    // TODO: Allow tap to retry for posts
    Post *tempPost = notification.object;
    
    // TODO: implement proper method
//    if (tempPost != nil && [tempPost.attributes.parentId isEqualToString:self.post.identifier] && tempPost.attributes.parentId.length > 0) {
//        // TODO: Check for image as well
//        [self.stream removeTempPost:tempPost.tempId];
//        if (self.post.attributes.summaries.counts.replies > 0 && self.tableView.stream.components.count == 0) {
//            self.post.attributes.summaries.counts.replies = 0;
//        }
//
//        [self.tableView reloadData];
//        self.errorView.hidden = (self.tableView.stream.components.count != 0);
//    }
}

#pragma mark - Load post
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
- (void)loadLink {
    if (self.link) {
        // fill in post info
        [self.tableView reloadData];
        [self.tableView layoutSubviews];
        
        if (!self.link.attributes) {
            [self getLink];
        }
        [self loadLinkQuotes];
    }
    else {
        // post not found
        self.tableView.hidden = true;
        
        self.errorView.hidden = false;
        
        BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Link Not Found" description:@"We couldn't find the link\nyou were looking for" actionTitle:nil actionBlock:nil];
        self.errorView.visualError = visualError;
        
        [self positionErrorView];
        
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            ((SimpleNavigationController *)self.navigationController).rightActionView.alpha = 0;
        } completion:^(BOOL finished) {
        }];
    }
}
- (void)getLink {
    [self.tableView reloadData];
    [self.tableView layoutSubviews];
    
    NSString *url = [NSString stringWithFormat:@"links/%@", self.link.identifier];
    
    NSLog(@"url: %@", url);
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
        
        self.errorView.hidden = true;
        
        //BFContext *contextBefore = self.link.attributes.context;
        
        // first page
        NSError *postError;
        
        self.link = [[BFLink alloc] initWithDictionary:responseData error:&postError];
        
//        if (contextBefore && !self.link.attributes.context) {
//            self.link.attributes.context = contextBefore;
//        }
        
        // update reply ability using camp
        [self updateComposeInputView];
        
        // update the theme color (in case we didn't know the Camp/Profile color before
        [self updateTheme];
        [self.tableView reloadData];
        
        if ([self.tableView isHidden]) {
            [self loadLinkQuotes];
        }
        
        // [[NSNotificationCenter defaultCenter] postNotificationName:@"LinkUpdated" object:self.link];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getCamp() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        
        if (statusCode == 404) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LinkDeleted" object:self.link];
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
- (void)loadLinkQuotes {
    if ([self canViewPost]) {
        [self getPostsWithCursor:StreamPagingCursorTypeNone];
    }
    else {
        [self hideComposeInputView];
        
        self.errorView.hidden = false;
        
        self.loading = false;
        /*self.tableView.loading = false;
        self.tableView.loadingMore = false;*/
        [self.tableView reloadData];
        
        ErrorViewType errorType = ErrorViewTypeGeneral;
        NSString *errorTitle = @"";
        NSString *errorDescription = @"";
        
        // TODO: use actual camp here
        Camp *camp = nil; //self.link.attributes.postedIn;
        if (camp != nil) {
            if (camp.attributes.isSuspended) { // Camp has been blocked
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
                self.tableView.hidden = true;
                self.errorView.hidden = false;
                
                errorType = ErrorViewTypeNotFound;
                errorTitle = @"Post Not Found";
                errorDescription = @"We couldn’t find the post\nyou were looking for";
                
                [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    ((SimpleNavigationController *)self.navigationController).rightActionView.alpha = 0;
                } completion:^(BOOL finished) {
                }];
            }
        }
        else {
            self.tableView.hidden = true;
            self.errorView.hidden = false;
            
            errorTitle = @"Post Not Found";
            errorDescription = @"We couldn’t find the post\nyou were looking for";
            errorType = ErrorViewTypeNotFound;
            
            [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                ((SimpleNavigationController *)self.navigationController).rightActionView.alpha = 0;
            } completion:^(BOOL finished) {
            }];
        }
        
        // update error view
        BFVisualError *visualError = [BFVisualError visualErrorOfType:errorType title:errorTitle description:errorDescription actionTitle:nil actionBlock:nil];
        self.errorView.visualError = visualError;
        
        [self positionErrorView];
    }
}
- (void)getPostsWithCursor:(StreamPagingCursorType)cursorType {
    NSString *url = [NSString stringWithFormat:@"links/%@/stream", self.link.identifier];

    NSLog(@"📲: %@", url);
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (cursorType == StreamPagingCursorTypeNext) {
        [params setObject:self.tableView.stream.nextCursor forKey:@"next_cursor"];
    }
    else if (self.tableView.stream.prevCursor.length > 0) {
        [params setObject:self.tableView.stream.prevCursor forKey:@"prev_cursor"];
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
    
    self.tableView.loading = (self.tableView.stream.components.count == 0);
    if (self.tableView.loading) {
        self.errorView.hidden = true;
        [self.tableView hardRefresh:false];
        
        self.errorView.hidden = true;
        self.tableView.hidden = false;
    }
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.loading = false;
        self.tableView.loading = false;
        
        // NSLog(@"CommonTableViewController / getReplies() success! ✅");
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
        if (page.data.count > 0) {
            if (cursorType == StreamPagingCursorTypeNext) {
                [self.tableView.stream appendPage:page];
            }
            else {
                [self.tableView.stream prependPage:page];
            }
            
            if (cursorType == StreamPagingCursorTypeNext) {
                self.tableView.loadingMore = false;
                
                [self.tableView refreshAtBottom];
            }
            else {
                // previous currsor
                [self.tableView hardRefresh:false];
            }
        }
        
        self.errorView.hidden = (self.tableView.stream.components.count > 0);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self updateContentInsets];
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"FeedViewController / getReplies() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        
        NSData *failingData = (NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSInteger bonfireErrorCode = 0;
        if (failingData) {
            id json = [NSJSONSerialization JSONObjectWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] options:0 error:nil];
            if (json && json[@"error"] && json[@"error"][@"code"]) {
                bonfireErrorCode = [json[@"error"][@"code"] integerValue];
            }
        }
        
        if (statusCode == 404 || bonfireErrorCode == LINK_NOT_EXISTS) {
            [self.navigationController dismissViewControllerAnimated:true completion:^{
                BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Link Doesn't Exist" message:@"The link you're looking for doesn't exist" preferredStyle:BFAlertControllerStyleAlert];
                
                BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
                [actionSheet addAction:cancelActionSheet];
                
                [[Launcher topMostViewController] presentViewController:actionSheet animated:YES completion:nil];
            }];
            return;
        }
        
        self.loading = false;
        self.loadingMore = false;
        
        self.tableView.userInteractionEnabled = true;
        [self.tableView reloadData];
    }];
}

#pragma mark - Table view
- (void)setupTableView {
    self.tableView = [[BFComponentTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.extendedDelegate = self;
    self.tableView.insightSeenInLabel = InsightSeenInPostView;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.width, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, 70, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.refreshControl = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.tintColor = self.theme;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerClass:[LinkPostCell class] forCellReuseIdentifier:linkPostReuseIdentifier];
    
    [self.tableView.stream setTempPostPosition:PostStreamOptionTempPostPositionBottom];
    
    [self.view addSubview:self.tableView];
    
    self.parentPostSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.parentPostSpinner.color = [UIColor bonfireSecondaryColor];
    self.parentPostSpinner.frame = CGRectMake(self.view.frame.size.width / 2 - (self.parentPostSpinner.frame.size.width / 2), (-1 * self.parentPostSpinner.frame.size.height) - 16, self.parentPostSpinner.frame.size.width, self.parentPostSpinner.frame.size.height);
    self.parentPostSpinner.hidden = true;
    [self.tableView addSubview:self.parentPostSpinner];
    
    [self setupImagePreviewView];
}

- (void)setupImagePreviewView {
    self.imagePreviewView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 160)];
    self.imagePreviewView.sd_imageTransition = [SDWebImageTransition fadeTransition];
    self.imagePreviewView.backgroundColor = [UIColor fromHex:self.link.attributes.attribution.attributes.color];
    self.imagePreviewView.contentMode = UIViewContentModeScaleAspectFill;
    self.imagePreviewView.clipsToBounds = true;
    self.imagePreviewView.userInteractionEnabled = true;
    [self.imagePreviewView bk_whenTapped:^{
        [Launcher expandImageView:self.imagePreviewView];
    }];
    [self.view insertSubview:self.imagePreviewView belowSubview:self.tableView];
    UIView *overlayView = [[UIView alloc] initWithFrame:self.imagePreviewView.bounds];
    overlayView.backgroundColor = self.theme;
    overlayView.alpha = 0;
    overlayView.tag = 10;
    //[self.imagePreviewView addSubview:overlayView];
    [self updateImagePreviewView];
}
- (void)updateImagePreviewView {
    if (self.link.attributes.images.count > 0) {
        self.tableView.contentInset = UIEdgeInsetsMake(160, 0, self.tableView.contentInset.bottom, 0);
        [self.imagePreviewView sd_setImageWithURL:[NSURL URLWithString:self.link.attributes.images[0]]];
    }
    else {
        self.tableView.contentInset = UIEdgeInsetsMake(72, 0, self.tableView.contentInset.bottom, 0);
        self.imagePreviewView.image = nil;
    }
    self.imagePreviewView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.tableView.contentInset.top + (-1 * self.tableView.contentOffset.y));
    UIVisualEffectView *overlayView = [self.imagePreviewView viewWithTag:10];
    overlayView.frame = self.imagePreviewView.bounds;
}

#pragma mark ↳ Table view data source
- (CGFloat)numberOfRowsInFirstSection {
    return self.link ? 1 : 0;
}
- (UITableViewCell *)cellForRowInFirstSection:(NSInteger)row {
    if (row == 0 && self.link) {
        // expanded post
        LinkPostCell *cell = [self.tableView dequeueReusableCellWithIdentifier:linkPostReuseIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        
        if (cell == nil) {
            cell = [[LinkPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:linkPostReuseIdentifier];
        }
        
//        cell.tintColor = self.theme;
        cell.loading = self.loading;
        
        cell.link = self.link;
        cell.activityView.tintColor = [UIColor fromHex:self.link.attributes.attribution.attributes.color adjustForOptimalContrast:true];
        
        if ((int)[cell.activityView currentViewTag] == (int)PostActivityViewTagAddReply && self.tableView.stream.components.count > 0) {
            [cell.activityView next];
        }
        else if (!cell.activityView.active) {
            [cell.activityView start];
        }
                
        return cell;
    }
    
    return nil;
}
- (CGFloat)heightForRowInFirstSection:(NSInteger)row {
    if (row == 0 && self.link) {
        return [LinkPostCell heightForLink:self.link width:[UIScreen mainScreen].bounds.size.width];
    }
    
    return 0;
}

- (void)didSelectRowInFirstSection:(NSInteger)row {
    if (row == 0) {
        if (self.link) {
            [Launcher openURL:self.link.attributes.actionUrl];
        }
    }
}

- (void)tableViewDidScroll:(UITableView *)tableView {
    if (tableView == self.tableView) {
        [(SimpleNavigationController *)self.navigationController childTableViewDidScroll:self.tableView];
        
        if (self.tableView.contentOffset.y > (-1 * self.tableView.contentInset.top)) {
            self.imagePreviewView.frame = CGRectMake(0, 0.5 * (-self.tableView.contentOffset.y - self.tableView.contentInset.top), self.view.frame.size.width, self.tableView.contentInset.top);
        }
        else {
            self.imagePreviewView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.tableView.contentInset.top + (-self.tableView.contentOffset.y - self.tableView.contentInset.top));
        }
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return textView.text.length + (text.length - range.length) <= [Session sharedInstance].defaults.post.maxLength;
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
    self.composeInputView.textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    [self.composeInputView bk_whenTapped:^{
        if (![self.composeInputView isActive]) {
            [self.composeInputView setActive:true];
        }
    }];
    [self.composeInputView.postButton setImage:[[UIImage imageNamed:@"nextButtonIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.composeInputView.postButton bk_whenTapped:^{
        [self openPrivacySelector];
    }];
    [self.composeInputView.expandButton bk_whenTapped:^{
//        [Launcher openComposePost:self.post.attributes.postedIn inReplyTo:self.post withMessage:self.composeInputView.textView.text media:@[]];
        [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:@[] quotedObject:self.link];
    }];
    [self.composeInputView.replyingToLabel bk_whenTapped:^{
        // scroll to post you're replying to
        NSInteger i = 0;
        for (BFPostStreamComponent *component in self.tableView.stream.components) {
            if (component.post && component.post.identifier == self.composeInputView.replyingTo.identifier) {
                // scroll to this item!
                NSIndexPath* ipath = [NSIndexPath indexPathForRow:0 inSection:i+1];
                [self.tableView scrollToRowAtIndexPath:ipath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                
                break;
            }
            i++;
        }
        
        [self updateContentInsets];
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.tintColor = [self.theme isEqual:[UIColor whiteColor]] ? [UIColor bonfirePrimaryColor] : self.theme;
    self.composeInputView.defaultPlaceholder = @"Share this link...";
    [self.composeInputView setMediaTypes:@[BFMediaTypeGIF, BFMediaTypeText, BFMediaTypeImage]];
    
    self.composeInputView.postButton.backgroundColor = [UIColor bonfirePrimaryColor];
    self.composeInputView.postButton.tintColor = [UIColor whiteColor];
}
- (void)privacySelectionDidSelectToPost:(Camp *)selection {
    [self postMessageInCamp:selection];
}
- (void)openPrivacySelector {
    PrivacySelectorTableViewController *sitvc = [[PrivacySelectorTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    sitvc.delegate = self;
    sitvc.postOnSelection = true;
    sitvc.shareOnProfile = false;
    
    SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:sitvc];
    simpleNav.transitioningDelegate = [Launcher sharedInstance];
    simpleNav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:simpleNav animated:YES completion:nil];
}
- (void)postMessageInCamp:(Camp *)camp {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *message = self.composeInputView.textView.text;
    if (message.length > 0) {
        [params setObject:[Post trimString:message] forKey:@"message"];
    }
    if (self.composeInputView.media.objects.count > 0) {
        [params setObject:self.composeInputView.media forKey:@"media"];
    }
    if (self.link) {
        [params setObject:@{@"link": self.link.attributes.actionUrl} forKey:@"attachments"];
    }
    
    if (params.allKeys.count > 0) {
        // meets min. requirements
        PostAttachments *attachments = [[PostAttachments alloc] init];
        attachments.link = self.link;
        
        [BFAPI createPost:params postingIn:camp replyingTo:nil attachments:attachments];
        
        [self.composeInputView reset];
    }
}




- (void)updateComposeInputView {
    Camp *camp = self.link.attributes.attribution;
    
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
    return true;
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
        self.tableView.contentInset = UIEdgeInsetsZero;
    }
}

#pragma mark - Misc.
- (void)updateTheme {
    UIColor *theme = [UIColor fromHex:self.link.attributes.attribution.attributes.color];
    
    self.theme = theme;
    self.view.tintColor = theme;
    self.navigationController.view.tintColor = theme;
    self.tableView.tintColor = theme;
    
    UIColor *themeAdjustedForDarkMode = [UIColor fromHex:[UIColor toHex:theme] adjustForOptimalContrast:true];
    [UIView animateWithDuration:0.35f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        if (((SimpleNavigationController *)self.navigationController).topViewController == self) {
            [(SimpleNavigationController *)self.navigationController updateBarColor:theme animated:false];
        }
        
        self.composeInputView.textView.tintColor = themeAdjustedForDarkMode;
        self.composeInputView.postButton.backgroundColor = themeAdjustedForDarkMode;
        self.composeInputView.postButton.tintColor = [UIColor highContrastForegroundForBackground:self.composeInputView.postButton.backgroundColor];
        
        self.imagePreviewView.backgroundColor = theme;
    } completion:^(BOOL finished) {
    }];
    
    [self.imagePreviewView viewWithTag:10].backgroundColor = self.theme;
}

- (void)setupErrorView {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Error loading quotes" description:@"Check your network settings and try again" actionTitle:nil actionBlock:nil];
    
    self.errorView = [[BFVisualErrorView alloc] initWithVisualError:visualError];
    [self positionErrorView];
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}
- (BOOL)canViewPost {
    Camp *camp = nil; //self.link.attributes.postedIn;
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
- (void)positionErrorView {
    LinkPostCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat heightOfHeader = headerCell.frame.size.height;
    self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 48, self.errorView.frame.size.width, self.errorView.frame.size.height);
}
- (void)updateContentInsets {
    CGFloat topPadding = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    CGFloat bottomPadding = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    
    CGFloat newComposeInputViewY = (self.currentKeyboardHeight > 0 ? self.composeInputView.frame.origin.y + topPadding : self.view.frame.size.height - self.composeInputView.frame.size.height +   bottomPadding);
    
    CGFloat parentPostOffset = 0;
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, self.view.frame.size.height - newComposeInputViewY + (self.composeInputView.replyingTo != nil ? self.composeInputView.replyingToLabel.frame.size.height : 0) + parentPostOffset, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.height - newComposeInputViewY + (self.composeInputView.replyingTo != nil ? self.composeInputView.replyingToLabel.frame.size.height : 0), 0);
}
- (void)updateComposeInputViewFrame {
    CGFloat bottomPadding = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    
    CGFloat newComposeInputViewY = self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + ([self.composeInputView.textView isFirstResponder] ? bottomPadding : 0);
            
    self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, newComposeInputViewY, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
}

- (void)setLink:(BFLink *)link {
    if (link != _link) {
        _link = link;
        
        [self updateImagePreviewView];
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)){
    if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[PostCell class]]) {
        Post *post = ((PostCell *)[tableView cellForRowAtIndexPath:indexPath]).post;
        
        if (post) {
            NSMutableArray *actions = [NSMutableArray new];
            if ([post.attributes.context.post.permissions canReply]) {
                UIAction *replyAction = [UIAction actionWithTitle:@"Reply" image:[UIImage systemImageNamed:@"arrowshape.turn.up.left"] identifier:@"reply" handler:^(__kindof UIAction * _Nonnull action) {
                    wait(0, ^{
                        [Launcher openComposePost:post.attributes.postedIn inReplyTo:post withMessage:nil media:nil  quotedObject:nil];
                    });
                }];
                [actions addObject:replyAction];
            }
            
//            UIAction *quoteAction = [UIAction actionWithTitle:@"Quote" image:[UIImage systemImageNamed:@"quote.bubble"] identifier:@"quote" handler:^(__kindof UIAction * _Nonnull action) {
//                wait(0, ^{
//                    [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil  quotedObject:post];
//                });
//            }];
//            [actions addObject:quoteAction];
            
            if (post.attributes.postedIn) {
                UIAction *openCamp = [UIAction actionWithTitle:@"Open Camp" image:[UIImage systemImageNamed:@"number"] identifier:@"open_camp" handler:^(__kindof UIAction * _Nonnull action) {
                    wait(0, ^{
                        Camp *camp = [[Camp alloc] initWithDictionary:[post.attributes.postedIn toDictionary] error:nil];
                        
                        [Launcher openCamp:camp];
                    });
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

@end
