//
//  BFTableViewCellExporter.m
//  Pulse
//
//  Created by Austin Valleskey on 8/30/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFViewExporter.h"
#import "UIColor+Palette.h"

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
    
    CGFloat footerHeight = 32.f;
    UIEdgeInsets padding = container ? UIEdgeInsetsMake(24, 24, 24 + footerHeight + 16, 24) : UIEdgeInsetsZero;
    DLog(@"padding: %f %f %f %f", padding.top, padding.left, padding.bottom, padding.right);
    CGFloat cornerRadius = container ? 20.f : 0;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width + padding.left + padding.right, size.height + padding.top + padding.bottom)];
    containerView.backgroundColor = container ? [UIColor tableViewBackgroundColor] : [UIColor clearColor];
    
    if (container) {
        [BFViewExporter continuityRadiusForView:view withRadius:cornerRadius];
        
        UIView *tableViewContainerView = [[UIView alloc] initWithFrame:CGRectMake(padding.left, padding.top, view.frame.size.width, view.frame.size.height)];
        [BFViewExporter continuityRadiusForView:tableViewContainerView withRadius:cornerRadius];
        [tableViewContainerView addSubview:view];
        
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(tableViewContainerView.frame.origin.x, tableViewContainerView.frame.origin.y + tableViewContainerView.frame.size.height + 16, view.frame.size.width, footerHeight)];
        UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bonfireShareFooterImage"]];
        logo.frame = CGRectMake(footer.frame.size.width / 2 - (168 / 2), 0, 168, 32);
        [footer addSubview:logo];
            
        [containerView addSubview:tableViewContainerView];
        [containerView addSubview:footer];
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
