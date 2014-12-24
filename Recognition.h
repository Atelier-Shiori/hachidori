//
//  Recognition.h
//  Hachidori
//
//  Created by 高町なのは on 2014/11/16.
//  Copyright 2014-2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Foundation/Foundation.h>
#import <OgreKit/OgreKit.h>
#import <anitomy-osx/anitomy-objc-wrapper.h>

@interface Recognition : NSObject
-(NSDictionary*)recognize:(NSString *)string;
@end
