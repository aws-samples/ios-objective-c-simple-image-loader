// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#import "SimpleImageLoader.h"
#include <Network/Network.h>

@interface SimpleImageLoader ()
@end

@implementation SimpleImageLoader

static BOOL pathConstrained = NO;
static BOOL pathExpensive = NO;
static NSURLSession *session = nil;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.filename setDelegate:self];
    static nw_path_monitor_t pathmon = nil;
    
    // Set up monitoring of network paths
    if (!pathmon) {
        pathmon = nw_path_monitor_create();
        nw_path_monitor_set_queue(pathmon, dispatch_get_main_queue());
        nw_path_monitor_set_update_handler(pathmon, ^(nw_path_t path) {
            // This code is called when our network path has changed:
            //   just store the value of the flags
            pathExpensive   = nw_path_is_expensive(path);
            pathConstrained = nw_path_is_constrained(path);
            if (session) {
                // Invalidate the current URL session so that
                // when the Fetch button is next pressed, we generate a
                // new session appropriate to the current network path
                [session finishTasksAndInvalidate];
                session = nil;
            }
        });
        nw_path_monitor_start(pathmon);
    }
}

// This is called if the 'go' button is pressed on the keyboard

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self fetchPressed:self.fetch];
    return YES;
}

- (IBAction)fetchPressed:(id)sender {
    NSString *message = [NSString stringWithFormat:@"Fetch %@%@%@",
                         [self.filename text], pathConstrained?@" CONSTRAINED":@"", pathExpensive?@" EXPENSIVE":@""];
    NSURL *url = [NSURL URLWithString:[self.filename text]];

    [self.filename resignFirstResponder];
    [self.output setText:message];

    if (!session) {
        // First time, or network path has changed (e.g. from Wifi to mobile data)
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSDictionary *myHeaders = nil;
        
        // Here we just use the pathConstrained flag to influence our
        // added HTTP request headers; we could do something more complex
        // using both flags
        
        if (pathConstrained) {
            // Add Save-Data: On header
            myHeaders = [NSDictionary dictionaryWithObject:@"on" forKey:@"Save-Data"];
            [config setHTTPAdditionalHeaders:myHeaders];
        }
        session = [NSURLSession sessionWithConfiguration:config];
        NSLog(@"created session with %@", myHeaders?myHeaders:@"standard headers");
    } else {
        NSLog(@"Use existing session, implies no network change since last download");
    }
    
    NSURLSessionTask *task = [session dataTaskWithURL:url
                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // Note we must explicitly call the UI functions on the main queue, this code
        // could be called from a background queue
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data && !error) {
                [self.output setText:[NSString stringWithFormat:@"Success (%0.1f Kb)", (data.length / 1024.0)]];
                [self.image setImage:[UIImage imageWithData:data]];
            } else if (error) {
                [self.output setText:[NSString stringWithFormat:@"Failure with error: %@", error]];
            }
        });
    }];
    [task resume];
}
@end
