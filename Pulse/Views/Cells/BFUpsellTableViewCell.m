//
//  BFUpsellTableViewCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFUpsellTableViewCell.h"

@implementation BFUpsellTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundColor = [UIColor clearColor];
        
        self.upsellView = [[StartCampUpsellView alloc] initWithFrame:CGRectMake(16, 0, self.frame.size.width - 32, 100)];
        self.upsellView.center = self.center;
        [self.contentView addSubview:self.upsellView];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat padding = 32;
    
    self.upsellView.frame = CGRectMake(16, padding, self.frame.size.width - 32, self.upsellView.frame.size.height);
}

+ (CGFloat)heightWithImage:(BOOL)hasImage title:(NSString * _Nullable)title description:(NSString * _Nullable)description actions:(BOOL)actions {
    CGFloat padding = 32;
    
    CGFloat height = padding * 2;
    
    
    
    return height;
}

@end
