//
//  ProfileViewController.h
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "Session.h"
#import "RSTableView.h"
#import "User.h"
#import "Bot.h"
#import "ThemedViewController.h"
#import "ComposeInputView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ProfileViewController : ThemedViewController <ComposeInputViewDelegate, RSTableViewDelegate>

@property (nonatomic, strong) User * _Nullable user;
@property (nonatomic, strong) Bot * _Nullable bot;

@property (nonatomic, strong) RSTableView * _Nullable tableView;
@property (nonatomic, strong) UIImageView *coverPhotoView;
@property (nonatomic, strong) CAGradientLayer *coverPhotoViewOverlay;

@property (nonatomic) CGFloat currentKeyboardHeight;
@property (nonatomic) BOOL isPreview;

- (void)openProfileActions;

@end

NS_ASSUME_NONNULL_END
