//
//  WaitlistViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 8/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "WaitlistViewController.h"
#import "UIColor+Palette.h"
#import "Configuration.h"
#import "Launcher.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <JGProgressHUD/JGProgressHUD.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <PINCache/PINCache.h>
#import "BFAlertController.h"

@interface WaitlistViewController ()

@property (nonatomic) NSInteger rank;
@property (nonatomic) BOOL upToDate;
@property (nonatomic, strong) NSDate *lastFetch;

@end

@implementation WaitlistViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    
    [self setup];
    wait(0.25f, ^{
        [self getRank:true];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredForeground) name:@"applicationWillEnterForeground" object:nil];
}

- (void)loadCache {
    NSString *cacheKey = @"waitlist_invite_status";
    // load cache
    NSDictionary *cache = [[PINCache sharedCache] objectForKey:cacheKey];
    if (cache) {
        self.inviteStatus = [[InviteStatusModel alloc] initWithDictionary:cache error:nil];
        
        [self setSpinning:false animated:true];
    }
}

- (void)enteredForeground {
    if (![self.bigSpinner isHidden] && !self.bigSpinner.animating) {
        [self addAnimationToBigSpinner];
    }
    
    [self getRank:false];
}

- (void)getRank:(BOOL)force {
    NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
    // NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
    if (!force && secondsSinceLastFetch < -(60)) {
        // already refreshed within the last minute -- no need
        return;
    }
    else {
        self.lastFetch = [NSDate date];
    }
    
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:true completion:nil];
    }
    [[HAWebService authenticatedManager] GET:@"users/me/invites/status" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject objectForKey:@"data"]) {
            self.upToDate = true;
            
            self.inviteStatus = [[InviteStatusModel alloc] initWithDictionary:responseObject[@"data"] error:nil];
            [[PINCache sharedCache] setObject:responseObject[@"data"] forKey:@"waitlist_invite_status"];
            
            if (self.centerView.alpha == 0) {
                [self setSpinning:false animated:true];
            }
            
            NSInteger invitesNeeded = MAX(self.inviteStatus.totalInvitesRequired - self.inviteStatus.invitees.count, 0);
            if (invitesNeeded == 0) {
                // get the user
                [self updateUser];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self loadCache];
        
        if (!self.inviteStatus) {
            [UIView animateWithDuration:0.2f animations:^{
                self.bigSpinner.alpha = 0;
            }];
            
            BFAlertController *alert = [BFAlertController
                                       alertControllerWithTitle:([HAWebService hasInternet] ? @"Error Updating" : @"No Internet")
                                       message:@"Check your network settings and tap below to try again"
                                       preferredStyle:BFAlertControllerStyleAlert];
            
            BFAlertAction *tryAgain = [BFAlertAction actionWithTitle:@"Try Again" style:BFAlertActionStyleDefault
                                                             handler:^{
                [self setSpinning:true animated:false];
                [self getRank:true];
                
                self.bigSpinner.alpha = 0;
                [UIView animateWithDuration:0.2f animations:^{
                    self.bigSpinner.alpha = 1;
                }];
            }];
            
            [alert addAction:tryAgain];
            alert.preferredAction = tryAgain;
            
            [[Launcher topMostViewController] presentViewController:alert animated:true completion:nil];
        }
    }];
}

- (void)useFriendCode:(NSString *)friendCode {
    [[HAWebService authenticatedManager] POST:@"users/me/invites/redeem" parameters:@{@"friend_code": friendCode} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject objectForKey:@"data"] && [[responseObject objectForKey:@"data"] objectForKey:@"invite_used"]) {
            BOOL inviteUsed = [responseObject[@"data"][@"invite_used"] boolValue];
            if (inviteUsed) {
                [self updateUser];
            }
            else {
                [self setSpinning:false animated:true];
                wait(0.45f, ^{
                    [self shakeFriendButton];
                });
                
                BFAlertController *alert = [BFAlertController
                                           alertControllerWithTitle:@"Uh oh!"
                                           message:@"Your friend is out of invites. Try using another Friend Code or invite some friends to skip the line!"
                                           preferredStyle:BFAlertControllerStyleAlert];

                BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel
                                                               handler:nil];
                
                [alert addAction:cancel];
                
                [[Launcher topMostViewController] presentViewController:alert animated:true completion:nil];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (self.inviteStatus) {
            [self setSpinning:false animated:true];
        }
        
        wait(0.45f, ^{
            [self shakeFriendButton];
        });
    }];
}
- (void)updateUser {
    [BFAPI getUser:^(BOOL success) {
        if (success) {
            if (![Session sharedInstance].currentUser.attributes.requiresInvite) {
                [self welcomeUser];
            }
            else {
                [self setSpinning:false animated:true];
            }
        }
    }];
}

