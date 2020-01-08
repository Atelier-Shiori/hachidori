//
//  Log.m
//  Hachidori
//
//  Created by 香風智乃 on 3/10/19.
//

#import "Log.h"

@implementation Log
void append(NSString *msg){
    NSString *documentsDirectory = [Log retrieveApplicationSupportDirectory:@""];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"Hachidori.log"];
    NSDate *clearlogdate = [NSUserDefaults.standardUserDefaults valueForKey:@"NextLogClearDate"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]
        || !clearlogdate || (clearlogdate && [clearlogdate timeIntervalSinceNow] <= 0)){
        fprintf(stderr,"Creating new log file at %s",[path UTF8String]);
        [[NSData data] writeToFile:path atomically:YES];
        [NSUserDefaults.standardUserDefaults setValue:[NSDate dateWithTimeIntervalSinceNow:1209600] forKey:@"NextLogClearDate"];
    }
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    [handle writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
}

void _Log(NSString *prefix, const char *file, int lineNumber, const char *funcName, NSString *format,...) {
    va_list ap;
    va_start (ap, format);
    format = [format stringByAppendingString:@"\n"];
    NSDate *date = [NSDate date];
    
    NSString *msg = [[NSString alloc] initWithFormat:[NSString stringWithFormat:@"[%@ %@] %@",[NSDateFormatter localizedStringFromDate: date
    dateStyle: NSDateFormatterShortStyle
    timeStyle: NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate: date
    dateStyle: NSDateFormatterNoStyle
    timeStyle: NSDateFormatterShortStyle], format] arguments:ap];
    va_end (ap);
    fprintf(stderr,"%s%50s:%3d - %s",[prefix UTF8String], funcName, lineNumber, [msg UTF8String]);
    append(msg);
}

+ (NSString *)retrieveApplicationSupportDirectory:(NSString*)append{
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSError *error;
    NSString *bundlename = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
    append = [NSString stringWithFormat:@"%@/%@", bundlename, append];
    NSURL *path = [filemanager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:true error:&error];
    NSString *dir = [NSString stringWithFormat:@"%@/%@",path.path,append];
    if (![filemanager fileExistsAtPath:dir isDirectory:nil]) {
        NSError *ferror;
        bool success = [filemanager createDirectoryAtPath:dir withIntermediateDirectories:true attributes:nil error:&ferror];
        if (success && ferror == nil) {
            return dir;
        }
        return @"";
    }
    return dir;
}

+ (void)openLogFile {
    NSString *path = [self retrieveApplicationSupportDirectory:@""];
    NSFileManager *filemanger = [NSFileManager defaultManager];
    NSString *fullfilenamewithpath = [NSString stringWithFormat:@"%@/%@.log",path, [NSBundle mainBundle].infoDictionary[@"CFBundleName"]];
    if (![filemanger fileExistsAtPath:fullfilenamewithpath]) {
        return;
    }
    [NSWorkspace.sharedWorkspace openFile:fullfilenamewithpath];
}
@end
