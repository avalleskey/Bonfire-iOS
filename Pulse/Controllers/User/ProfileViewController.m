//
//  ProfileViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "ProfileViewController.h"
#import "ComplexNavigationController.h"
#import "SimpleNavigationController.h"
#import "ErrorView.h"
#import "ProfileHeaderCell.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "SettingsTableViewController.h"
#import "InsightsLogger.h"
#import "ProfileCampsListViewController.h"
#import "HAWebService.h"

#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
@import Firebase;

@interface ProfileViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;

@property (nonatomic, strong) ComplexNavigationController *launchNavVC;
@property (strong, nonatomic) ErrorView *errorView;
@property (nonatomic) BOOL userDidRefresh;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.tintColor = self.theme;
    
    self.launchNavVC = (ComplexNavigationController *)self.navigationController;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    self.view.backgroundColor = [UIColor headerBackgroundColor];
    
    [self setupTableView];
    [self setupErrorView];
    
    [self setupComposeInputView];
    
    self.loading = true;
    [self loadUser];
    
    if ([self isCurrentUser]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userContextUpdated:) name:@"UserContextUpdated" object:nil];
    }
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Profile" screenClass:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self styleOnAppear];
    
    if (self.view.tag == 1) {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInProfileView];
    }
    else {
        self.view.tag = 1;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.tableView];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        [self.tableView.stream addTempPost:tempPost];
        [self.tableView refresh];
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    if (post != nil) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        [self.tableView.stream removeTempPost:tempId];
        
        [self getPostsWithCursor:PostStreamPagingCursorTypePrevious];
    }
}
// TODO: Allow tap to retry for posts
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil) {
        // TODO: Check for image as well
        [self.tableView.stream removeTempPost:tempPost.tempId];
        [self.tableView refresh];
        self.errorView.hidden = (self.tableView.stream.posts.count != 0);
    }
}

- (void)userUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        if ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            self.user = [Session sharedInstance].currentUser;
            self.tableView.parentObject = [Session sharedInstance].currentUser;
            
            [self.tableView.stream updateUserObjects:user];
            
            [self updateTheme];
            
            [self.tableView refresh];
            
            [self positionErrorView];
        }
    }
}
- (void)userContextUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        self.user = user;
        self.tableView.parentObject = self.user;
        
        [self.tableView.stream updateUserObjects:user];
        
        [self.tableView refresh];
    }
}

- (NSString *)userIdentifier {
    if (self.user.identifier != nil) return self.user.identifier;
    if (self.user.attributes.details.identifier != nil) return self.user.attributes.details.identifier;
    
    return nil;
}
- (NSString *)matchingCurrentUserIdentifier {
    // return matching identifier type for the current user
    if (self.user.identifier != nil) return [Session sharedInstance].currentUser.identifier;
    if (self.user.attributes.details.identifier != nil) return [Session sharedInstance].currentUser.attributes.details.identifier;
    
    return nil;
}

- (BOOL)isCurrentUser {
    return [self userIdentifier] != nil && [[self userIdentifier] isEqualToString:[self matchingCurrentUserIdentifier]];
}
- (BOOL)canViewPosts {
    return true;
}

