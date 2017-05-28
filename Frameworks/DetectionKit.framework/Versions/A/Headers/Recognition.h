//
//  Recognition.h
//  DetectionKit
//
//  Created by 高町なのは on 2014/11/16.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Foundation/Foundation.h>
/**
 This class allows you to perform recognition for a file name.
 */
@interface Recognition : NSObject
/**
 Performs recognition of a media file name.
 @param string The filename of a media file.
 @return NSDictionary The parsed media file information.
 */
-(NSDictionary*)recognize:(NSString *)string;
@end