- (void)setup {
    [self initCenterView];
    [self initBigSpinner];
    
    self.instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, self.view.frame.size.height, self.view.frame.size.width - 48, 42)];
    self.instructionLabel.textAlignment = NSTextAlignmentCenter;
    self.instructionLabel.text = [NSString stringWithFormat:@"You're in line @%@!\nCheck your status below", [Session sharedInstance].currentUser.attributes.identifier];
    self.instructionLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
    self.instructionLabel.textColor = [UIColor bonfirePrimaryColor];
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGFloat instructionHeight = ceilf([self.instructionLabel.text boundingRectWithSize:CGSizeMake(self.instructionLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: self.instructionLabel.font} context:nil].size.height);
    SetHeight(self.instructionLabel, instructionHeight);
    self.instructionLabel.center = CGPointMake(self.instructionLabel.center.x, (self.view.frame.size.height / 4) - 52);
    [self.view addSubview:self.instructionLabel];
    
    self.redeemButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.redeemButton.frame = CGRectMake(24, self.view.frame.size.height - 48 - [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom - (HAS_ROUNDED_CORNERS ? 12 : 24), self.view.frame.size.width - (24 * 2), 48);
    self.redeemButton.backgroundColor = [UIColor bonfireBrand];
    [self.redeemButton setBackgroundImage:[self gradientImageForView:self.redeemButton topLeftColor:[UIColor colorWithDisplayP3Red:1 green:0.35 blue:0.93 alpha:1] bottomRightColor:[UIColor colorWithDisplayP3Red:0.90 green:0 blue:0 alpha:1]] forState:UIControlStateNormal];
    self.redeemButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    [self.redeemButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    self.redeemButton.adjustsImageWhenHighlighted = false;
    [self continuityRadiusForView:self.redeemButton withRadius:14.f];
    [self.redeemButton setTitle:@"Enter Friend Code" forState:UIControlStateNormal];
    [self.redeemButton bk_whenTapped:^{
        BFAlertController *alert = [BFAlertController
                                   alertControllerWithTitle:@"Skip the Line"
                                   message:@"Ask a friend with invites\nfor their Friend Code!"
                                   preferredStyle:BFAlertControllerStyleAlert];
        
        BFAlertAction *ok = [BFAlertAction actionWithTitle:@"Use Friend Code" style:BFAlertActionStyleDefault
                                                   handler:^(){
            //Do Some action here
            UITextField *textField = alert.textField;
            
            if (textField.text.length == 0) {
                [self shakeFriendButton];
            }
            else {
                [self setSpinning:true animated:true];
                
                [self useFriendCode:textField.text];
            }
        }];

        BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel
                                                       handler:nil];
        
        [alert addAction:ok];
        [alert addAction:cancel];
        
        alert.preferredAction = ok;
        
        UITextField *textField = [UITextField new];
        textField.placeholder = @"Friend Code";
        textField.keyboardType = UIKeyboardTypeDefault;
        [alert setTextField:textField];
        [textField becomeFirstResponder];
        
        [[Launcher topMostViewController] presentViewController:alert animated:true completion:nil];
    }];
    [self.redeemButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.redeemButton.alpha = 0.8;
            self.redeemButton.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.redeemButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.redeemButton.alpha = 1;
            self.redeemButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [self.view addSubview:self.redeemButton];
    
    self.redeemButtonHelperLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, self.redeemButton.frame.origin.y - 19 - 16, self.view.frame.size.width - 48, 19)];
    self.redeemButtonHelperLabel.textAlignment = NSTextAlignmentCenter;
    self.redeemButtonHelperLabel.textColor = [UIColor bonfireSecondaryColor];
    self.redeemButtonHelperLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular];
    self.redeemButtonHelperLabel.text = @"Invited by a friend?";
    [self.view addSubview:self.redeemButtonHelperLabel];
    
    [self setSpinning:true animated:false];
}

