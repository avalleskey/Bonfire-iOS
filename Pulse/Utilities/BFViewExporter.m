//
//  BFTableViewCellExporter.m
//  Pulse
//
//  Created by Austin Valleskey on 8/30/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFViewExporter.h"
#import "UIColor+Palette.h"
#import "BFAvatarView.h"
#import "Session.h"
#import "BFPostAttachmentView.h"
#import "UIView+Styles.h"

@interface BFViewExporter()

@property (nonatomic, strong) id cell;
@property (nonatomic) CGSize size;

@end

@implementation BFViewExporter

+ (BFViewExporter *)sharedExporter {
    static BFViewExporter *_sharedExporter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedExporter = [[self alloc] init];
    });
    
    return _sharedExporter;
}

+ (UIImage *)imageForCell:(id)cell size:(CGSize)size {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.delegate = [BFViewExporter sharedExporter];
    tableView.dataSource = [BFViewExporter sharedExporter];
    [BFViewExporter sharedExporter].cell = cell;
    [BFViewExporter sharedExporter].size = size;
    [tableView reloadData];
    
    return [BFViewExporter imageForView:tableView];
}
+ (UIImage *)imageForView:(UIView *)view container:(BOOL)container {
    CGSize size = view.frame.size;
    
    CGFloat footerHeight = 48.f;
    UIEdgeInsets padding = UIEdgeInsetsZero;
    if (container) {
        padding = UIEdgeInsetsMake(24, 24, 24 + footerHeight, 24);
        
        CGFloat newContainerWidth = size.width + padding.left + padding.right;
        CGFloat newContainerHeight = size.height + padding.top + padding.bottom;
        
        if (newContainerWidth > newContainerHeight) {
            CGFloat verticalPadding = (newContainerWidth - newContainerHeight) / 2;
            padding.top += verticalPadding;
            padding.bottom += verticalPadding;
        }
    }
    DLog(@"padding: %f %f %f %f", padding.top, padding.left, padding.bottom, padding.right);
    CGFloat cornerRadius = container ? 0 : 0;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width + padding.left + padding.right, size.height + padding.top + padding.bottom)];
    containerView.backgroundColor = container ? [UIColor tableViewBackgroundColor] : [UIColor clearColor];
    
    if (container) {
        UIView *tableViewContainerView = [[UIView alloc] initWithFrame:CGRectMake(padding.left, padding.top, view.frame.size.width, view.frame.size.height)];
        tableViewContainerView.layer.cornerRadius = view.layer.cornerRadius;
        [tableViewContainerView setElevation:1];
        tableViewContainerView.layer.borderWidth = 0;
        [tableViewContainerView addSubview:view];
        
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, containerView.frame.size.height - footerHeight, view.frame.size.width + padding.left + padding.right, footerHeight)];
//        [footer setElevation:2];
//        footer.backgroundColor = [UIColor colorNamed:@"Navigation_ClearBackgroundColor"];
        
        UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(padding.left, 0, footer.frame.size.width - padding.left - padding.right, HALF_PIXEL)];
        lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [footer addSubview:lineSeparator];
        
        UIImageView *bonfireLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchLogo"]];
        bonfireLogo.frame = CGRectMake(footer.frame.size.width - 24 - padding.right, 12, 24, 24);
        [footer addSubview:bonfireLogo];
        
        UILabel *bonfireDownloadURL = [[UILabel alloc] initWithFrame:CGRectMake(bonfireLogo.frame.origin.x - 120 - 8, 0, 120, footer.frame.size.height)];
        bonfireDownloadURL.textAlignment = NSTextAlignmentRight;
        bonfireDownloadURL.textColor = [UIColor bonfirePrimaryColor];
        bonfireDownloadURL.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
        bonfireDownloadURL.text = @"joinbonfire.com";
        [footer addSubview:bonfireDownloadURL];
        
        BFAvatarView *currentUser = [[BFAvatarView alloc] initWithFrame:CGRectMake(padding.left, 12, 24, 24)];
        currentUser.user = [Session sharedInstance].currentUser;
        [footer addSubview:currentUser];
        
        UILabel *sharedBy = [[UILabel alloc] initWithFrame:CGRectMake(currentUser.frame.origin.x + currentUser.frame.size.width + 8, 0, bonfireDownloadURL.frame.origin.x - 8 - (currentUser.frame.origin.x + currentUser.frame.size.width + 8), footer.frame.size.height)];
        
        NSString *username = [NSString stringWithFormat:@"@%@", [Session sharedInstance].currentUser.attributes.identifier];
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"shared by %@", username] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        [attributedString addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]} range:[attributedString.string rangeOfString:username]];
        
        sharedBy.attributedText = attributedString;
        [footer addSubview:sharedBy];
        
        [containerView addSubview:tableViewContainerView];
        [containerView addSubview:footer];
        
        if ([view isKindOfClass:[BFPostAttachmentView class]]) {
            BFPostAttachmentView *attachmentView = (BFPostAttachmentView *)view;
            attachmentView.contentView.layer.borderColor = [UIColor clearColor].CGColor;
            attachmentView.contentView.layer.borderWidth = 0;
        }
    }
    else {
        view.frame = CGRectMake(padding.left, padding.top, view.frame.size.width, view.frame.size.height);
        [containerView addSubview:view];
    }
        
    // capture screenshot
    UIGraphicsBeginImageContextWithOptions(containerView.bounds.size, NO, 3.f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, containerView.bounds);
    [containerView.layer renderInContext:context];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return snapshotImage;
}
+ (UIImage *)imageForView:(UIView *)view {
    return [self imageForView:view container:true];
}
+ (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
    sender.layer.shadowPath = maskLayer.path;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (self.cell) {
        //[self.cell layoutSubviews];
        return self.cell;
    }
    
    UITableViewCell *cell = [UITableViewCell new];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"self.size.height: %f", self.size.height);
    return self.size.height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

@end
