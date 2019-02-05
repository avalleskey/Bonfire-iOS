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
#import "ExpandedPostCell.h"
#import "InsightsLogger.h"

@interface PostViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;

@property (strong, nonatomic) ErrorView *errorView;
@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property (nonatomic, strong) NSMutableArray *posts;
@property (strong, nonatomic) ComplexNavigationController *launchNavVC;

@end

@implementation PostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.launchNavVC = (ComplexNavigationController *)self.navigationController;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSString *themeCSS;
    if (self.post.attributes.status.postedIn != nil) {
        NSLog(@"postedIn: %@", self.post.attributes.status.postedIn);
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
    
    if (tempPost != nil && tempPost.attributes.details.parent == self.post.identifier && tempPost.attributes.details.parent != 0) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        [self.tableView.stream prependTempPost:tempPost];
        [self.tableView refresh];
        
        [self.tableView setContentOffset:CGPointMake(0, -1 * (self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height)) animated:YES];
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    if (post != nil && post.attributes.details.parent == self.post.identifier && post.attributes.details.parent != 0) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        [self.tableView.stream updateTempPost:tempId withFinalPost:post];
        [self.tableView refresh];
        
        /*
        // update Post object
        PostSummaries *summaries = self.post.attributes.summaries == nil ? [[PostSummaries alloc] init] : self.post.attributes.summaries;
        //summaries.replies = summaries.replies == nil ? @[post] : [summaries.replies arrayByAddingObject:post];
        summaries.counts.replies = summaries.counts.replies + 1;
        self.post.attributes.summaries = summaries;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:self.post];*/
    }
}
// TODO: Allow tap to retry for posts
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && tempPost.attributes.details.parent == self.post.identifier && tempPost.attributes.details.parent != 0) {
        // TODO: Check for image as well
        [self.tableView.stream removeTempPost:tempPost.tempId];
        [self.tableView refresh];
        self.errorView.hidden = (self.tableView.stream.posts.count != 0);
    }
}

- (void)postUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[Post class]]) {
        Post *post = (Post *)notification.object;
        if (post.identifier == self.post.identifier) {
            // match
            self.post = post;
            self.post.rowHeight = 0;
            self.tableView.parentObject = post;
            [self.tableView refresh];
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
        self.tableView.parentObject = self.post;
        [self.tableView refresh];
        
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
    self.tableView.loading = false;
    self.tableView.loadingMore = true;
    [self.tableView refresh];
    
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
                
                NSLog(@"response dataaaaa: %@", responseData);
                
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
                
                NSLog(@"self.post: %@", self.post);
                if (postError) {
                    NSLog(@"postError; %@", postError);
                }
                
                self.tableView.parentObject = self.post;
                [self.tableView refresh];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomViewController / getRoom() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.errorView.hidden = false;
                
                [self.errorView updateType:ErrorViewTypeGeneral];
                [self.errorView updateTitle:@"Error Loading Post"];
                [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
                
                [self positionErrorView];
                
                self.loading = false;
                self.tableView.loading = false;
                self.tableView.loadingMore = false;
                self.tableView.error = true;
                [self.tableView refresh];
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
        self.tableView.loading = false;
        self.tableView.loadingMore = false;
        [self.tableView refresh];
        
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
    self.composeInputView = [[ComposeInputView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.composeInputView.frame = CGRectMake(0, self.view.frame.size.height - 52, self.view.frame.size.width, 190);
    self.composeInputView.parentViewController = self;

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
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.textView.delegate = self;
    self.composeInputView.tintColor = [self.theme isEqual:[UIColor whiteColor]] ? [UIColor colorWithWhite:0.2f alpha:1] : self.theme;
    self.composeInputView.postButton.backgroundColor = self.composeInputView.tintColor;
    self.composeInputView.addMediaButton.tintColor = self.composeInputView.tintColor;
}
- (void)textViewDidChange:(UITextView *)textView {
    if ([textView isEqual:self.composeInputView.textView]) {
        NSLog(@"text view did change");
        [self.composeInputView resize:false];
        
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        CGFloat bottomPadding = window.safeAreaInsets.bottom;
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + bottomPadding, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
        
        if (textView.text.length > 0) {
            NSLog(@"show post button");
            [self.composeInputView showPostButton];
        }
        else {
            NSLog(@"hide post button");
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
        if (self.post.attributes.status.postedIn) {
            [[Session sharedInstance] createPost:params postingIn:self.post.attributes.status.postedIn replyingTo:self.post];
        }
        else {
            [[Session sharedInstance] createPost:params postingIn:nil replyingTo:self.post];
        }
        
        self.composeInputView.textView.text = @"";
        [self.composeInputView hidePostButton];
        [self.composeInputView.textView resignFirstResponder];
        self.composeInputView.media = [[NSMutableArray alloc] init];
        [self.composeInputView hideMediaTray];
    }
}

- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.bounds.size.width, collapsed_inputViewHeight);
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}

- (void)getRepliesWithNextCursor:(NSString *)nextCursor {
    if ([nextCursor isEqualToString:@""]) {
        self.loading = false;
        
        self.tableView.loading = false;
        self.tableView.loadingMore = false;
        
        [self.tableView refresh];
        
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
            
            // NSLog(@"params: %@", params);
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // NSLog(@"CommonTableViewController / getReplies() success! ✅");
                PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
                if (page.data.count == 0) {
                    self.tableView.reachedBottom = true;
                }
                else {
                    [self.tableView.stream appendPage:page];
                }
                
                self.errorView.hidden = true;
                
                self.loading = false;
                
                self.tableView.loading = false;
                self.tableView.loadingMore = false;
                
                [self.tableView refresh];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"FeedViewController / getReplies() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.loading = false;
                self.tableView.userInteractionEnabled = true;
                [self.tableView refresh];
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
    self.tableView = [[RSTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataType = RSTableViewTypePost;
    self.tableView.parentObject = self.post;
    self.tableView.paginationDelegate = self;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.refreshControl = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.tintColor = self.theme;
    
    [self.view addSubview:self.tableView];
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.tableView.stream.posts.count > 0) {
        [self getRepliesWithNextCursor:[self.tableView.stream.pages lastObject].meta.paging.next_cursor];
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
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        [self.composeInputView resize:false];
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.composeInputView.frame.size.height, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
        
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
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
    actionSheet.view.tintColor = [UIColor colorWithWhite:0.2 alpha:1];
    
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
    [cancel setValue:self.theme forKey:@"titleTextColor"];
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