- (void)initBigSpinner {
    self.bigSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 52, 52)];
    self.bigSpinner.image = [[UIImage imageNamed:@"spinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.bigSpinner.tintColor = [UIColor bonfireBrand];
    self.bigSpinner.center = self.view.center;
    self.bigSpinner.alpha = 0;
    self.bigSpinner.tag = 1111;
    
    [self.view addSubview:self.bigSpinner];
}
- (void)setSpinning:(BOOL)spinning animated:(BOOL)animated {
    if (spinning) {
        [self addAnimationToBigSpinner];
        
        self.centerView.userInteractionEnabled = false;
        [UIView animateWithDuration:animated?0.4f:0 delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.centerView.alpha = 0;
            self.centerView.transform = CGAffineTransformMakeScale(0.5, 0.5);
            
            self.bigSpinner.alpha = 1;
            self.bigSpinner.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {

        }];
    }
    else {
        [UIView animateWithDuration:animated?0.4f:0 delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.bigSpinner.alpha = 0;
            self.bigSpinner.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            [self.bigSpinner.layer removeAnimationForKey:@"rotationAnimation"];
        }];
        [UIView animateWithDuration:animated?0.56f:0 delay:0.1f usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.centerView.alpha = 1;
            self.centerView.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {
            self.centerView.userInteractionEnabled = true;
        }];
    }
}
- (void)addAnimationToBigSpinner {
    [self.bigSpinner.layer removeAnimationForKey:@"rotationAnimation"];
    
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1 * 1.f ];
    rotationAnimation.duration = 0.8f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    [self.bigSpinner.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)initCenterView {
    self.centerView = [[UIView alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - (24 * 2), 116)];
    [self.view addSubview:self.centerView];
    
    // create the invites label
    self.rankLabel = [self newRankLabel];
    
    self.peopleInFrontLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.rankLabel.frame.origin.y + self.rankLabel.frame.size.height + 12, self.centerView.frame.size.width, 21)];
    self.peopleInFrontLabel.text = @"people in front of you";
    self.peopleInFrontLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightRegular];
    self.peopleInFrontLabel.textAlignment = NSTextAlignmentCenter;
    self.peopleInFrontLabel.textColor = [UIColor bonfireSecondaryColor];
    [self.centerView addSubview:self.peopleInFrontLabel];
    
    [self initInvitedProgressView];
    
    self.invitesNeededLabel = [[MarqueeLabel alloc] initWithFrame:CGRectMake(0, self.invitedProgressView.frame.origin.y + self.invitedProgressView.frame.size.height + 12, self.centerView.frame.size.width, 21) duration:13.f andFadeLength:16.f];
    self.invitesNeededLabel.textAlignment = NSTextAlignmentCenter;
    self.invitesNeededLabel.numberOfLines = 0;
    self.invitesNeededLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.invitesNeededLabel.animationDelay = 0;
    [self.centerView addSubview:self.invitesNeededLabel];
    
    NSMutableArray *buttons = [NSMutableArray new];
    
    BOOL hasInstagram = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram-stories://"]];
    BOOL hasSnapchat = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"snapchat://"]];
    BOOL hasTwitter = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]];
    
    if (hasTwitter) {
        [buttons addObject:@{@"id": @"twitter", @"image": [UIImage imageNamed:@"share_twitter"], @"color": [UIColor fromHex:@"1DA1F2" adjustForOptimalContrast:false]}];
    }
    
    [buttons addObject:@{@"id": @"facebook", @"image": [UIImage imageNamed:@"share_facebook"], @"color": [UIColor fromHex:@"3B5998" adjustForOptimalContrast:false]}];
      
    if (hasInstagram) {
        [buttons addObject:@{@"id": @"instagram", @"image": [UIImage imageNamed:@"share_instagram"], @"color": [UIColor fromHex:@"DC3075" adjustForOptimalContrast:false]}];
    }
    
    if (hasSnapchat) {
        [buttons addObject:@{@"id": @"snapchat", @"image": [UIImage imageNamed:@"share_snapchat"], @"color": [UIColor fromHex:@"fffc00" adjustForOptimalContrast:false]}];
    }
    
    if (buttons.count < 4) {
        [buttons addObject:@{@"id": @"imessage", @"image": [UIImage imageNamed:@"share_imessage"], @"color": [UIColor fromHex:@"36DB52" adjustForOptimalContrast:false]}];
    }
    
    [buttons addObject:@{@"id": @"more", @"image": [[UIImage imageNamed:@"share_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate], @"color": [UIColor tableViewSeparatorColor]}];
    
    CGFloat buttonPadding = 12;
    CGFloat buttonDiameter = MIN(56, ceilf((self.centerView.frame.size.width - ((buttons.count - 1) * buttonPadding)) / buttons.count));
    
    NSString *message;
    if ([Session sharedInstance].currentUser.attributes.invites.friendCode) {
        message = [NSString stringWithFormat:@"Join me on Bonfire with my friend code: %@ https://bonfire.camp/download", [Session sharedInstance].currentUser.attributes.invites.friendCode];
    }
    else {
        message = [NSString stringWithFormat:@"Join me on Bonfire 🔥 https://bonfire.camp/download"];
    }
    
    self.shareActionsView = [UIView new];
    self.shareActionsView.frame = CGRectMake(0, self.invitesNeededLabel.frame.origin.y + self.invitesNeededLabel.frame.size.height + 16, self.centerView.frame.size.width, buttonDiameter);
    [self.centerView addSubview:self.shareActionsView];
    for (NSInteger i = 0; i < buttons.count; i++) {
        NSDictionary *buttonDict = buttons[i];
        NSString *identifier = buttonDict[@"id"];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(i * (buttonDiameter + buttonPadding), 0, buttonDiameter, buttonDiameter);
        button.layer.cornerRadius = button.frame.size.width / 2;
        button.backgroundColor = buttonDict[@"color"];
        button.adjustsImageWhenHighlighted = false;
        button.layer.masksToBounds = true;
        button.tintColor = [UIColor bonfireSecondaryColor];
        [button setImage:buttonDict[@"image"] forState:UIControlStateNormal];
        button.contentMode = UIViewContentModeCenter;
        [self.shareActionsView addSubview:button];
        
        [button bk_addEventHandler:^(id sender) {
            [HapticHelper generateFeedback:FeedbackType_Selection];
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                button.transform = CGAffineTransformMakeScale(0.92, 0.92);
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
                
        [button bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                button.transform = CGAffineTransformIdentity;
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        
        [button bk_whenTapped:^{
            if ([identifier isEqualToString:@"twitter"]) {
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://post"]]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://post?message=%@", [message stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]]] options:@{} completionHandler:nil];
                }
                else {
                    DLog(@"can't open twitter posts");
                }
            }
            else if ([identifier isEqualToString:@"instagram"]) {
                [Launcher shareOnInstagram];
            }
            else if ([identifier isEqualToString:@"facebook"]) {
                FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
                content.contentURL = [NSURL URLWithString:@"https://bonfire.camp/download"];
                content.hashtag = [FBSDKHashtag hashtagWithString:@"#Bonfire"];
                [FBSDKShareDialog showFromViewController:[Launcher topMostViewController]
                                              withContent:content
                                                                 delegate:nil];
            }
            else if ([identifier isEqualToString:@"imessage"]) {
                [Launcher shareOniMessage:message image:nil];
            }
            else if ([identifier isEqualToString:@"snapchat"]) {
                [Launcher shareOnSnapchat];
            }
            else if ([identifier isEqualToString:@"more"]) {
                UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[message] applicationActivities:nil];
                controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                
                [[Launcher topMostViewController] presentViewController:controller animated:YES completion:nil];
            }
        }];
    }
    
    [self layoutViews];
}

- (void)initInvitedProgressView {
    self.invitedProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, self.peopleInFrontLabel.frame.origin.y, self.centerView.frame.size.width, 24)];
    self.invitedProgressView.layer.cornerRadius = self.invitedProgressView.frame.size.height / 2;
    self.invitedProgressView.backgroundColor = [UIColor tableViewSeparatorColor];
    [self.centerView addSubview:self.invitedProgressView];
    
    UIColor *topLeftColor = [UIColor colorWithDisplayP3Red:1 green:0.35 blue:0.93 alpha:1];
    UIColor *bottomRightColor = [UIColor colorWithDisplayP3Red:0.90 green:0 blue:0 alpha:1];
    
    self.invitedProgressGradientLayer = [CAGradientLayer layer];
    self.invitedProgressGradientLayer.colors = [NSArray arrayWithObjects:(id)topLeftColor.CGColor, bottomRightColor.CGColor, nil];
    self.invitedProgressGradientLayer.startPoint = CGPointMake(0, 0);
    self.invitedProgressGradientLayer.endPoint = CGPointMake(1, 1);
    self.invitedProgressGradientLayer.cornerRadius = self.invitedProgressView.frame.size.height / 2;
    self.invitedProgressGradientLayer.frame = CGRectMake(0, 0, 0, self.invitedProgressView.frame.size.height);
    [self.invitedProgressView.layer addSublayer:self.invitedProgressGradientLayer];
}

- (void)setInviteStatus:(InviteStatusModel *)inviteStatus {
    if (inviteStatus != _inviteStatus) {
        NSInteger invitesNeeded_before = MAX(_inviteStatus.totalInvitesRequired - _inviteStatus.invitees.count, 0);
        NSInteger totalInvitesRequired_before = _inviteStatus.totalInvitesRequired;
        
        _inviteStatus = inviteStatus;
        
        // update rank
        self.rank = inviteStatus.rank;
        
        // update invites needed label
        NSInteger invitesNeeded_after = MAX(inviteStatus.totalInvitesRequired - inviteStatus.invitees.count, 0);
        NSInteger totalInvitesRequired_after = inviteStatus.totalInvitesRequired;
        
        // animate the invites needed change
        if (invitesNeeded_before != invitesNeeded_after) {
            BOOL animated = self.invitesNeededLabel.text.length > 0;
            [UIView animateWithDuration:(animated ? 0.6f : 0) delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.invitesNeededLabel.alpha = 0.0;
            } completion:^(BOOL finished) {
                // TODO: Highlight the friends remaining text
                NSString *friendsNeededString = [NSString stringWithFormat:@"%lu friend%@", (long)invitesNeeded_after, (invitesNeeded_after == 1 ? @"" : @"s")];
                NSString *friendCode = [Session sharedInstance].currentUser.attributes.invites.friendCode;
                
                NSMutableAttributedString *attributedInvitesNeededString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Invite %@ to skip the line       Your Friend Code is %@   ", friendsNeededString, friendCode] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightRegular], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
                [attributedInvitesNeededString addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold], NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]} range:[attributedInvitesNeededString.string rangeOfString:friendsNeededString]];
                [attributedInvitesNeededString addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold], NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]} range:[attributedInvitesNeededString.string rangeOfString:friendCode]];
                self.invitesNeededLabel.attributedText = attributedInvitesNeededString;
                
                [UIView animateWithDuration:(animated ? 0.6f : 0) delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.invitesNeededLabel.alpha = 1.0;
                } completion:nil];
            }];
        }
        
        if (totalInvitesRequired_before != totalInvitesRequired_after) {
            [self drawInvitedProgressView];
        }
    }
}

