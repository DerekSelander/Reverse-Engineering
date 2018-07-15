//
//  CSGradientView.m
//  async_wake_ios
//
//  Created by CoolStar on 1/12/18.
//  Copyright © 2018 CoolStar. All rights reserved.
//

#import "CSGradientView.h"
#import <QuartzCore/QuartzCore.h>

@implementation CSGradientView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self){
        CAGradientLayer *layer = (CAGradientLayer *)self.layer;
        layer.startPoint = CGPointMake(0, 0);
        layer.endPoint = CGPointMake(1, 1);
        layer.colors = @[(id)[[UIColor colorWithRed:0.227450982 green:0.274509817 blue:0.356862754 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:0.325490206 green:0.412549019 blue:0.463921577 alpha:1.0] CGColor]];
    }
    return self;
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