- (void)setupComposeInputView {
    CGFloat bottomPadding = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView = [[ComposeInputView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.frame.size.width, collapsed_inputViewHeight)];
    self.composeInputView.hidden = true;
    
    self.composeInputView.parentViewController = self;
    self.composeInputView.postButton.backgroundColor = [self.theme isEqual:[UIColor whiteColor]] ? [UIColor bonfireBlack] : self.theme;
    self.composeInputView.addMediaButton.tintColor = self.composeInputView.postButton.backgroundColor;
    self.composeInputView.textView.tintColor = self.composeInputView.postButton.backgroundColor;
    
    [self.composeInputView bk_whenTapped:^{
        if (![self.composeInputView isActive]) {
            [self.composeInputView setActive:true];
        }
    }];
    [self.composeInputView.postButton bk_whenTapped:^{
        [self postMessage];
    }];
    [self.composeInputView.expandButton bk_whenTapped:^{
        NSString *message = self.composeInputView.textView.text;
        if (message.length == 0 && ![self isCurrentUser]) {
            message = [NSString stringWithFormat:@"@%@ ", self.user.attributes.details.identifier];
        }
        [Launcher openComposePost:nil inReplyTo:nil withMessage:message media:nil];
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.textView.delegate = self;
    self.composeInputView.tintColor = self.view.tintColor;
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    self.tableView.inputView = self.composeInputView;
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
- (void)updateComposeInputView {
    if ([self canViewPosts]) {
        [self showComposeInputView];
        [self.composeInputView updatePlaceholders];
    }
    else {
        [self hideComposeInputView];
    }
}
- (void)showComposeInputView {
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    if (self.composeInputView.isHidden) {
        self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        self.composeInputView.hidden = false;
        
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}
- (void)hideComposeInputView {
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, 0, self.tableView.contentInset.right);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    if (!self.composeInputView.isHidden) {
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        } completion:^(BOOL finished) {
            self.composeInputView.hidden = true;
        }];
    }
}
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (![self isCurrentUser] && self.composeInputView.textView.text.length == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.composeInputView.textView.text = [NSString stringWithFormat:@"@%@ ", self.user.attributes.details.identifier];
            
            self.composeInputView.textView.selectedRange = NSMakeRange(self.composeInputView.textView.text.length, 0);
            
            [self.composeInputView updatePlaceholders];
        });
    }
    
    UIView *tapToDismissView = [self.view viewWithTag:888];
    if (!tapToDismissView) {
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
    }];
    UISwipeGestureRecognizer *swipeDownGesture = [[UISwipeGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        [textView resignFirstResponder];
    }];
    swipeDownGesture.direction = UISwipeGestureRecognizerDirectionDown;
    [tapToDismissView addGestureRecognizer:swipeDownGesture];
    
    return true;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (![self isCurrentUser] && (self.composeInputView.textView.text.length == 0 || [[self stringByRemovingLeadingAndTrailingWhiteSpaces:self.composeInputView.textView.text] isEqualToString:[@"@" stringByAppendingString:self.user.attributes.details.identifier]])) {
        self.composeInputView.textView.text = @"";
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.composeInputView updatePlaceholders];
        });
    }
    
    UIView *tapToDismissView = [self.view viewWithTag:888];
    
    if (self.loading) {
        self.tableView.scrollEnabled = false;
    }
    else {
        self.tableView.scrollEnabled = true;
    }
    
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        tapToDismissView.alpha = 0;
    } completion:^(BOOL finished) {
        [tapToDismissView removeFromSuperview];
    }];
    
    return true;
}
- (NSString*)stringByRemovingLeadingAndTrailingWhiteSpaces:(NSString*)string {
    NSArray * components = [string componentsSeparatedByString:@" "];
    
    if([components count] == 1) {
        return string;
    }
    
    NSUInteger originalLength = [string length];
    unichar buffer[originalLength+1];
    [string getCharacters:buffer range:NSMakeRange(0, originalLength)];
    
    NSMutableString * newStringNoLeadingSpace = [NSMutableString string];
    BOOL goToStripTrailing = NO;
    for(int i = 0; i < originalLength; i++) {
        NSLog(@"%C", buffer[i]);
        NSString * newCharString = [NSString stringWithFormat:@"%c", buffer[i]];
        if(goToStripTrailing == NO && [newCharString isEqualToString:@" "]) continue;
        goToStripTrailing = YES;
        [newStringNoLeadingSpace appendString:newCharString];
    }
    
    NSUInteger newLength = [newStringNoLeadingSpace length];
    NSMutableString * newString = [NSMutableString string];
    unichar bufferSecondPass[newLength+1];
    [newStringNoLeadingSpace getCharacters:bufferSecondPass range:NSMakeRange(0, newLength)];
    
    int locationOfLastCharacter = (int)newLength;
    for(int i = (int)newLength - 1; i >= 0; i--) {
        NSLog(@"%C", bufferSecondPass[i]);
        NSString * newCharString = [NSString stringWithFormat:@"%c", bufferSecondPass[i]];
        locationOfLastCharacter = i+1;
        if(![newCharString isEqualToString:@" "]) break;
    }
    
    NSRange range = NSMakeRange(0, locationOfLastCharacter);
    
    newString = [[NSString stringWithString:[newStringNoLeadingSpace substringWithRange:range]] copy];
    
    return newString;
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
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        [self.composeInputView resize:false];
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.composeInputView.frame.size.height, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    } completion:nil];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return textView.text.length + (text.length - range.length) <= [Session sharedInstance].defaults.post.maxLength.soft;
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
        [BFAPI createPost:params postingIn:nil replyingTo:nil];
        
        [self.composeInputView reset];
    }
}

