//
//  TappableButton.m
//  Pulse
//
//  Created by Austin Valleskey on 12/13/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "TappableButton.h"

@implementation TappableButton

-(BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect newArea = CGRectMake(self.bounds.origin.x - self.padding.left, self.bounds.origin.y - self.padding.top, self.bounds.size.width + (self.padding.left + self.padding.right), self.bounds.size.height + (self.padding.top + self.padding.bottom));
    
    return CGRectContainsPoint(newArea, point);
}

@end
