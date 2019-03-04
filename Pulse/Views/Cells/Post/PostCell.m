//
//  PostCell.m
//  Pulse
//
//  Created by Austin Valleskey on 3/10/18.
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "PostCell.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SafariServices/SafariServices.h>
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "ComplexNavigationController.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>
#import <JGProgressHUD/JGProgressHUD.h>

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

@implementation PostCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectable = true;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.masksToBounds = true;
        self.tintColor = self.superview.tintColor;
        
        self.post = [[Post alloc] init];
        
        self.contextView = [[PostContextView alloc] init];
        [self.contentView addSubview:self.contextView];
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, 12, 48, 48)];
        self.profilePicture.openOnTap = false;
        self.profilePicture.dimsViewOnTap = true;
        self.profilePicture.allowOnlineDot = true;
        [self.profilePicture bk_whenTapped:^{
            [[Launcher sharedInstance] openProfile:self.post.attributes.details.creator];
        }];
        [self.contentView addSubview:self.profilePicture];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, self.contentView.frame.size.width - 12 - 12, 15)];
        self.nameLabel.text = @"Display Name";
        self.nameLabel.numberOfLines = 1;
        self.nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        // self.nameLabel.userInteractionEnabled = YES;
        [self.contentView addSubview:self.nameLabel];
        
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.nameLabel.frame.origin.y, 21, self.nameLabel.frame.size.height)];
        self.dateLabel.font = [UIFont systemFontOfSize:self.nameLabel.font.pointSize weight:UIFontWeightRegular];
        self.dateLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.dateLabel];
        
        // text view
        self.textView = [[PostTextView alloc] initWithFrame:CGRectMake(12, 58, self.contentView.frame.size.width - (12 + 12), 200)]; // 58 will change based on whether or not the detail label is shown
        self.textView.messageLabel.font = textViewFont;
        self.textView.delegate = self;
        [self.contentView addSubview:self.textView];
        
        [self initImagesView];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor separatorColor];
        [self addSubview:self.lineSeparator];
    }
    
    return self;
}

- (void)initImagesView {
    // image view
    self.imagesView = [[PostImagesView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, [PostImagesView streamImageHeight])];
    [self.contentView addSubview:self.imagesView];
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
    // BOOL insideRoom    = true; // compare ID of post room and active room
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *copyPost = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = @"http://testflight.com/bonfire-ios";
        
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.textLabel.text = @"Copied!";
        HUD.vibrancyEnabled = false;
        HUD.animation = [[JGProgressHUDFadeZoomAnimation alloc] init];
        HUD.tintColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.textLabel.textColor = HUD.tintColor;
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
        
        [HUD showInView:[Launcher sharedInstance].activeViewController.view animated:YES];
        [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        
        [HUD dismissAfterDelay:1.5f];
    }];
    [actionSheet addAction:copyPost];
    
    // !2.A.* -- Not Creator, any page, any following state
    if (!isCreator) {
        UIAlertAction *reportPost = [UIAlertAction actionWithTitle:@"Report Post" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // confirm action
            UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Report Post" message:@"Are you sure you want to report this post?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *confirmDeletePost = [UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [[Session sharedInstance] reportPost:self.post.identifier completion:^(BOOL success, id responseObject) {
                    // NSLog(@"reported post!");
                }];
            }];
            [confirmDeletePostActionSheet addAction:confirmDeletePost];
            
            UIAlertAction *cancelDeletePost = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [confirmDeletePostActionSheet addAction:cancelDeletePost];
            
            [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
        }];
        [actionSheet addAction:reportPost];
    }
    
    // 2|3.A.* -- Creator or room admin, any page, any following state
    if (isCreator || isRoomAdmin) {
        UIAlertAction *deletePost = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [actionSheet dismissViewControllerAnimated:YES completion:nil];
            // confirm action
            UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Delete Post" message:@"Are you sure you want to delete this post?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *confirmDeletePost = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"delete post");
                // confirm action
                [[Session sharedInstance] deletePost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        
                    }
                }];
            }];
            [confirmDeletePostActionSheet addAction:confirmDeletePost];
            
            UIAlertAction *cancelDeletePost = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [confirmDeletePostActionSheet addAction:cancelDeletePost];
            
            [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
        }];
        [actionSheet addAction:deletePost];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [actionSheet addAction:cancel];
    
    [[Launcher.sharedInstance activeViewController] presentViewController:actionSheet animated:YES completion:nil];
}

