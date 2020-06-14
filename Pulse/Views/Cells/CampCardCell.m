//
//  CampCardCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "CampCardCell.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "BFAlertController.h"
#import "BFTipsManager.h"
#import "Launcher.h"

@implementation CampCardCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.camp = [[Camp alloc] init];
        
        [self setCornerRadiusType:BFCornerRadiusTypeSmall];
        [self setElevation:1];
        
        self.contentView.layer.cornerRadius = self.layer.cornerRadius;
        self.contentView.layer.masksToBounds = true;
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (state == UIGestureRecognizerStateBegan) {
                // recognized long press
                BFAlertController *options = [BFAlertController alertControllerWithTitle:self.camp.attributes.title message:(self.camp.attributes.identifier.length > 0 ? [@"#" stringByAppendingString:self.camp.attributes.identifier] : nil) preferredStyle:BFAlertControllerStyleActionSheet];
                
                if ([self.camp isMember]) {
                    BOOL isFavorite = [self.camp isFavorite];
                    
                    BFAlertAction *star = [BFAlertAction actionWithTitle:(isFavorite?@"Remove from Favorites":@"Add to Favorites") style:(isFavorite?BFAlertActionStyleDestructive:BFAlertActionStyleDefault) handler:^{
                        if (isFavorite) {
                            [self.camp unFavorite];
                        }
                        else {
                            if (![BFTipsManager hasSeenTip:@"about_favorited_camps"]) {
                                BFAlertController *about = [BFAlertController alertControllerWithIcon:[UIImage imageNamed:@"alert_icon_star"] title:@"Add to Favorites?" message:@"Favorited Camps appear at the top of your Camps list and get shown more in your feed." preferredStyle:BFAlertControllerStyleAlert];

                                BFAlertAction *favoriteCamp = [BFAlertAction actionWithTitle:@"Favorite" style:BFAlertActionStyleDefault handler:^{
                                    [self.camp favorite];
                                }];
                                [about addAction:favoriteCamp];

                                BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
                                [about addAction:cancel];

                                [about show];
                            }
                            else {
                                [self.camp favorite];
                            }
                        }
                    }];
                    [options addAction:star];
                }
                
                BFAlertAction *shareCamp = [BFAlertAction actionWithTitle:@"Share Camp" style:BFAlertActionStyleDefault handler:^{
                    [Launcher shareCamp:self.camp];
                }];
                [options addAction:shareCamp];
                
                BFAlertAction *openCamp = [BFAlertAction actionWithTitle:@"Open Camp" style:BFAlertActionStyleDefault handler:^{
                    [Launcher openCamp:self.camp];
                }];
                [options addAction:openCamp];
                
                BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
                [options addAction:cancel];
                
                [options show];
            }
        }];
        [self addGestureRecognizer:longPress];
        
        
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    // support dark mode
    [self themeChanged];
}

@end