- (void)drawInvitedProgressView {
    NSInteger required = _inviteStatus.totalInvitesRequired;
    DLog(@"%li", (long)required);
    if (!self.invitedAvatarViews) {
        self.invitedAvatarViews = [NSMutableArray new];
        // create the avatar views
        for (float i = 1; i < required; i++) {
            DLog(@"i %f", i);
            UIView *avatarContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
            avatarContainer.center = CGPointMake(roundf(self.invitedProgressView.frame.size.width * (i / required)), self.invitedProgressView.frame.size.height / 2);
            avatarContainer.backgroundColor = [UIColor whiteColor];
            avatarContainer.layer.shadowOffset = CGSizeMake(0, 1);
            avatarContainer.layer.shadowRadius = 2.f;
            avatarContainer.layer.shadowOpacity = 0.12;
            avatarContainer.layer.shadowColor = [UIColor blackColor].CGColor;
            avatarContainer.layer.cornerRadius = avatarContainer.frame.size.height / 2;
            [self.invitedProgressView addSubview:avatarContainer];
            
            BFAvatarView *avatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, self.invitedProgressView.frame.size.height, self.invitedProgressView.frame.size.height)];
            avatar.center = CGPointMake(avatarContainer.frame.size.width / 2, avatarContainer.frame.size.height / 2);
            DLog(@"required: %li", required);
            DLog(@"meh: %f", self.invitedProgressView.frame.size.width);
            DLog(@"i / required: %f", (i / required));
            avatar.imageView.backgroundColor = [UIColor contentBackgroundColor];
            avatar.imageView.image = nil;
            avatar.transform = CGAffineTransformMakeScale(0.01, 0.01);
            [avatarContainer addSubview:avatar];
            
            [self.invitedAvatarViews addObject:avatar];
        }
    }
    
    // fill in the avatars
    NSArray <User *> *invitees = self.inviteStatus.invitees;
    
    CGFloat progress = (float)invitees.count / required;
    CGFloat duration = (invitees.count * 0.9f);
    CGFloat newWidth = ceilf(self.invitedProgressView.frame.size.width * (progress)) + (progress > 0 && progress < 1 ? 12 : 0);
    CGRect newBounds = CGRectMake(0, self.invitedProgressGradientLayer.bounds.origin.y, newWidth, self.invitedProgressGradientLayer.frame.size.height);
    
    CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    boundsAnimation.duration = duration;
    self.invitedProgressGradientLayer.bounds = newBounds;
    
    CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    positionAnimation.duration = duration;
    self.invitedProgressGradientLayer.position = CGPointMake(newWidth / 2, self.invitedProgressGradientLayer.position.y);
    
    [self.invitedProgressGradientLayer addAnimation:boundsAnimation forKey:@"bounds"];
    [self.invitedProgressGradientLayer addAnimation:positionAnimation forKey:@"position"];
    
    for (NSInteger i = 0; i < self.invitedAvatarViews.count; i++) {
        BFAvatarView *avatar = self.invitedAvatarViews[i];
        UIView *avatarContainer = avatar.superview;
        
        [UIView animateWithDuration:0.7f delay:(i+1)*0.85f usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (i < invitees.count) {
                avatar.user = invitees[i];
                avatar.transform = CGAffineTransformMakeScale(1, 1);
                avatar.alpha = 1;
                avatarContainer.frame = CGRectMake(avatarContainer.frame.origin.x, avatarContainer.frame.origin.y, self.invitedProgressView.frame.size.height + 8, self.invitedProgressView.frame.size.height + 8);
            }
            else {
                avatar.imageView.backgroundColor = [UIColor contentBackgroundColor];
                avatar.imageView.image = nil;
                avatar.transform = CGAffineTransformMakeScale(0.01, 0.01);
                avatar.alpha = 0;
                avatarContainer.frame = CGRectMake(avatarContainer.frame.origin.x, avatarContainer.frame.origin.y, 12, 12);
            }
            avatarContainer.layer.cornerRadius = avatarContainer.frame.size.height / 2;
            avatar.center = CGPointMake(avatarContainer.frame.size.width / 2, avatarContainer.frame.size.height / 2);
            avatarContainer.center = CGPointMake(roundf(self.invitedProgressView.frame.size.width * (((float)i+1) / required)), self.invitedProgressView.frame.size.height / 2);
        } completion:nil];
    }
}

