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

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface PostViewController () {
    int previousTableViewYOffset;
    ErrorView *errorView;
}

@property (nonatomic) BOOL loading;

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
    
    self.view.tintColor = self.theme;
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.hidesBackButton = true;
    
    [self setupTableView];
    [self setupErrorView];
    if (self.post.identifier) {
        [self setupComposeInputView];
    }
    
    self.manager = [HAWebService manager];
    self.loading = true;
    [self getReplies];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self styleOnAppear];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)setupErrorView {
    errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Post Not Found" description:@"We couldn’t find the post you were looking for. Please try again." type:ErrorViewTypeNotFound];
    errorView.center = self.tableView.center;
    [self.view addSubview:errorView];
}


- (void)setupComposeInputView {
    self.composeInputView = [[ComposeInputView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.composeInputView.frame = CGRectMake(0, self.view.frame.size.height - 52, self.view.frame.size.width, 190);
    self.composeInputView.parentViewController = self;
    self.composeInputView.postButton.tintColor = [self.theme isEqual:[UIColor whiteColor]] ? [UIColor colorWithWhite:0.2f alpha:1] : self.theme;
    [self.composeInputView bk_whenTapped:^{
        if (![self.composeInputView isActive]) {
            [self.composeInputView setActive:true];
        }
    }];
    [self.composeInputView.postButton bk_whenTapped:^{
        [self postMessage];
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
- (void)postMessage {
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/posts/%ld/replies", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.post.attributes.status.postedIn.identifier, (long)self.post.identifier];
    
    NSLog(@"url: %@", url);
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (self.composeInputView.textView.text.length > 0) {
        [params setObject:self.composeInputView.textView.text forKey:@"message"];
        self.composeInputView.textView.text = @"";
    }
    
    if ([params objectForKey:@"message"]) {
        [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
            if (success) {
                NSLog(@"token::: %@", token);
                [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                [self.manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    // NSLog(@"PostViewController / postMessage() success! ✅");
                    
                    // NSArray *responseData = (NSArray *)responseObject[@"data"];
                    // NSLog(@"responsedata: %@", responseData);
                    
                    [self getReplies];
                    
                    /*
                     
                     self.tableView.data = [[NSMutableArray alloc] initWithArray:responseData];
                     
                     self.loading = false;
                     
                     self.tableView.loading = false;
                     [self.tableView reloadData];
                     
                     */
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"FeedViewController / getPosts() - error: %@", error);
                    //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    
                    self.loading = false;
                    self.tableView.userInteractionEnabled = true;
                    [self.tableView refresh];
                }];
            }
        }];
    }
}

- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(0, self.view.frame.size.height - collapsed_inputViewHeight, self.view.frame.size.width, collapsed_inputViewHeight);
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height, 0);
    
    errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.center.y - bottomPadding);
}

- (void)getReplies {
    if (self.post.identifier) {
        errorView.hidden = true;
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
        NSLog(@"url: %@", url);
        [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
            if (success) {
                [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                
                [self.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    // NSLog(@"CommonTableViewController / getReplies() success! ✅");
                    PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
                    [self.tableView.stream appendPage:page];
                    
                    self.loading = false;
                    
                    self.tableView.loading = false;
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
    else {
        errorView.hidden = false;
        self.tableView.hidden = true;
    }
}
- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataType = RSTableViewTypePost;
    self.tableView.parentObject = self.post;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tableView];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.tableView.alpha = 0.2;
    } completion:nil];
    
    return true;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.tableView.alpha = 1;
    } completion:nil];
    
    return true;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    NSLog(@"keyboard will change frame");
    
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
    
    // Following state
    // *) Any Following State
    // +) Following Room
    // &) Following User
    // BOOL followingRoom = true;
    BOOL followingUser = true;
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    actionSheet.view.tintColor = [UIColor colorWithWhite:0.2 alpha:1];
    
    // 1.A.* -- Any user, any page, any following state
    BOOL hasiMessage = [MFMessageComposeViewController canSendText];
    if (hasiMessage) {        
        UIAlertAction *shareOniMessage = [UIAlertAction actionWithTitle:@"Share on iMessage" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"share on iMessage");
            // confirm action
            MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init]; // Create message VC
            messageController.messageComposeDelegate = self; // Set delegate to current instance
            messageController.transitioningDelegate = [Launcher sharedInstance];
            
            messageController.body = @"Join my room! https://rooms.app/room/room-name"; // Set initial text to example message
            
            //NSData *dataImg = UIImagePNGRepresentation([UIImage imageNamed:@"logoApple"]);//Add the image as attachment
            //[messageController addAttachmentData:dataImg typeIdentifier:@"public.data" filename:@"Image.png"];
            
            [self.navigationController presentViewController:messageController animated:YES completion:NULL];
        }];
        [actionSheet addAction:shareOniMessage];
    }
    
    // 1.A.* -- Any user, any page, any following state
    UIAlertAction *sharePost = [UIAlertAction actionWithTitle:@"Share via..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share post");
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
        UIAlertAction *openRoom = [UIAlertAction actionWithTitle:@"Open Room" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"open room");
            
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
    
    // !2.A.* -- Not Creator, any page, any following state
    if (!isCreator) {
        UIAlertAction *followUser = [UIAlertAction actionWithTitle:(followingUser?@"Follow @username":@"Unfollow @username") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"follow user");
            if (followingUser) {
                [[Session sharedInstance] unfollowUser:self.post.attributes.details.creator completion:^(BOOL success, id responseObject) {
                    NSLog(@"unfollowed user!");
                }];
            }
            else {
                [[Session sharedInstance] followUser:self.post.attributes.details.creator completion:^(BOOL success, id responseObject) {
                    NSLog(@"followed user!");
                }];
            }
        }];
        [actionSheet addAction:followUser];
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
