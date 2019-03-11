//
//  NSString+HTMLtoNSAttributedString.h
//  Shukofukurou
//
//  Created by 天々座理世 on 2017/03/29.
//  Copyright © 2017-2018 MAL Updater OS X Group and Moy IT Solutions. All rights reserved. Licensed under 3-clause BSD License
//

#import <Foundation/Foundation.h>
#import <Appkit/Appkit.h>

@interface NSString (HTMLtoNSAttributedString)
- (NSAttributedString *)convertHTMLtoAttStr;
@end