- (void)setRank:(NSInteger)rank {
    BOOL changed = rank != _rank;
    
    if (changed || self.peopleInFrontLabel.text.length == 0) {
        _rank = rank;
        
        if (self.rankLabel) {
            [self updateRank:rank animated:changed&&self.upToDate];
        }
    }
}

- (UILabel *)newRankLabel {
    UILabel *newLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.centerView.frame.size.width, 86)];
    newLabel.textAlignment = NSTextAlignmentCenter;
    newLabel.clipsToBounds = false;
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle]; // this line is important!
    NSString *formatted = [formatter stringFromNumber:[NSNumber numberWithInteger:self.rank]];
    
    newLabel.text = formatted;
    
    NSInteger fontSize = MIN(156, MAX(80, ceilf(((self.centerView.frame.size.width * .8) / newLabel.text.length) * (10 / 7))));
    newLabel.font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightHeavy];
    DLog(@"New label font size: %lu", (long)fontSize);
    
    CGSize newLabelSize = [newLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, newLabel.font.lineHeight) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: newLabel.font} context:nil].size;
    CGFloat newWidth = ceilf(newLabelSize.width);
    CGFloat newHeight = ceilf(newLabelSize.height);
    newLabel.frame = CGRectMake(self.centerView.frame.size.width / 2 - newWidth / 2, newLabel.frame.origin.y, newWidth, newHeight);
    
    if (self.rank == 0) {
        newLabel.textColor = [UIColor colorWithPatternImage:[self gradientImageForView:newLabel topLeftColor:[UIColor colorWithDisplayP3Red:0.77 green:0.77 blue:0.77 alpha:1] bottomRightColor:[UIColor colorWithDisplayP3Red:0.99 green:0.99 blue:0.99 alpha:1]]];
    }
    else {
        newLabel.textColor = [UIColor colorWithPatternImage:[self gradientImageForView:newLabel topLeftColor:[UIColor colorWithDisplayP3Red:1 green:0.35 blue:0.93 alpha:1] bottomRightColor:[UIColor colorWithDisplayP3Red:0.90 green:0 blue:0 alpha:1]]];
    }
    
    return newLabel;
}