- (void)openProfileActions {
    BOOL userIsBlocked = [self isCurrentUser] ? false : [self.user.attributes.context.me.status isEqualToString:USER_STATUS_BLOCKS];
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"\n\n\n\n\n\n" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    CGFloat margin = 8.0f;
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(margin, 0, actionSheet.view.bounds.size.width - margin * 4, 140.f)];
    BFAvatarView *userAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(customView.frame.size.width / 2 - 32, 24, 64, 64)];
    userAvatar.user = self.user;
    [customView addSubview:userAvatar];
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 96, customView.frame.size.width - 32, 20)];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightSemibold];
    nameLabel.textColor = [UIColor blackColor];
    nameLabel.text = self.user.attributes.details.displayName;
    [customView addSubview:nameLabel];
    [actionSheet.view addSubview:customView];
    
    if (![self isCurrentUser]) {
        UIAlertAction *mention = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Mention @%@", self.user.attributes.details.identifier] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [Launcher openComposePost:nil inReplyTo:nil withMessage:[NSString stringWithFormat:@"@%@ ", self.user.attributes.details.identifier] media:nil];
        }];
        [actionSheet addAction:mention];
    }
    
    if (![self isCurrentUser] && ([self.user.attributes.context.me.status isEqualToString:USER_STATUS_FOLLOWS] || [self.user.attributes.context.me.status isEqualToString:USER_STATUS_FOLLOW_BOTH])) {
        BOOL userPostNotificationsOn = self.user.attributes.context.me.follow.me.subscription != nil;
        UIAlertAction *togglePostNotifications = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Turn %@ Post Notifications", userPostNotificationsOn ? @"Off" : @"On"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"toggle post notifications");
            // confirm action
            if ([Session sharedInstance].deviceToken.length > 0) {
                if (userPostNotificationsOn) {
                    [BFAPI unsubscribeFromUser:self.user completion:^(BOOL success, User *_Nullable user) {
                        if (success && user) {
                            self.user = user;
                            NSLog(@"user updated!");
                        }
                    }];
                }
                else {
                    [BFAPI subscribeToUser:self.user completion:^(BOOL success, User *_Nullable user) {
                        if (success && user) {
                            self.user = user;
                            NSLog(@"user updated! subscribed now....");
                        }
                    }];
                }
            }
            else {
                // confirm action
                UIAlertController *notificationsNotice = [UIAlertController alertControllerWithTitle:@"Notifications Not Enabled" message:@"In order to enable Post Notifications, you must turn on notifications for Bonfire in the iOS Settings" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *alertCancel = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                }];
                [notificationsNotice addAction:alertCancel];
                
                [self.navigationController presentViewController:notificationsNotice animated:YES completion:nil];
            }
        }];
        [actionSheet addAction:togglePostNotifications];
    }
    
    // 1.A.* -- Any user, any page, any following state
    UIAlertAction *shareUser = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Share %@ via...", [self isCurrentUser] ? @"your profile" : [NSString stringWithFormat:@"@%@", self.user.attributes.details.identifier]] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share user");
        
        [Launcher shareUser:self.user];
    }];
    [actionSheet addAction:shareUser];
    
    if (![self isCurrentUser]) {
        UIAlertAction *blockUsername = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@", userIsBlocked ? @"Unblock" : @"Block"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // confirm action
            UIAlertController *alertConfirmController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", userIsBlocked ? @"Unblock" : @"Block" , self.user.attributes.details.displayName] message:[NSString stringWithFormat:@"Are you sure you would like to block @%@?", self.user.attributes.details.identifier] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *alertConfirm = [UIAlertAction actionWithTitle:userIsBlocked ? @"Unblock" : @"Block" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                if (userIsBlocked) {
                    [BFAPI unblockUser:self.user completion:^(BOOL success, id responseObject) {
                        if (success) {
                            // NSLog(@"success unblocking!");
                        }
                        else {
                            NSLog(@"error unblocking ;(");
                        }
                    }];
                }
                else {
                    [BFAPI blockUser:self.user completion:^(BOOL success, id responseObject) {
                        if (success) {
                            // NSLog(@"success blocking!");
                        }
                        else {
                            NSLog(@"error blocking ;(");
                        }
                    }];
                }
            }];
            [alertConfirmController addAction:alertConfirm];
            
            UIAlertAction *alertCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [alertConfirmController addAction:alertCancel];
            
            [self.navigationController presentViewController:alertConfirmController animated:YES completion:nil];
        }];
        [actionSheet addAction:blockUsername];
        
        UIAlertAction *reportUsername = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Report"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // confirm action
            UIAlertController *saveAndOpenTwitterConfirm = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Report %@", self.user.attributes.details.displayName] message:[NSString stringWithFormat:@"Are you sure you would like to report @%@?", self.user.attributes.details.identifier] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *alertConfirm = [UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"report user");
                [BFAPI reportUser:self.user completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // update the state to blocked
                        
                    }
                    else {
                        // error reporting user
                    }
                }];
            }];
            [saveAndOpenTwitterConfirm addAction:alertConfirm];
            
            UIAlertAction *alertCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"cancel report user");
                
                // TODO: Verify this closes both action sheets
            }];
            [saveAndOpenTwitterConfirm addAction:alertCancel];
            
            [self.navigationController presentViewController:saveAndOpenTwitterConfirm animated:YES completion:nil];
        }];
        [actionSheet addAction:reportUsername];
    }
    
    if ([self isCurrentUser]) {
        UIAlertAction *openSettings = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [Launcher openSettings];
        }];
        [actionSheet addAction:openSettings];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel");
    }];
    [actionSheet addAction:cancel];
    
    [self.navigationController presentViewController:actionSheet animated:YES completion:nil];
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"User Not Found" description:@"We couldn’t find the User\nyou were looking for" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        self.errorView.hidden = true;
        
        self.tableView.loading = true;
        self.tableView.loadingMore = false;
        [self.tableView refresh];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.user.identifier != nil && self.user.attributes.context != nil) {
                [self getPostsWithCursor:PostStreamPagingCursorTypeNone];
            }
            else {
                [self loadUser];
            }
        });
    }];
}

