//
//  ProfileViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "ProfileViewController.h"
#import "LauncherNavigationViewController.h"
#import "ErrorView.h"
#import "ProfileHeaderCell.h"

#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface ProfileViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;

@property (strong, nonatomic) LauncherNavigationViewController *launchNavVC;
@property (strong, nonatomic) ErrorView *errorView;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.launchNavVC = (LauncherNavigationViewController *)self.navigationController;
    
    self.title = self.user.attributes.details.displayName;
    self.view.tintColor = self.theme;
    
    self.view.backgroundColor = [UIColor whiteColor];
    // self.navigationItem.hidesBackButton = true;
    
    [self setupTableView];
    [self setupErrorView];
    if ([self.user.identifier isKindOfClass:[NSString class]] &&
        [self.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier])
    {
        [self setupComposeInputView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userProfileUpdated:) name:@"userProfileUpdated" object:nil];
    }
    
    self.manager = [HAWebService manager];
    self.loading = true;
    
    if ([self canViewPosts]) {
        [self getPosts];
    }
    else {
        self.composeInputView.hidden = true;
        
        self.errorView.hidden = false;
        
        self.loading = false;
        self.tableView.loading = false;
        self.tableView.loadingMore = false;
        [self.tableView refresh];
        
        BOOL isBlocked = false;
        BOOL isPrivate = false;
        
        if (isBlocked) { // blocked by User
            [self.errorView updateTitle:[NSString stringWithFormat:@"@%@ Blocked You", self.user.attributes.details.identifier]];
            [self.errorView updateDescription:[NSString stringWithFormat:@"You are blocked from viewing and interacting with %@", self.user.attributes.details.displayName]];
            [self.errorView updateType:ErrorViewTypeLocked];
        }
        else if (isPrivate) { // not blocked, not follower
            // private room but not a member yet
            [self.errorView updateTitle:@"Private User"];
            [self.errorView updateDescription:[NSString stringWithFormat:@"Only confirmed followers have access to @%@'s posts and complete profile", self.user.attributes.details.identifier]];
            [self.errorView updateType:ErrorViewTypeLocked];
        }
        else {
            [self.errorView updateTitle:@"User Not Found"];
            [self.errorView updateDescription:@"We couldn’t find the User\nyou were looking for"];
            [self.errorView updateType:ErrorViewTypeNotFound];
            
            [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.launchNavVC.infoButton.alpha = 0;
                self.launchNavVC.moreButton.alpha = 0;
            } completion:^(BOOL finished) {
            }];
        }
        
        [self positionErrorView];
    }
}

- (BOOL)canViewPosts {
    return true;
}

- (void)viewWillAppear:(BOOL)animated {
    [self styleOnAppear];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)userProfileUpdated:(NSNotificationCenter *)sender {
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    
    [self.launchNavVC updateBarColor:@"888888" withAnimation:2 statusBarUpdateDelay:0];
    
    self.composeInputView.addMediaButton.tintColor = [Session sharedInstance].themeColor;
    self.composeInputView.postButton.tintColor = [Session sharedInstance].themeColor;
}

- (void)openProfileActions {
    BOOL userIsBlocked   = false;
    
    // Share to...
    // Turn on/off post notifications
    // Share on Instagram
    // Share on Twitter
    // Share on iMessage
    // Report Room
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"@%@", self.user.attributes.details.identifier] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    actionSheet.view.tintColor = [UIColor colorWithWhite:0.2f alpha:1];
    
    // 1.A.* -- Any user, any page, any following state
    UIAlertAction *shareUser = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Share @%@ via...", self.user.attributes.details.identifier] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share user");
        
        //[self showShareUserSheet];
    }];
    [actionSheet addAction:shareUser];
    
    UIAlertAction *blockUsername = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@", userIsBlocked ? @"Unblock" : @"Block"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // confirm action
        UIAlertController *saveAndOpenInstaConfirm = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", userIsBlocked ? @"Unblock" : @"Block" , self.user.attributes.details.displayName] message:[NSString stringWithFormat:@"Are you sure you would like to block @%@?", self.user.attributes.details.identifier] preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *alertConfirm = [UIAlertAction actionWithTitle:@"Block" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"switch user block state");
        }];
        [saveAndOpenInstaConfirm addAction:alertConfirm];
        
        UIAlertAction *alertCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"cancel");
        }];
        [saveAndOpenInstaConfirm addAction:alertCancel];
        
        [self.navigationController presentViewController:saveAndOpenInstaConfirm animated:YES completion:nil];
    }];
    [actionSheet addAction:blockUsername];
    
    UIAlertAction *reportUsername = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Report"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // confirm action
        UIAlertController *saveAndOpenTwitterConfirm = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Report %@", self.user.attributes.details.displayName] message:[NSString stringWithFormat:@"Are you sure you would like to report @%@?", self.user.attributes.details.identifier] preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *alertConfirm = [UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"report user");
        }];
        [saveAndOpenTwitterConfirm addAction:alertConfirm];
        
        UIAlertAction *alertCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"cancel report user");
        }];
        [saveAndOpenTwitterConfirm addAction:alertCancel];
        
        [self.navigationController presentViewController:saveAndOpenTwitterConfirm animated:YES completion:nil];
    }];
    [actionSheet addAction:reportUsername];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel");
    }];
    [cancel setValue:self.theme forKey:@"titleTextColor"];
    [actionSheet addAction:cancel];
    
    [self.navigationController presentViewController:actionSheet animated:YES completion:nil];
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Profile Not Found" description:@"We couldn’t find the profile\nyou were looking for" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    [self.view addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        if ([self canViewPosts]) {
            self.errorView.hidden = true;
            
            self.tableView.loading = true;
            self.tableView.loadingMore = false;
            [self.tableView refresh];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self getPosts];
            });
        }
    }];
}