- (void)updateRank:(NSInteger)rank animated:(BOOL)animated {
    UILabel *newRankLabel = [self newRankLabel];
    newRankLabel.alpha = 0;
    [self.centerView addSubview:newRankLabel];
    
    UILabel *oldLabel = self.rankLabel;
    
    BOOL rankHeightChange = (self.rankLabel.frame.size.height != newRankLabel.frame.size.height);
    
    [UIView animateWithDuration:animated?0.3f:0 delay:0.25f options:UIViewAnimationOptionCurveEaseOut animations:^{
        if (oldLabel) {
            oldLabel.transform = CGAffineTransformMakeScale(0.1, 0.1);
            oldLabel.alpha = 0;
        }
    } completion:^(BOOL finished) {
        self.rankLabel = newRankLabel;
        newRankLabel.alpha = 0;
        newRankLabel.transform = CGAffineTransformIdentity;
        
        [UIView animateWithDuration:animated&&rankHeightChange?0.3f:0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self layoutViews];
        } completion:^(BOOL finished) {
            newRankLabel.transform = CGAffineTransformMakeScale(0.1, 0.1);
            
            [UIView animateWithDuration:animated?0.9f:0 delay:0 usingSpringWithDamping:0.65 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.rankLabel.alpha = 1;
                self.rankLabel.transform = CGAffineTransformIdentity;
            } completion:nil];
        }];
    }];
}

