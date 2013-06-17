/********************************************************************************
 Copyright (c) 2011-2013, jemast software
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the <organization> nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
********************************************************************************/


#import "AppDelegate.h"
#import "MainViewController.h"

@implementation AppDelegate

@synthesize window = _window, controller = _controller;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Open project immediately
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.delegate = self;
    openPanel.title = @"Pick your Unity project directory";
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            // This block will allow easy early returns for errors opening project
            void (^couldNotOpenProject)(NSError *) = ^(NSError *error) {
                // Invalid folder, alert and prevent open panel validation
                NSAlert *alert = [NSAlert alertWithMessageText:@"Could Not Open Project" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Error : %@", (error ? error.localizedDescription : @"Undefined error.")];
                [alert runModal];
                
                // Reset
                [self.controller reset];
            };
            
            // Reset
            [self.controller reset];
            
            // Save project URL
            self.controller.projectURL = [[openPanel URLs] lastObject];
            
            // Update window title
            self.window.title = [NSString stringWithFormat:@"Unity Entitlements Tool - %@", [[self.controller.projectURL pathComponents] lastObject]];
            
            // Attempt to import project build pipeline
            NSError *importError = nil;
            if (![self.controller importProjectBuildPipeline:&importError]) {
                couldNotOpenProject(importError);
                return;
            }
            
            // Update provisioning profile list
            NSError *profileError = nil;
            if (![self.controller updateProvisioningProfileList:&profileError]) {
                couldNotOpenProject(profileError);
                return;
            }
            
            // Update installer profile list
            if (![self.controller updateInstallerProfileList:&profileError]) {
                couldNotOpenProject(profileError);
                return;
            }
            
            // Enable pipeline update & clear buttons
            [self.controller.updateBuildPipelineButton setEnabled:YES];
            [self.controller.clearBuildPipelineButton setEnabled:YES];
            
            // Sync UI with loaded entitlements
            [self.controller syncUIWithEntitlements];
            
            // Show window
            [self.window makeKeyAndOrderFront:self];
        }
    }];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}


@end
