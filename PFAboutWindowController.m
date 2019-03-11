//
//  PFAboutWindowController.m
//
//  Copyright (c) 2015 Perceval FARAMAZ (@perfaram). All rights reserved.
//

#import "PFAboutWindowController.h"
#import <AFNetworking/AFNetworking.h>
#import "NSString+HTMLtoNSAttributedString.h"

@interface PFAboutWindowController()

/** The window nib to load. */
+ (NSString *)nibName;

/** The info view. */
@property (assign) IBOutlet NSView *infoView;

/** The main text view. */
@property (assign) IBOutlet NSTextView *textField;

/** The app version's text view. */
@property (assign) IBOutlet NSTextField *versionField;

/** The app version's text view. */
@property (assign) IBOutlet NSTextField *nameField;

/** The button that opens the app's website. */
@property (assign) IBOutlet NSButton *visitWebsiteButton;

/** The button that opens the EULA. */
@property (assign) IBOutlet NSButton *EULAButton;
    
@property (strong) IBOutlet NSButton *PatronsButton;
    
/** The button that opens the credits. */
@property (assign) IBOutlet NSButton *creditsButton;

/** The view that's currently active. */
@property (assign) NSView *activeView;

/** The string to hold the credits if we're showing them in same window. */
@property (copy) NSAttributedString *creditsString;

/** Select a background color (defaults to white). */
@property () NSColor *backgroundColor;

/** Select the title (app name & version) color (defaults to black). */
@property () NSColor *titleColor;

/** Select the text (Acknowledgments & EULA) color (defaults to light grey). */
@property () NSColor *textColor;

@end

@implementation PFAboutWindowController

#pragma mark - Class Methods

+ (NSString *)nibName {
    return @"PFAboutWindow";
}

#pragma mark - Overrides

- (id)init {
    self.windowShouldHaveShadow = YES;
    //self.backgroundColor = [NSColor whiteColor];
    //self.titleColor = [NSColor blackColor];
    self.textColor = (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9) ? NSColor.lightGrayColor : NSColor.controlTextColor;
    
    return [super initWithWindowNibName:[[self class] nibName]];
}