- (void)positionErrorView {
    ProfileHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat heightOfHeader = headerCell.frame.size.height;
    self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 64, self.errorView.frame.size.width, self.errorView.frame.size.height);
}

- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.bounds.size.width, collapsed_inputViewHeight);
}

- (void)loadUser {
    if (self.user.identifier.length > 0 || self.user.attributes.details.identifier.length > 0) {
        self.tableView.parentObject = self.user;
        [self.tableView refresh];
        
        NSLog(@"self.user.identifier:: %@", self.user.identifier);
        
        if (!self.user.identifier || self.user.identifier.length == 0) {
            // no user identifier yet, don't show the ••• icon just yet
            [self hideMoreButton];
        }
        
        // load camp info before loading posts
        self.errorView.hidden = true;
        [self getUserInfo];
    }
    else {
        // camp not found
        self.tableView.hidden = true;
        self.errorView.hidden = false;
        
        [self.errorView updateTitle:@"User Not Found"];
        [self.errorView updateDescription:@"We couldn’t find the User\nyou were looking for"];
        [self.errorView updateType:ErrorViewTypeNotFound];
        
        [self hideMoreButton];
    }
}

- (void)getUserInfo {
    NSString *url = [NSString stringWithFormat:@"users/%@", [self isCurrentUser] ? @"me" : [self userIdentifier]]; // sample data
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
        
        NSLog(@"response data:: user:: %@", responseData);
        
        // this must go before we set self.camp to the new Camp object
        NSString *colorBefore = self.user.attributes.details.color;
        BOOL requiresColorUpdate = (colorBefore == nil || colorBefore.length == 0);
        
        // first page
        self.user = [[User alloc] initWithDictionary:responseData error:nil];
        if (![self isCurrentUser]) [[Session sharedInstance] addToRecents:self.user];
        
        if ([self isCurrentUser]) {
            // if current user -> update Session current user object
            [[Session sharedInstance] updateUser:self.user];
        }
        
        if (![colorBefore isEqualToString:self.user.attributes.details.color]) requiresColorUpdate = true;
        if (requiresColorUpdate) {
            [self updateTheme];
        }
        
        if (!([self isCurrentUser] && [self.navigationController isKindOfClass:[SimpleNavigationController class]])) {
            self.title = self.user.attributes.details.displayName;
            if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
                [((ComplexNavigationController *)self.navigationController).searchView updateSearchText:self.title];
            }
        }
        
        [self updateComposeInputView];
        
        self.tableView.parentObject = self.user;
        
        [self positionErrorView];
        
        [self.tableView refresh];
        
        // Now that the VC's Camp object is complete,
        // Go on to load the camp content
        [self loadUserContent];
        
        [self showMoreButton];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ProfileViewController / getUserInfo() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.errorView.hidden = false;
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode == 404) {
            [self.errorView updateTitle:@"User Not Found"];
            [self.errorView updateDescription:@"We couldn’t find the User\nyou were looking for"];
            [self.errorView updateType:ErrorViewTypeNotFound];
            
            [self hideMoreButton];
        }
        else {
            if ([HAWebService hasInternet]) {
                [self.errorView updateType:ErrorViewTypeGeneral];
                [self.errorView updateTitle:@"Error Loading"];
                [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
            }
            else {
                [self.errorView updateType:ErrorViewTypeNoInternet];
                [self.errorView updateTitle:@"No Internet"];
                [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
            }
        }
        
        self.loading = false;
        self.tableView.loading = false;
        self.tableView.error = true;
        [self.tableView refresh];
        
        [self positionErrorView];
    }];
}

