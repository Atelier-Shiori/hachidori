//
//  streamlinkdetectordelegate.h
//  streamlinkdetect
//
//  Created by 天々座理世 on 2017/04/04.
//  Copyright © 2017年 Atelier Shiori. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 This provide call backs when a stream has began or endded.
 */
@protocol streamlinkdetectordelegate <NSObject>
@optional
/**
 Delegate method when a stream begins.
 */
- (void)streamDidBegin;
/**
 Delegate method when a stream has ended.
 */
- (void)streamDidEnd;
@end
