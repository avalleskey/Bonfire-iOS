//
//  LinkConversationsViewController.h
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "ComposeInputView.h"
#import "Session.h"
#import "Post.h"
#import "ComposeInputView.h"
#import "ThemedViewController.h"
#import "PostStream.h"
#import "TappableView.h"
#import "BFComponentTableView.h"

@interface LinkConversationsViewController : ThemedViewController <ComposeInputViewDelegate, BFComponentTableViewDelegate>

@property (nonatomic, strong) BFLink *link;

@property (nonatomic, strong) BFComponentTableView *tableView;
@property (nonatomic, strong) UIImageView *imagePreviewView;

@property (nonatomic, strong) ComposeInputView *composeInputView;
@property (nonatomic, strong) TappableView *parentPostScrollIndicator;

@property (nonatomic) CGFloat currentKeyboardHeight;
@property (nonatomic) CGRect currentKeyboardFrame;

@property (nonatomic) BOOL showKeyboardOnOpen;
@property (nonatomic) BOOL isPreview;

@end
