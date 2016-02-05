//
//  NSObject_Extension.m
//  ThinStrokes
//
//  Created by Christopher Liscio on 2016-02-04.
//  Copyright © 2016 Christopher Liscio. All rights reserved.
//


#import "NSObject_Extension.h"
#import "ThinStrokes.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[ThinStrokes alloc] initWithBundle:plugin];
        });
    }
}
@end
