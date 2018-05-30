//
//  TorrentManager.h
//  TorrentBrowser
//
//  Created by James Moy on 2017/11/09.
//  Copyright © 2017 Moy IT Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface TorrentManager : NSObject
@property (strong) NSManagedObjectContext *moc;
@property bool timeractive;
@property bool autodownloadinprogress;
- (bool)startAutoDownloadTimer;
- (bool)stopAutoDownloadTimer;
- (void)fireAutoDownloadTimerNow;
- (void)retrievetorrent:(NSString *)url withFilename:(NSString *)filename completion:(void (^)(bool success))completionHandler error:(void (^)(NSError * error))errorHandler;
- (void)autodownloadtimerDidFire;
@end
