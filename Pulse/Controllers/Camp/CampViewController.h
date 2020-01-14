//
//  CampViewController.h
//  
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "ComposeInputView.h"
#import "Session.h"
#import "RSTableView.h"
#import "Camp.h"
#import "ComposeInputView.h"
#import "ThemedViewController.h"

#if !TARGET_OS_MACCATALYST
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#endif

@interface CampViewController : ThemedViewController <UITextViewDelegate, RSTableViewDelegate>

@property (nonatomic, strong) Camp *camp;

@property (nonatomic, strong) UILabel *navTitle;

@property (nonatomic, strong) RSTableView *tableView;
@property (nonatomic, strong) UIImageView *coverPhotoView;

@property (nonatomic, strong) ComposeInputView *composeInputView;

@property (nonatomic) CGFloat currentKeyboardHeight;
@property (nonatomic) BOOL isPreview;

@property (nonatomic) BOOL shimmering;

- (void)openCampActions;

@end
