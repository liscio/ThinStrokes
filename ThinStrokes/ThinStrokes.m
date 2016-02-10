//
//  ThinStrokes.m
//  ThinStrokes
//
//  Created by Christopher Liscio on 2016-02-04.
//  Copyright © 2016 Christopher Liscio, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "ThinStrokes.h"

extern void CGContextSetFontSmoothingStyle(CGContextRef, int);
extern int CGContextGetFontSmoothingStyle(CGContextRef);

@implementation ThinStrokes

+ (void)pluginDidLoad:(NSBundle *)plugin {
    Class DVTLayoutManager = NSClassFromString(@"DVTLayoutManager");
    if(!DVTLayoutManager) {
        NSLog(@"Couldn't find DVTLayoutManager, so ThinStrokes can't load. Reverting to normal font rendering.");
        return;
    }
    
    SEL showCGGlyphsSEL = @selector(showCGGlyphs:positions:count:font:matrix:attributes:inContext:);
    
    Method showCGGlyphsMethod = class_getInstanceMethod(DVTLayoutManager, showCGGlyphsSEL);
    IMP oldIMP = method_getImplementation(showCGGlyphsMethod);
    
    IMP newIMP = imp_implementationWithBlock(^(id self, const CGGlyph *glyphs, const NSPoint *positions, NSUInteger count, NSFont *font, NSAffineTransform *matrix, NSDictionary *attributes, NSGraphicsContext *inContext) {
        
        CGContextRef ctx = [inContext CGContext];
        
        // The below code—save for the swizzling—is copied nearly verbatim from
        // iTerm. Here's the source: https://github.com/gnachman/iTerm2/blob/76fe643f505eb3a0eed5a8390c39325e3c22d179/sources/iTermTextDrawingHelper.m#L681
        
        // This seems to be available at least on 10.8 and later. The only reference to it is in
        // WebKit. This causes text to render just a little lighter, which looks nicer.
        int savedFontSmoothingStyle = CGContextGetFontSmoothingStyle(ctx);
        CGContextSetFontSmoothingStyle(ctx, 16);
        
        CGContextSetTextDrawingMode(ctx, kCGTextFill);
        
        ((void (*)(id, SEL, const CGGlyph *, const NSPoint *, NSUInteger, NSFont *, NSAffineTransform *, NSDictionary *, NSGraphicsContext *))oldIMP)(self, showCGGlyphsSEL, glyphs, positions, count, font, matrix, attributes, inContext);
        
        CGContextSetFontSmoothingStyle(ctx, savedFontSmoothingStyle);
    });
    method_setImplementation(showCGGlyphsMethod, newIMP);
}

@end
