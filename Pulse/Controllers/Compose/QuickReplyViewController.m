//
//  QuickReplyViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 2/24/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "QuickReplyViewController.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Launcher.h"

@interface QuickReplyViewController ()

@end

@implementation QuickReplyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.96 alpha:0.3];
    
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    visualEffectView.frame = self.view.bounds;
    visualEffectView.tag = 2;
    [visualEffectView bk_whenTapped:^{
        [self dismiss];
    }];
    [self.view addSubview:visualEffectView];
    
    UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
    
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 44 - 11, safeAreaInsets.top + 2, 44, 44);
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.tintColor = [UIColor blackColor];
    self.closeButton.adjustsImageWhenHighlighted = false;
    self.closeButton.contentMode = UIViewContentModeCenter;
    [self.closeButton bk_whenTapped:^{
        [self dismiss];
    }];
    [self.view addSubview:self.closeButton];
    
    [self setupComposeInputView];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [self animateIn];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.composeInputView.textView becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)animateIn {
    UIVisualEffectView *visualEffectView = [self.view viewWithTag:2];
    visualEffectView.alpha = 0;
    
    self.closeButton.transform = CGAffineTransformMakeScale(0.6, 0.6);
    self.closeButton.alpha = 0;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(12, self.view.frame.size.height, self.view.frame.size.width - 24, 100)];
    self.tableView.center = self.fromCenter;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.layer.cornerRadius = 12.f;
    self.tableView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.tableView.layer.shadowOffset = CGSizeMake(0, 1);
    self.tableView.layer.shadowOpacity = 0.1;
    self.tableView.layer.shadowRadius = 3.f;
    [self.view addSubview:self.tableView];
    
    [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        visualEffectView.alpha = 1;
        
        self.closeButton.transform = CGAffineTransformMakeScale(1, 1);
        self.closeButton.alpha = 1;
        
        // CGFloat scale = (self.view.frame.size.width - 24) / self.view.frame.size.width;
        self.tableView.center = CGPointMake(self.tableView.center.x, self.view.frame.size.height - self.currentKeyboardHeight - (self.tableView.frame.size.height / 2) - 16);
    } completion:nil];
}


- (void)setupComposeInputView {
    CGFloat bottomPadding = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView = [[ComposeInputView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.frame.size.width, collapsed_inputViewHeight)];
    self.composeInputView.hidden = true;
    
    self.composeInputView.parentViewController = self;
    self.composeInputView.postButton.backgroundColor = self.view.tintColor;//[self.theme isEqual:[UIColor whiteColor]] ? [UIColor colorWithWhite:0.2f alpha:1] : self.theme;
//    self.composeInputView.addMediaButton.backgroundColor = self.composeInputView.postButton.backgroundColor;
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
        //[[Launcher sharedInstance] openComposePost:self.camp inReplyTo:nil withMessage:self.composeInputView.textView.text media:self.composeInputView.media];
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.textView.delegate = self;
    self.composeInputView.tintColor = self.view.tintColor;
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
    if (self.composeInputView.media.objects.count > 0) {
        [params setObject:self.composeInputView.media forKey:@"media"];
    }
    
    if ([params objectForKey:@"message"] || [params objectForKey:@"images"]) {
        // meets min. requirements
        // [[Session sharedInstance] createPost:params postingIn:self.camp replyingTo:nil];
        
        self.composeInputView.textView.text = @"";
        [self.composeInputView hidePostButton];
        [self.composeInputView.textView resignFirstResponder];
        [self.composeInputView.media flush];
        [self.composeInputView hideMediaTray];
        [self.composeInputView setReplyingTo:nil];
    }
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

- (void)dismiss {
    [self.view endEditing:TRUE];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