- (void)updateTheme {
    UIColor *theme = [UIColor fromHex:self.user.attributes.details.color];
    
    if (self.navigationController.topViewController == self) {
        if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
            [(ComplexNavigationController *)self.navigationController updateBarColor:theme animated:true];
        }
        else if ([self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController updateBarColor:theme animated:true];
        }
    }
    
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.composeInputView.textView.tintColor = theme;
        self.composeInputView.postButton.backgroundColor = theme;
        self.composeInputView.addMediaButton.tintColor = theme;
    } completion:^(BOOL finished) {
    }];
    
    self.theme = theme;
    self.view.tintColor = self.theme;
}

- (void)loadUserContent {
    if ([self canViewPosts]) {
        [self showComposeInputView];
        
        [self getPostsWithCursor:PostStreamPagingCursorTypeNone];
    }
    else {
        [self hideComposeInputView];
        
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
            // private camp but not a member yet
            [self.errorView updateTitle:@"Private User"];
            [self.errorView updateDescription:[NSString stringWithFormat:@"Only confirmed followers have access to @%@'s posts and complete profile", self.user.attributes.details.identifier]];
            [self.errorView updateType:ErrorViewTypeLocked];
        }
        else {
            [self.errorView updateTitle:@"User Not Found"];
            [self.errorView updateDescription:@"We couldn’t find the User\nyou were looking for"];
            [self.errorView updateType:ErrorViewTypeNotFound];
            
            [self hideMoreButton];
        }
    }
    
    [self positionErrorView];
}

- (void)hideMoreButton {
    [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.launchNavVC.rightActionButton.alpha = 0;
    } completion:^(BOOL finished) {
    }];
}
- (void)showMoreButton {
    [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.launchNavVC.rightActionButton.alpha = 1;
    } completion:^(BOOL finished) {
    }];
}