+ (NSAttributedString *)attributedCreatorStringForPost:(Post *)post includeTimestamp:(BOOL)includeTimestamp includePostedIn:(BOOL)includePostedIn {
    // set display name + room name combo
    NSString *username = post.attributes.details.creator.attributes.details.identifier != nil ? [NSString stringWithFormat:@"@%@", post.attributes.details.creator.attributes.details.identifier] : @"anonymous";
    
    UIFont *font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
    
    NSMutableAttributedString *creatorString = [[NSMutableAttributedString alloc] initWithString:username];
    PatternTapResponder creatorTapResponder = ^(NSString *string) {
        [[Launcher sharedInstance] openProfile:post.attributes.details.creator];
    };
    [creatorString addAttribute:RLTapResponderAttributeName value:creatorTapResponder range:NSMakeRange(0, creatorString.length)];
    // [creatorString addAttribute:NSForegroundColorAttributeName value:[UIColor fromHex:post.attributes.details.creator.attributes.details.color] range:NSMakeRange(0, creatorString.length)];
    [creatorString addAttribute:NSForegroundColorAttributeName value:[UIColor fromHex:post.attributes.details.creator.attributes.details.color] range:NSMakeRange(0, creatorString.length)];
    
    UIFont *heavyItalicFont = [UIFont fontWithDescriptor:[[[UIFont systemFontOfSize:font.pointSize weight:UIFontWeightHeavy] fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:font.pointSize];
    [creatorString addAttribute:NSFontAttributeName value:heavyItalicFont range:NSMakeRange(0, creatorString.length)];
    [creatorString addAttribute:RLHighlightedForegroundColorAttributeName value:[UIColor colorWithWhite:0.2f alpha:0.5f] range:NSMakeRange(0, creatorString.length)];
    
    if (includeTimestamp) {
        NSMutableAttributedString *connector = [[NSMutableAttributedString alloc] initWithString:@"  "];
        [connector addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, connector.length)];
        [creatorString appendAttributedString:connector];
        
        NSString *timeAgo = [NSDate mysqlDatetimeFormattedAsTimeAgo:post.attributes.status.createdAt withForm:TimeAgoShortForm];
        if (timeAgo != nil) {
            NSMutableAttributedString *timeAgoString = [[NSMutableAttributedString alloc] initWithString:timeAgo];
            [timeAgoString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.6 alpha:1] range:NSMakeRange(0, timeAgoString.length)];
            [timeAgoString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, timeAgoString.length)];
            
            [creatorString appendAttributedString:timeAgoString];
        }
    }
    if (includePostedIn && post.attributes.status.postedIn != 0) {
        NSMutableAttributedString *connector = [[NSMutableAttributedString alloc] initWithString:@" in "];
        [connector addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.6 alpha:1] range:NSMakeRange(0, connector.length)];
        [connector addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, connector.length)];
        [creatorString appendAttributedString:connector];
        
        NSString *roomTitle = [NSString stringWithFormat:@"%@", post.attributes.status.postedIn.attributes.details.title];
        NSMutableAttributedString *roomTitleString = [[NSMutableAttributedString alloc] initWithString:roomTitle];
        [roomTitleString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.6 alpha:1] range:NSMakeRange(0, roomTitleString.length)];
        [roomTitleString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, roomTitleString.length)];
        
        [creatorString appendAttributedString:roomTitleString];
    }
    
    /*
    BOOL isVerified = false;
    if (isVerified) {
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
        [spacer addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, spacer.length)];
        [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
        [creatorString appendAttributedString:spacer];
        
        // verified icon ☑️
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"verifiedIcon_small"];
        [attachment setBounds:CGRectMake(0, roundf(font.capHeight - attachment.image.size.height)/2.f, attachment.image.size.width, attachment.image.size.height)];
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [creatorString appendAttributedString:attachmentString];
    }*/
    
    return creatorString;
}

@end
