//
//  PingNotifier.h
//  DetectionKit
//
//  Created by 桐間紗路 on 2017/09/26.
//  Copyright © 2017年 Atelier Shiori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GBPing/GBPing.h"
@class GBPing;

@interface PingNotifier : NSObject <GBPingDelegate>
@property (nonatomic, copy) void (^onlineblock)(void);
@property (nonatomic, copy) void (^offlineblock)(void);
@property (getter=getOnline) bool isOnline;
@property (getter=getisSetUp) bool isSetUp;
@property (getter=getisActive) bool isActive;
@property (strong) GBPing *pingclient;

- (id)initWithHost:(NSString *)hostname;
- (void)changeHostName:(NSString *)hostname;
- (void)startPing;
- (void)stopPing;
@end