- (void)getPostsWithCursor:(PostStreamPagingCursorType)cursorType {
    if ([self userIdentifier] != nil) { 
        self.errorView.hidden = true;
        self.tableView.hidden = false;
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        if (cursorType == PostStreamPagingCursorTypeNext) {
            [params setObject:self.tableView.stream.nextCursor forKey:@"cursor"];
            [self.tableView.stream addLoadedCursor:self.tableView.stream.nextCursor];
        }
        else if (self.tableView.stream.prevCursor) {
            [params setObject:self.tableView.stream.prevCursor forKey:@"cursor"];
        }
        if ([params objectForKey:@"cursor"]) {
            [self.tableView.stream addLoadedCursor:params[@"cursor"]];
        }
        NSLog(@"params: %@", params);
        
        NSString *url = [NSString stringWithFormat:@"users/%@/posts", [self userIdentifier]]; // sample data
        
        [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            self.tableView.scrollEnabled = true;
            
            if (self.userDidRefresh) {
                self.userDidRefresh = false;
                self.tableView.stream.posts = @[];
                self.tableView.stream.pages = [[NSMutableArray alloc] init];
            }
            
            PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
            if (page.data.count > 0) {
                if (cursorType == PostStreamPagingCursorTypeNone || cursorType == PostStreamPagingCursorTypePrevious) {
                    [self.tableView.stream prependPage:page];
                }
                else if (cursorType == PostStreamPagingCursorTypeNext) {
                    [self.tableView.stream appendPage:page];
                }
            }
            
            if (self.tableView.stream.posts.count == 0) {
                // Error: No sparks yet!
                self.errorView.hidden = false;
                
                ProfileHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                CGFloat heightOfHeader = headerCell.frame.size.height;
                
                [self.errorView updateType:ErrorViewTypeNoPosts];
                [self.errorView updateTitle:@"No Posts Yet"];
                [self.errorView updateDescription:@""];
                
                self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 70, self.errorView.frame.size.width, self.errorView.frame.size.height);
            }
            else {
                self.errorView.hidden = true;
            }
            
            self.loading = false;
            
            self.tableView.loading = false;
            self.tableView.loadingMore = false;
            
            [self.tableView refresh];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"ProfileViewController / getPostsWithMaxId() - error: %@", error);
            //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            
            if (self.tableView.stream.posts.count == 0) {
                self.errorView.hidden = false;
                
                if ([HAWebService hasInternet]) {
                    [self.errorView updateType:ErrorViewTypeGeneral];
                    [self.errorView updateTitle:@"Error Loading"];
                    [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
                }
                else {
                    [self.errorView updateType:ErrorViewTypeNoInternet];
                    [self.errorView updateTitle:@"No Internet"];
                    [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
                }
                
                [self positionErrorView];
            }
            
            self.loading = false;
            self.tableView.loading = false;
            self.tableView.loadingMore = false;
            self.tableView.userInteractionEnabled = true;
            self.tableView.scrollEnabled = false;
            [self.tableView refresh];
        }];
    }
    else {
        self.loading = false;
        self.tableView.loading = false;
        self.tableView.loadingMore = false;
        self.tableView.userInteractionEnabled = true;
        self.tableView.scrollEnabled = false;
        [self.tableView refresh];
    }
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    NSLog(@"has loaded cursor:::: %@", [self.tableView.stream hasLoadedCursor:self. tableView.stream.nextCursor] ? @"true" : @"false");
    if (self.tableView.stream.nextCursor.length > 0 && ![self.tableView.stream hasLoadedCursor:self. tableView.stream.nextCursor]) {
        NSLog(@"load page using next cursor: %@", self.tableView.stream.nextCursor);
        [self getPostsWithCursor:PostStreamPagingCursorTypeNext];
    }
}

- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataType = RSTableViewTypeProfile;
    self.tableView.tableViewStyle = RSTableViewStyleGrouped;
    self.tableView.parentObject = self.user;
    self.tableView.loading = true;
    self.tableView.paginationDelegate = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.tag = 101;
    [self.tableView.refreshControl addTarget:self
                                action:@selector(refresh)
                      forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.tableView];
    
    UIView *headerHack = [[UIView alloc] initWithFrame:CGRectMake(0, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    headerHack.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    //[self.tableView insertSubview:headerHack atIndex:0];
}
- (void)refresh {
    NSLog(@"refresh profile view controller");
    self.userDidRefresh = true;
    [self loadUser];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