- (void)windowDidLoad {
    [super windowDidLoad];
	self.windowState = 0;
	self.infoView.layer.cornerRadius = 10.0;
    self.window.backgroundColor = self.backgroundColor;
    [self.window setHasShadow:self.windowShouldHaveShadow];
    // Change highlight of the `visitWebsiteButton` when it's clicked. Otherwise, the button will have a highlight around it which isn't visually pleasing.
    [self.visitWebsiteButton.cell setHighlightsBy:NSContentsCellMask];
   
    // Load variables
    NSDictionary *bundleDict = [[NSBundle mainBundle] infoDictionary];
    
    // Set app name
    if(!self.appName) {
        self.appName = [bundleDict objectForKey:@"CFBundleName"];
    }
    
    // Set app version
    if(!self.appVersion) {
        NSString *version = [bundleDict objectForKey:@"CFBundleVersion"];
        NSString *shortVersion = [bundleDict objectForKey:@"CFBundleShortVersionString"];
        self.appVersion = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (Build %@)", @"Version %@ (Build %@), displayed in the about window"), shortVersion, version];
    }
	
    // Set copyright
    if(!self.appCopyright) {
        self.appCopyright = [[NSAttributedString alloc] initWithString:[bundleDict objectForKey:@"NSHumanReadableCopyright"] attributes:@{
                                                                                                                                          NSFontAttributeName:[NSFont fontWithName:@"HelveticaNeue" size:11]/*/NSParagraphStyleAttributeName  : paragraphStyle*/}];
    }
	
	// Code that can potentially throw an exception
	// Set credits
	if(!self.appCredits) {
		@try {
			self.appCredits = [[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"] documentAttributes:nil];
		}
		@catch (NSException *exception) {
			// hide the credits button
			[self.creditsButton setHidden:YES];
             NSLog(@"PFAboutWindowController did handle exception: %@",exception);
		}
	}
	// Set EULA
	if(!self.appEULA) {
		@try {
			self.appEULA = [[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"EULA" ofType:@"rtf"] documentAttributes:nil];
		}
		@catch (NSException *exception) {
			// hide the eula button
			[self.EULAButton setHidden:YES];
			NSLog(@"PFAboutWindowController did handle exception: %@",exception);
		}
	}
    self.patronsList = [NSAttributedString new];
    [self generatePatronsList:^(NSAttributedString *patrons) {
        self.patronsList = patrons;
    }];
	[self.textField.textStorage setAttributedString:self.appCopyright];
	self.creditsButton.title = NSLocalizedString(@"Credits", @"Caption of the 'Credits' button in the about window");
	self.EULAButton.title = NSLocalizedString(@"License Agreement", @"Caption of the 'License Agreement' button in the about window");
    
    _textField.textColor = self.textColor;
    _versionField.textColor = self.titleColor;
    _nameField.textColor = self.titleColor;
    self.window.backgroundColor = self.backgroundColor;
}

- (BOOL)windowShouldClose:(id)sender{
    return YES;
}

- (void) showCredits:(id)sender {
	if (self.windowState!=1) {
		CGFloat amountToIncreaseHeight = 100;
		NSRect oldFrame = [self.window frame];
		oldFrame.size.height += amountToIncreaseHeight;
		oldFrame.origin.y -= amountToIncreaseHeight;
		[self.window setFrame:oldFrame display:YES animate:NSAnimationLinear];
		self.windowState = 1;
	}
	[self.textField.textStorage setAttributedString:self.appCredits];
    _textField.textColor = self.textColor;
}

- (void) showEULA:(id)sender {
	if (self.windowState!=1) {
		CGFloat amountToIncreaseHeight = 100;
		NSRect oldFrame = [self.window frame];
		oldFrame.size.height += amountToIncreaseHeight;
		oldFrame.origin.y -= amountToIncreaseHeight;
		[self.window setFrame:oldFrame display:YES animate:NSAnimationLinear];
		self.windowState = 1;
	}
	[self.textField.textStorage setAttributedString:self.appEULA];
    _textField.textColor = self.textColor;
}

- (void) showCopyright:(id)sender {
	if (self.windowState!=0) {
		CGFloat amountToIncreaseHeight = -100;
		NSRect oldFrame = [self.window frame];
		oldFrame.size.height += amountToIncreaseHeight;
		oldFrame.origin.y -= amountToIncreaseHeight;
		[self.window setFrame:oldFrame display:YES animate:NSAnimationLinear];
		self.windowState = 0;
	}
	[self.textField.textStorage setAttributedString:self.appCopyright];
    _textField.textColor = self.textColor;
}
    
- (void) showPatrons:(id)sender {
    if (self.windowState!=1) {
        CGFloat amountToIncreaseHeight = 100;
        NSRect oldFrame = [self.window frame];
        oldFrame.size.height += amountToIncreaseHeight;
        oldFrame.origin.y -= amountToIncreaseHeight;
        [self.window setFrame:oldFrame display:YES animate:NSAnimationLinear];
        self.windowState = 1;
    }
    [self.textField.textStorage setAttributedString:self.patronsList];
    _textField.textColor = self.textColor;
}

- (IBAction)visitWebsite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:self.appURL];
}

- (void)showWindow:(id)sender
{
	// make sure the window will be visible and centered
	[NSApp activateIgnoringOtherApps:YES];
	[self.window center];
	[self showCopyright:sender];
    [super showWindow:sender];
}

- (void)generatePatronsList:(void (^)(NSAttributedString *patrons)) completionHandler  {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:@"https://patreonlicensing.malupdaterosx.moe/patronslist.php" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSMutableString *tmpstr = [NSMutableString new];
        [tmpstr appendString:@"<p>Here are the list of Patrons that support the development of our programs:</p><ul>"];
        for (NSDictionary *patron in responseObject) {
            [tmpstr appendFormat:@"<li>%@</li>", patron[@"name"]];
        }
        [tmpstr appendString:@"</ul><p>You can learn more on how to become a Patron on <a href='https://malupdaterosx.moe'>our website</a></p>"];
        completionHandler([tmpstr convertHTMLtoAttStr]);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completionHandler([(@"Unable to load Patrons list") convertHTMLtoAttStr]);
    }];
}
    
#pragma mark - Public Methods

- (id)initWithBackgroundColor:(NSColor*)background titleColor:(NSColor*)title textColor:(NSColor*)text {
    self.windowShouldHaveShadow = YES;
    self.backgroundColor = background;
    self.titleColor = title;
    self.textColor = text;
    return [super initWithWindowNibName:[[self class] nibName]];
}

@end
