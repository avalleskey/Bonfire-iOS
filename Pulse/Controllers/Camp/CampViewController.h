//
//  CampViewController.h
//  
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "ComposeInputView.h"
#import "Session.h"
#import "BFComponentTableView.h"
#import "BFComponentSectionTableView.h"
#import "Camp.h"
#import "ComposeInputView.h"
#import "ThemedViewController.h"

#if !TARGET_OS_MACCATALYST
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#endif

@interface CampViewController : ThemedViewController <UITextViewDelegate, BFComponentSectionTableViewDelegate>

@property (nonatomic, strong) Camp *camp;

@property (nonatomic, strong) BFComponentSectionTableView *tableView;
@property (nonatomic, strong) UIImageView *coverPhotoView;

@property (nonatomic, strong) ComposeInputView *composeInputView;

@property (nonatomic) CGFloat currentKeyboardHeight;
@property (nonatomic) BOOL isPreview;

- (void)openCampActions;

@end
