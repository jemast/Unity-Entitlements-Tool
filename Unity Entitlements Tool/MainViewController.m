/********************************************************************************
 Copyright (c) 2011, jemast software
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


#import "MainViewController.h"
#import "NSData+Helpers.h"
#import "NSDictionary+Helpers.h"
#import "NSView+Helpers.h"




@implementation MainViewController

@synthesize projectNameLabel, projectIconImageView, codeSignIconImageView, entitlementsIconImageView, sandboxingIconImageView, pickProjectDirectoryButton, updateBuildPipelineButton, clearBuildPipelineButton;

@synthesize codeSignBox, provisioningProfileAppIdLabel, provisioningProfileCertificateLabel, provisioningProfilePopUpButton, codeSignCheckbox;

@synthesize entitlementsBox, entitlementsCheckbox, iCloudContainerTextField, iCloudKeyValueStoreTextField;

@synthesize sandboxingBox, sandboxingCheckbox, sbAllowDownloadsFolderAccessCheckbox, sbAllowIncomingNetworkConnectionsCheckbox, sbAllowOutgoingNetworkConnectionsCheckbox, sbAllowCameraAccessCheckbox, sbAllowMicrophoneAccessCheckbox, sbAllowUSBAccessCheckbox, sbAllowPrintingCheckbox, sbAllowAddressBookDataAccessCheckbox, sbAllowLocationServicesAccessCheckbox, sbAllowCalendarDataAccessCheckbox, sbFileSystemAccessPopUpButton, sbMusicFolderAccessPopUpButton, sbMoviesFolderAccessPopUpButton, sbPicturesFolderAccesPopUpButton;


///////////////////////////
// Unity Project Actions //
///////////////////////////

#pragma mark Unity Project Actions

- (IBAction)pickProjectDirectoryPressed:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.delegate = self;
    openPanel.title = @"Pick Project Directory";
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            // This block will allow easy early returns for errors opening project
            void (^couldNotOpenProject)(NSError *) = ^(NSError *error) {
                // Invalid folder, alert and prevent open panel validation
                NSAlert *alert = [NSAlert alertWithMessageText:@"Could Not Open Project" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:(error ? error.localizedDescription : @"Undefined error.")];
                [alert runModal];
                
                // Reset
                [self reset];
            };
            
            // Reset
            [self reset];

            // Save project URL
            projectURL = [[openPanel URLs] lastObject];
            
            // Update project name
            [self.projectNameLabel setStringValue:[[projectURL pathComponents] lastObject]];
            
            // Attempt to import project build pipeline
            NSError *importError = nil;
            if (![self importProjectBuildPipeline:&importError]) {
                couldNotOpenProject(importError);
                return;
            }
            
            // Update provisioning profile list
            NSError *profileError = nil;
            if (![self updateProvisioningProfileList:&profileError]) {
                couldNotOpenProject(profileError);
                return;
            }
            
            // Enable pipeline update & clear buttons
            [self.updateBuildPipelineButton setEnabled:YES];
            [self.clearBuildPipelineButton setEnabled:YES];
            
            // Sync UI with loaded entitlements
            [self syncUIWithEntitlements];
        }
    }];
}

- (IBAction)updateBuildPipelinePressed:(id)sender {
    // Failsafe
    if (projectURL == nil)
        return;
    
    // Force update text-fields -- if we're still in the text field, update message is not sent so just force update it
    [self iCloudKeyValueStoreTextFieldEdited:self.iCloudKeyValueStoreTextField];
    [self iCloudContainerTextFieldEdited:self.iCloudContainerTextField];
    
    // Check for wildcard in iCloud identifiers
    if (([[entitlements objectForKey:@"com.apple.developer.ubiquity-kvstore-identifier"] rangeOfString:@"*"].location != NSNotFound)
        || ([[[entitlements objectForKey:@"com.apple.developer.ubiquity-container-identifiers"] objectAtIndex:0] rangeOfString:@"*"].location != NSNotFound)) {
        // Alert and stop
        NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid iCloud Identifiers" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"iCloud identifiers should not contain wildcard '*' character. iCloud identifiers should be in the form of AppID.com.company.name with AppID matching the one of your provisioning profile."];
        [alert runModal];        
        return;
    }
    
    // Edit post-process script
    NSError *readError = nil;
    NSMutableString *postProcessScript = [NSMutableString stringWithContentsOfURL:postProcessScriptURL encoding:NSUTF8StringEncoding error:&readError];
        
    // Update script to with new settings
    [self updatePostProcessScript:postProcessScript codesign:(self.codeSignCheckbox.state == NSOnState) entitlements:(self.entitlementsCheckbox.state == NSOnState)];

    // Save post-process script
    NSError *writeError = nil;
    [postProcessScript writeToURL:postProcessScriptURL atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    
    // Save entitlements
    [[entitlements xmlData] writeToURL:entitlementsURL atomically:YES];
    
    // Update project status
    [self updateProjectStatus];
}

- (IBAction)clearBuildPipelinePressed:(id)sender {
    // Failsafe
    if (projectURL == nil)
        return;
    
    // Edit post-process script
    NSError *readError = nil;
    NSMutableString *postProcessScript = [NSMutableString stringWithContentsOfURL:postProcessScriptURL encoding:NSUTF8StringEncoding error:&readError];
    
    // Update script to clear pipeline
    [self updatePostProcessScript:postProcessScript codesign:NO entitlements:NO];
    
    // Save post-process script
    NSError *writeError = nil;
    [postProcessScript writeToURL:postProcessScriptURL atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    
    // Clear entitlements
    [entitlements removeAllObjects];
    
    // Save entitlements
    [[entitlements xmlData] writeToURL:entitlementsURL atomically:YES];
    
    // Sync UI
    [self syncUIWithEntitlements];
    
    // Update project status
    [self updateProjectStatus];
}


//////////////////////
// Codesign Actions //
//////////////////////

#pragma mark Codesign Actions

- (IBAction)codeSignCheckboxPressed:(id)sender {
    if (self.codeSignCheckbox.state)
        [self setEntitlementsBoxActive];
    else
        [self setEntitlementsBoxInactive];
}

- (IBAction)provisioningProfilePicked:(id)sender {
    // Set the provisioning profile using the certificate name
    provisioningProfile = [provisioningProfileCertificates objectAtIndex:self.provisioningProfilePopUpButton.indexOfSelectedItem];
    
    // Update iCloud key-value store text field
    [self.iCloudKeyValueStoreTextField setStringValue:[provisioningProfileAppIds objectAtIndex:self.provisioningProfilePopUpButton.indexOfSelectedItem]];

    // Update iCloud container text field
    [self.iCloudContainerTextField setStringValue:[provisioningProfileAppIds objectAtIndex:self.provisioningProfilePopUpButton.indexOfSelectedItem]];
}


//////////////////////////
// Entitlements Actions //
//////////////////////////

#pragma mark Entitlements Actions

- (IBAction)entitlementsCheckboxPressed:(id)sender {
    if (self.entitlementsCheckbox.state)
        [self setSandboxingBoxActive];
    else
        [self setSandboxingBoxInactive];
}

- (IBAction)iCloudKeyValueStoreTextFieldEdited:(id)sender {
    [entitlements setObject:[sender stringValue] forKey:@"com.apple.application-identifier"];
    [entitlements setObject:[sender stringValue] forKey:@"com.apple.developer.ubiquity-kvstore-identifier"];
}

- (IBAction)iCloudContainerTextFieldEdited:(id)sender {
    [entitlements setObject:[NSArray arrayWithObject:[sender stringValue]] forKey:@"com.apple.developer.ubiquity-container-identifiers"];
}


////////////////////////
// Sandboxing Actions //
////////////////////////

#pragma mark Sandboxing Actions

- (IBAction)sandboxingCheckboxPressed:(id)sender {
    if (self.sandboxingCheckbox.state)
        [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.app-sandbox"];
    else
        [entitlements removeObjectForKey:@"com.apple.security.app-sandbox"];
}

- (IBAction)sandboxingPopUpButtonPicked:(id)sender {
    // Just pass any pop-up button change to our entitlements dictionary
    
    if (sender == self.sbFileSystemAccessPopUpButton) {
        // Clear first
        [entitlements removeObjectForKey:@"com.apple.security.files.user-selected.read-only"];
        [entitlements removeObjectForKey:@"com.apple.security.files.user-selected.read-write"];

        // Set any new object
        switch (self.sbFileSystemAccessPopUpButton.indexOfSelectedItem) {
            case 1:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.files.user-selected.read-only"];
                break;
            case 2:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.files.user-selected.read-write"];
                break;
                
            default:
                break;
        }
    } else if (sender == self.sbMusicFolderAccessPopUpButton) {
        // Clear first
        [entitlements removeObjectForKey:@"com.apple.security.assets.music.read-only"];
        [entitlements removeObjectForKey:@"com.apple.security.assets.music.read-write"];
        
        // Set any new object
        switch (self.sbFileSystemAccessPopUpButton.indexOfSelectedItem) {
            case 1:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.assets.music.read-only"];
                break;
            case 2:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.assets.music.read-write"];
                break;
                
            default:
                break;
        }
    } else if (sender == self.sbMoviesFolderAccessPopUpButton) {
        // Clear first
        [entitlements removeObjectForKey:@"com.apple.security.assets.movies.read-only"];
        [entitlements removeObjectForKey:@"com.apple.security.assets.movies.read-write"];
        
        // Set any new object
        switch (self.sbFileSystemAccessPopUpButton.indexOfSelectedItem) {
            case 1:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.assets.movies.read-only"];
                break;
            case 2:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.assets.movies.read-write"];
                break;
                
            default:
                break;
        }
    } else if (sender == self.sbPicturesFolderAccesPopUpButton) {
        // Clear first
        [entitlements removeObjectForKey:@"com.apple.security.assets.pictures.read-only"];
        [entitlements removeObjectForKey:@"com.apple.security.assets.pictures.read-write"];
        
        // Set any new object
        switch (self.sbFileSystemAccessPopUpButton.indexOfSelectedItem) {
            case 1:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.assets.pictures.read-only"];
                break;
            case 2:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.assets.pictures.read-write"];
                break;
                
            default:
                break;
        }
    }
}

- (IBAction)sandboxingOptionCheckboxPressed:(id)sender {
    // Just pass any checkbox change to our entitlements dictionary

    if (sender == self.sbAllowDownloadsFolderAccessCheckbox) {
        if (self.sbAllowDownloadsFolderAccessCheckbox.state)
            [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.files.downloads.read-write"];
        else
            [entitlements removeObjectForKey:@"com.apple.security.files.downloads.read-write"];
    } else if (sender == self.sbAllowIncomingNetworkConnectionsCheckbox) {
        if (self.sbAllowIncomingNetworkConnectionsCheckbox.state)
            [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.network.server"];
        else
            [entitlements removeObjectForKey:@"com.apple.security.network.server"];
    } else if (sender == self.sbAllowOutgoingNetworkConnectionsCheckbox) {
        if (self.sbAllowOutgoingNetworkConnectionsCheckbox.state)
            [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.network.client"];
        else
            [entitlements removeObjectForKey:@"com.apple.security.network.client"];
    } else if (sender == self.sbAllowCameraAccessCheckbox) {
        if (self.sbAllowCameraAccessCheckbox.state)
            [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.device.camera"];
        else
            [entitlements removeObjectForKey:@"com.apple.security.device.camera"];
    } else if (sender == self.sbAllowMicrophoneAccessCheckbox) {
        if (self.sbAllowMicrophoneAccessCheckbox.state)
            [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.device.microphone"];
        else
            [entitlements removeObjectForKey:@"com.apple.security.device.microphone"];
    } else if (sender == self.sbAllowUSBAccessCheckbox) {
        if (self.sbAllowUSBAccessCheckbox.state)
            [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.device.usb"];
        else
            [entitlements removeObjectForKey:@"com.apple.security.device.usb"];
    } else if (sender == self.sbAllowPrintingCheckbox) {
        if (self.sbAllowPrintingCheckbox.state)
            [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.print"];
        else
            [entitlements removeObjectForKey:@"com.apple.security.print"];
    } else if (sender == self.sbAllowAddressBookDataAccessCheckbox) {
        if (self.sbAllowAddressBookDataAccessCheckbox.state)
            [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.personal-information.addressbook"];
        else
            [entitlements removeObjectForKey:@"com.apple.security.personal-information.addressbook"];
    } else if (sender == self.sbAllowLocationServicesAccessCheckbox) {
        if (self.sbAllowLocationServicesAccessCheckbox.state)
            [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.personal-information.location"];
        else
            [entitlements removeObjectForKey:@"com.apple.security.personal-information.location"];
    } else if (sender == self.sbAllowCalendarDataAccessCheckbox) {
        if (self.sbAllowCalendarDataAccessCheckbox.state)
            [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.personal-information.calendars"];
        else
            [entitlements removeObjectForKey:@"com.apple.security.personal-information.calendar"];
    }
}


////////////////////////////////////////////
// NSOpenSavePanelDelegate Implementation //
////////////////////////////////////////////

#pragma mark NSOpenSavePanelDelegate Implementation

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError {
    // This block will allow easy early returns for invalid directories
    BOOL (^presentInvalidPanel)() = ^(void) {
        // Invalid folder, alert and prevent open panel validation
        NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid Directory" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"This directory is not a valid Unity project directory."];
        [alert runModal];
        return NO;
    };
    
    // Check we're dealing with a valid Unity project folder
    BOOL isDirectory;
    
    // Check we have an item at Assets path
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[url URLByAppendingPathComponent:@"Assets" isDirectory:YES] path] isDirectory:&isDirectory])
        return presentInvalidPanel();
    
    // Check Assets is a folder
    if (!isDirectory)
        return presentInvalidPanel();
    
    // Check we have an item at Library path
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[url URLByAppendingPathComponent:@"Library" isDirectory:YES] path] isDirectory:&isDirectory])
        return presentInvalidPanel();
    
    // Check Library is a folder
    if (!isDirectory)
        return presentInvalidPanel();
    
    // Check we have ProjectSettings.asset file in Library folder
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[url URLByAppendingPathComponent:@"Library/ProjectSettings.asset" isDirectory:NO] path] isDirectory:&isDirectory])
        return presentInvalidPanel();
    
    // Check ProjectSettings.asset is a file
    if (isDirectory)
        return presentInvalidPanel();
    
    // This directory is valid
    return YES;
}


@end