- (UIImage *)gradientImageForView:(UIView *)view topLeftColor:(UIColor *)topLeftColor bottomRightColor:(UIColor *)bottomRightColor {
    CGSize size = view.frame.size;
    CGFloat width = size.width;
    CGFloat height = size.height;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    NSArray *colors = @[(__bridge id)topLeftColor.CGColor, (__bridge id)bottomRightColor.CGColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);

    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(width, height), 0);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)layoutViews {
    CGAffineTransform transform_before = self.centerView.transform;
    self.centerView.transform = CGAffineTransformIdentity;
    
    self.rankLabel.center = CGPointMake(self.centerView.frame.size.width / 2, self.rankLabel.center.y);
    self.peopleInFrontLabel.frame = CGRectMake(0, self.rankLabel.frame.origin.y + self.rankLabel.frame.size.height + 8, self.centerView.frame.size.width, self.peopleInFrontLabel.frame.size.height);
    
    SetY(self.invitedProgressView, self.peopleInFrontLabel.frame.origin.y + self.peopleInFrontLabel.frame.size.height + 24);
    
    SetY(self.invitesNeededLabel, self.invitedProgressView.frame.origin.y + self.invitedProgressView.frame.size.height + 24);
    
    SetY(self.shareActionsView, self.invitesNeededLabel.frame.origin.y + self.invitesNeededLabel.frame.size.height + 16);
    
    CGFloat newHeight = self.shareActionsView.frame.origin.y + self.shareActionsView.frame.size.height;
    self.centerView.frame = CGRectMake(self.centerView.frame.origin.x, self.view.frame.size.height / 2 - newHeight / 2, self.centerView.frame.size.width, newHeight);
    
    self.centerView.transform = transform_before;
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (void)welcomeUser {
    DLog(@"welcome the user 🎈🎈🎈");
    // hide the loading spinner
    [self setSpinning:false animated:true];
    
    // 0) hide all existing views
    [UIView animateWithDuration:0.75f animations:^{
        for (UIView *subview in self.view.subviews) {
            subview.alpha = 0;
        }
    } completion:^(BOOL finished) {
        // animate in the new welcome view
        UILabel *welcome = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height / 2 - 25, self.view.frame.size.width, 50)];
        welcome.text = @"Welcome!";
        welcome.textAlignment = NSTextAlignmentCenter;
        welcome.font = [UIFont systemFontOfSize:42.f weight:UIFontWeightHeavy];
        SetWidth(welcome, ceilf([welcome.text boundingRectWithSize:welcome.frame.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: welcome.font} context:nil].size.width));
        welcome.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        welcome.textColor = [UIColor colorWithPatternImage:[self gradientImageForView:welcome topLeftColor:[UIColor colorWithDisplayP3Red:1 green:0.35 blue:0.93 alpha:1] bottomRightColor:[UIColor colorWithDisplayP3Red:0.90 green:0 blue:0 alpha:1]]];
        welcome.alpha = 0;
        welcome.transform = CGAffineTransformMakeScale(1.2, 1.2);
        [self.view addSubview:welcome];
        
        // 1) show welcome label
        [UIView animateWithDuration:0.5f delay:0.2f options:UIViewAnimationOptionCurveEaseOut animations:^{
            welcome.alpha = 1;
            welcome.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {
            // 2) start balloons
            [self startBalloons];
            
            wait(4.0f, ^{
                // 3) present logged in view controller
                DLog(@"present logged in view controller");
                [Launcher launchLoggedIn:true replaceRootViewController:false];
            });
        }];
    }];
    
}

