//
//  Detection.h
//  Hachidori
//
//  Created by Tail Red on 1/31/15.
//  Copyright 2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Foundation/Foundation.h>
#import <OgreKit/OgreKit.h>

@interface Detection : NSObject
+(NSDictionary *)detectmedia;
+(NSDictionary *)checksstreamlinkinfo:(NSDictionary *)d;
@end
