//
//  AuthWebView.h
//  Shukofukurou
//
//  Created by 小鳥遊六花 on 4/24/18.
//  Copyright © 2017-2018 MAL Updater OS X Group and Moy IT Solutions. All rights reserved. Licensed under 3-clause BSD License
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface AuthWebView : NSViewController <WKUIDelegate,WKNavigationDelegate>
@property (nonatomic, copy) void (^completion)(NSString *pin);
- (void)loadAuthorization;
- (void)resetWebView;
@end
