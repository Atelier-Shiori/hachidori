//
//  CrashWindowController.h
//  Hachidori
//
//  Created by 香風智乃 on 4/6/19.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface CrashWindowController : NSWindowController
@property (strong) IBOutlet NSTextView *commentstextview;
@property (strong) IBOutlet NSButton *includelog;

@end

NS_ASSUME_NONNULL_END