- (void)startBalloons {
    DLog(@"start balloons!!!!");
    NSMutableArray *balloons = [NSMutableArray new];
    
    [balloons addObject:@{
        @"color": @"orange",
        @"scale": @(1.0),
        @"xPosStart": @(0),
        @"xPosEnd": @(0.1),
        @"delay": @(0),
        @"duration": @(4.5)
    }];
    
    [balloons addObject:@{
        @"color": @"yellow",
        @"scale": @(1.25),
        @"xPosStart": @(0.25),
        @"xPosEnd": @(0.4),
        @"delay": @(0.4),
        @"duration": @(3.75)
    }];
    
    [balloons addObject:@{
        @"color": @"blue",
        @"scale": @(0.75),
        @"xPosStart": @(0.4),
        @"xPosEnd": @(0.3),
        @"delay": @(1.0),
        @"duration": @(4)
    }];
    
    [balloons addObject:@{
        @"color": @"green",
        @"scale": @(1.0),
        @"xPosStart": @(0.1),
        @"xPosEnd": @(0.15),
        @"delay": @(1.2),
        @"duration": @(5)
    }];
    
    [balloons addObject:@{
        @"color": @"pink",
        @"scale": @(1.5),
        @"xPosStart": @(0.8),
        @"xPosEnd": @(0.65),
        @"delay": @(1.6),
        @"duration": @(3.5)
    }];
    
    [balloons addObject:@{
        @"color": @"purple",
        @"scale": @(1.75),
        @"xPosStart": @(0.9),
        @"xPosEnd": @(0.95),
        @"delay": @(2.5),
        @"duration": @(4)
    }];
    
    [balloons addObject:@{
        @"color": @"orange",
        @"scale": @(1.75),
        @"xPosStart": @(0.0),
        @"xPosEnd": @(0.95),
        @"delay": @(2.3),
        @"duration": @(3)
    }];
    
    CGFloat xMin = -40;
    CGFloat xMax = self.view.frame.size.width + 40;
    for (NSInteger b = 0; b < balloons.count; b++) {
        NSDictionary *balloon = balloons[b];
        
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"balloon_%@", balloon[@"color"]]];
        CGFloat scale = [balloon[@"scale"] floatValue];
        CGFloat width = image.size.width * scale;
        CGFloat height = image.size.height * scale;
        CGFloat xStart = [balloon[@"xPosStart"] floatValue] * ((xMax - width) - xMin);
        CGFloat xEnd = [balloon[@"xPosEnd"] floatValue] * ((xMax - width) - xMin);
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.frame = CGRectMake(xStart, self.view.frame.size.height, width, height);
        [self.view addSubview:imageView];
        
        [UIView animateWithDuration:[balloon[@"duration"] floatValue] delay:[balloon[@"delay"] floatValue] options:UIViewAnimationOptionCurveEaseOut animations:^{
            imageView.frame = CGRectMake(xEnd, -(height), width, height);
        } completion:^(BOOL finished) {
            [imageView removeFromSuperview];
        }];
    }
}

- (void)shakeFriendButton {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.16f];
    [animation setRepeatCount:0];
    [animation setAutoreverses:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    
    UIViewController *activeViewController = [Launcher activeViewController];
    if ([activeViewController isKindOfClass:[UITabBarController class]]) {
        activeViewController = ((UITabBarController *)activeViewController).selectedViewController;
    }
    
    NSInteger shakeDistance = 3;
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake(self.redeemButton.center.x + shakeDistance, self.redeemButton.center.y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake(self.redeemButton.center.x - shakeDistance, self.redeemButton.center.y)]];
    [self.redeemButton.layer addAnimation:animation forKey:@"position"];
    
    [HapticHelper generateFeedback:FeedbackType_Notification_Error];
}

@end

@implementation InviteStatusModel

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
}

@end