- (void)positionErrorView {
    ProfileHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat heightOfHeader = headerCell.frame.size.height;
    self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 64, self.errorView.frame.size.width, self.errorView.frame.size.height);
}

- (void)setupComposeInputView {
    // only show compose input view if current user
    self.composeInputView = [[ComposeInputView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.composeInputView.frame = CGRectMake(0, self.view.frame.size.height - 52, self.view.frame.size.width, 190);
    self.composeInputView.parentViewController = self;

    self.composeInputView.addMediaButton.tintColor = [Session sharedInstance].themeColor;
    self.composeInputView.postButton.tintColor = [Session sharedInstance].themeColor;
    
    [self.composeInputView bk_whenTapped:^{
        if (![self.composeInputView isActive]) {
            [self.composeInputView setActive:true];
        }
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.textView.delegate = self;
    self.composeInputView.tintColor = self.view.tintColor;
}
- (void)textViewDidChange:(UITextView *)textView {
    if ([textView isEqual:self.composeInputView.textView]) {
        NSLog(@"text view did change");
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

- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(0, self.view.frame.size.height - collapsed_inputViewHeight, self.view.frame.size.width, collapsed_inputViewHeight);
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height, 0);
    
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.center.y - bottomPadding);
}

- (void)getPosts {
    if (self.user.identifier) {
        self.errorView.hidden = true;
        self.tableView.hidden = false;
        
        NSString *url = [NSString stringWithFormat:@"%@/%@/users/%@/posts", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.user.attributes.details.identifier]; // sample data
        
        [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
            if (success) {
                [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                
                [self.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    // NSLog(@"CommonTableViewController / getPosts() success! ✅");
                    
                    NSLog(@"responseObject: %@", responseObject);
                    
                    NSArray *responseData = (NSArray *)responseObject[@"data"];

                    self.tableView.data = [[NSMutableArray alloc] initWithArray:responseData];
                    
                    self.loading = false;
                    
                    self.tableView.loading = false;
                    [self.tableView refresh];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"FeedViewController / getPosts() - error: %@", error);
                    //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    
                    self.loading = false;
                    [self.tableView refresh];
                }];
            }
        }];
    }
    else {
        self.errorView.hidden = false;
        self.tableView.hidden = true;
        
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.launchNavVC.infoButton.alpha = 0;
            self.launchNavVC.moreButton.alpha = 0;
        } completion:^(BOOL finished) {
        }];
    }
}
- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataType = tableCategoryProfile;
    self.tableView.parentObject = self.user;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tableView];
    
    UIView *headerHack = [[UIView alloc] initWithFrame:CGRectMake(0, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    headerHack.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    [self.tableView addSubview:headerHack];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return true;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    return true;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + bottomPadding, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        [self.composeInputView resize:false];
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.composeInputView.frame.size.height, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    } completion:nil];
}

/*
 - (void)textViewDidChange:(UITextView *)textView {
 //[self sentimentAnalysisUpdate];
 
 NSString *temp = textView.text;
 
 //    if([[textView text] length] > self.composeInputView.currentTextViewLimit || self.composeInputView.preventTyping){
 //        textView.text = [temp substringToIndex:[temp length] - 1];
 //    }
 //    else {
 ////        [self.composeInputView updateTextView:self.composeInputView.composeTextView];
 //
 ////        // -- SEND BUTTON ON/OFF
 ////        NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
 ////        if (self.composeInputView.textView.text.length == 0 || [[self.composeInputView.composeTextView.text stringByTrimmingCharactersInSet: set] length] == 0) {
 ////            self.composeInputView.sendButton.enabled = false;
 ////            self.composeInputView.sendButton.userInteractionEnabled = false;
 ////        }
 ////        else {
 ////            self.composeInputView.sendButton.enabled = true;
 ////            self.composeInputView.sendButton.userInteractionEnabled = true;
 ////        }
 //    }
 }*/
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
