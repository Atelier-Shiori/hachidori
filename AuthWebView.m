//
//  AuthWebView.m
//  Shukofukurou
//
//  Created by 小鳥遊六花 on 4/24/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AuthWebView.h"
#import "ClientConstants.h"
#import "PKCEGenerator.h"
#import "Utility.h"

@interface AuthWebView ()
@property (strong) WKWebView *webView;
@end

@implementation AuthWebView
- (void)loadView {
    WKWebViewConfiguration *webConfiguration = [WKWebViewConfiguration new];
    _webView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:webConfiguration];
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    _webView.customUserAgent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1 Safari/605.1.15";
    self.view = _webView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self loadAuthorization:_service];
}

- (NSURL *)authURL {
    NSString *authurl;
    switch (_service) {
        case 1:
            authurl = [NSString stringWithFormat:@"https://anilist.co/api/v2/oauth/authorize?client_id=%@&response_type=code",kanilistclient];
            break;
        case 2:
            _verifier = [PKCEGenerator generateCodeChallenge:[PKCEGenerator createVerifierString]];
            authurl = [NSString stringWithFormat:@"https://myanimelist.net/v1/oauth2/authorize?response_type=code&client_id=%@&redirect_uri=%@&code_challenge=%@&code_challenge_method=plain", kmalclient, [Utility urlEncodeString:@"hachidoriauth://malauth/"], _verifier];
            break;
        default:
            break;
    }
    return [NSURL URLWithString:authurl];
}

- (void)loadAuthorization:(int)nservice {
    _service = nservice;
    [_webView loadRequest:[NSURLRequest requestWithURL:[self authURL]]];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *redirectURL;
    switch (_service) {
        case 1:
            redirectURL = @"hachidoriauth://anilistauth/?code=";
            break;
        case 2:
            redirectURL = @"hachidoriauth://malauth/?code=";
            break;
        default:
            break;
    }
    if ([navigationAction.request.URL.absoluteString containsString:redirectURL]) {
        // Save Pin
        decisionHandler(WKNavigationActionPolicyCancel);
        [self resetWebView];
        _completion([navigationAction.request.URL.absoluteString stringByReplacingOccurrencesOfString:redirectURL withString:@""]);
    }
    else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}


- (void)resetWebView {
    // Clears WebView cookies and cache
    NSSet *websiteDataTypes;
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_12) {
        websiteDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache,WKWebsiteDataTypeOfflineWebApplicationCache,WKWebsiteDataTypeMemoryCache,WKWebsiteDataTypeLocalStorage,WKWebsiteDataTypeCookies,WKWebsiteDataTypeSessionStorage,WKWebsiteDataTypeIndexedDBDatabases, WKWebsiteDataTypeWebSQLDatabases]];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
        }];
    }
    else {
        return;
    }
}



@end
