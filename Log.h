//
//  Log.h
//  Hachidori
//
//  Created by 香風智乃 on 3/10/19.
//

#import <Foundation/Foundation.h>
#define NSLog(args...) _Log(@"DEBUG ", __FILE__,__LINE__,__PRETTY_FUNCTION__,args);

NS_ASSUME_NONNULL_BEGIN

@interface Log : NSObject
void _Log(NSString *prefix, const char *file, int lineNumber, const char *funcName, NSString *format,...);
+ (void)openLogFile;
@end

NS_ASSUME_NONNULL_END
