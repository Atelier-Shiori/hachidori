//
//  main.m
//  Hachidori
//
//  Created by James M. on 8/7/10.
//  Copyright 2009-2010 Chikorita157's Anime Blog. All rights reserved. Code licensed under New BSD License
//

#import <Cocoa/Cocoa.h>
#import <objc/objc-runtime.h>

int main(int argc, char *argv[])
{
    //Load VisualEffect as NSView on Operating Systems < 10.10
    if (![NSVisualEffectView class]) {
        Class NSVisualEffectViewClass = objc_allocateClassPair([NSView class], "NSVisualEffectView", 0);
        objc_registerClassPair(NSVisualEffectViewClass);
    }
    return NSApplicationMain(argc,  (const char **) argv);
}

