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


#import "MainViewController.h"
#import "NSData+Helpers.h"
#import "NSDictionary+Helpers.h"
#import "NSView+Helpers.h"




@implementation MainViewController

@synthesize codeSignIconImageView, entitlementsIconImageView, sandboxingIconImageView, packagingIconImageView, updateBuildPipelineButton, clearBuildPipelineButton;

@synthesize codeSignBox, provisioningProfileAppIdLabel, provisioningProfilePopUpButton, provisioningProfileCertificatePopUpButton, codeSignCheckbox, bundleIdentifierTextField, macAppStoreCategoryPopUpButton, versionNumberTextField, bundleGetInfoTextField, setCustomIconButton, unsetCustomIconButton, customIconImageWell;

@synthesize entitlementsBox, entitlementsCheckbox, entitlementsApplicationIdentifierTextField, iCloudContainerTextField, iCloudKeyValueStoreTextField, entitlementsGameCenterCheckbox, entitlementApsPopUpButton;

@synthesize sandboxingBox, sandboxingCheckbox, sbAllowIncomingNetworkConnectionsCheckbox, sbAllowOutgoingNetworkConnectionsCheckbox, sbAllowCameraAccessCheckbox, sbAllowMicrophoneAccessCheckbox, sbAllowUSBAccessCheckbox, sbAllowPrintingCheckbox, sbAllowAddressBookDataAccessCheckbox, sbAllowLocationServicesAccessCheckbox, sbAllowCalendarDataAccessCheckbox, sbFileSystemAccessPopUpButton, sbMusicFolderAccessPopUpButton, sbMoviesFolderAccessPopUpButton, sbPicturesFolderAccesPopUpButton, sbDownloadsFolderAccessPopUpButton;

@synthesize packagingBox, packagingCheckbox, installerCertificatePopUpButton;

@synthesize projectURL;


////////////////////
// Initialization //
////////////////////

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        macAppStoreCategories = [NSArray arrayWithObjects:
                                 @"public.app-category.business",
                                 @"public.app-category.developer-tools",
                                 @"public.app-category.education",
                                 @"public.app-category.entertainment",
                                 @"public.app-category.finance",
                                 @"public.app-category.games",
                                 @"public.app-category.action-games",
                                 @"public.app-category.adventure-games",
                                 @"public.app-category.arcade-games",
                                 @"public.app-category.board-games",
                                 @"public.app-category.card-games",
                                 @"public.app-category.casino-games",
                                 @"public.app-category.dice-games",
                                 @"public.app-category.educational-games",
                                 @"public.app-category.family-games",
                                 @"public.app-category.kids-games",
                                 @"public.app-category.music-games",
                                 @"public.app-category.puzzle-games",
                                 @"public.app-category.racing-games",
                                 @"public.app-category.role-playing-games",
                                 @"public.app-category.simulation-games",
                                 @"public.app-category.sports-games",
                                 @"public.app-category.strategy-games",
                                 @"public.app-category.trivia-games",
                                 @"public.app-category.word-games",
                                 @"public.app-category.graphics-design",
                                 @"public.app-category.healthcare-fitness",
                                 @"public.app-category.lifestyle",
                                 @"public.app-category.medical",
                                 @"public.app-category.music",
                                 @"public.app-category.news",
                                 @"public.app-category.photography",
                                 @"public.app-category.productivity",
                                 @"public.app-category.reference",
                                 @"public.app-category.social-networking",
                                 @"public.app-category.sports",
                                 @"public.app-category.travel",
                                 @"public.app-category.utilities",
                                 @"public.app-category.video",
                                 @"public.app-category.weather",
                                 nil];
        
        macAppStoreCategoriesFullNames = [NSArray arrayWithObjects:
                                          @"Business",
                                          @"Developer Tools",
                                          @"Education",
                                          @"Entertainment",
                                          @"Finance",
                                          @"Games",
                                          @"Games - Action",
                                          @"Games - Adventure",
                                          @"Games - Arcade",
                                          @"Games - Board",
                                          @"Games - Card",
                                          @"Games - Casino",
                                          @"Games - Dice",
                                          @"Games - Educational",
                                          @"Games - Family",
                                          @"Games - Kids",
                                          @"Games - Music",
                                          @"Games - Puzzle",
                                          @"Games - Racing",
                                          @"Games - Role Playing",
                                          @"Games - Simulation",
                                          @"Games - Sports",
                                          @"Games - Strategy",
                                          @"Games - Trivia",
                                          @"Games - Word",
                                          @"Graphics, Design",
                                          @"Healthcare, Fitness",
                                          @"Lifestyle",
                                          @"Medical",
                                          @"Music",
                                          @"News",
                                          @"Photography",
                                          @"Productivity",
                                          @"Reference",
                                          @"Social Networking",
                                          @"Sports",
                                          @"Travel",
                                          @"Utilities",
                                          @"Video",
                                          @"Weather",
                                          nil];
    }
    
    return self;
}


///////////////////////////
// Unity Project Actions //
///////////////////////////

#pragma mark Unity Project Actions


- (IBAction)updateBuildPipelinePressed:(id)sender {
    // Failsafe
    if (projectURL == nil)
        return;
    
    // Force update text-fields -- if we're still in the text field, update message is not sent so just force update it
    [self bundleIdentifierTextFieldEdited:self.bundleIdentifierTextField];
    [self versionNumberTextFieldEdited:self.versionNumberTextField];
    [self bundleGetInfoTextFieldEdited:self.bundleGetInfoTextField];
    [self entitlementsApplicationIdentifierTextFieldEdited:self.entitlementsApplicationIdentifierTextField];
    [self iCloudKeyValueStoreTextFieldEdited:self.iCloudKeyValueStoreTextField];
    [self iCloudContainerTextFieldEdited:self.iCloudContainerTextField];
    
    // Check bundle identifer
    if (self.codeSignCheckbox.state == NSOnState) {
        if ([bundleIdentifier rangeOfString:@"*"].location != NSNotFound) {
            // Alert and stop
            NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid Bundle Identifier" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Bundle Identifier should not contain wildcard '*' character. Bundle Identifier should be in the form of com.company.name with a pattern matching the one of your provisioning profile."];
            [alert runModal];        
            return;
        } else if ([bundleIdentifier isEqualToString:@""]) {
            // Alert and stop
            NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid Bundle Identifier" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Bundle Identifier should not be empty. Bundle Identifier should be in the form of com.company.name with a pattern matching the one of your provisioning profile."];
            [alert runModal];        
            return;
        }
    }
    
    // Check for wildcard in iCloud identifiers
    if (self.entitlementsCheckbox.state == NSOnState) {
        if (([entitlements objectForKey:@"com.apple.developer.ubiquity-kvstore-identifier"] != nil && ([[entitlements objectForKey:@"com.apple.developer.ubiquity-kvstore-identifier"] rangeOfString:@"*"].location != NSNotFound))
            || ([entitlements objectForKey:@"com.apple.developer.ubiquity-container-identifiers"] != nil && ([[[entitlements objectForKey:@"com.apple.developer.ubiquity-container-identifiers"] objectAtIndex:0] rangeOfString:@"*"].location != NSNotFound))) {
            // Alert and stop
            NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid iCloud Identifiers" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"iCloud identifiers should not contain wildcard '*' character. iCloud identifiers should be in the form of AppID.com.company.name with AppID matching the one of your provisioning profile."];
            [alert runModal];
            return;
        }
    }
    
    // Edit post-process script
    NSError *readError = nil;
    NSMutableString *postProcessScript = [NSMutableString stringWithContentsOfURL:postProcessScriptURL encoding:NSUTF8StringEncoding error:&readError];
    
    // Make sure existing post-process script (if any) is perl
    if (postProcessScript.length > 0 && [postProcessScript rangeOfString:@"#!/usr/bin/perl"].location == NSNotFound) {
        // Alert and stop
        NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid existing post-process script" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"You have an existing post-process which is not using Perl scripting command line language. At the moment, Unity Entitlements Tool only supports Perl scripting."];
        [alert runModal];
        return;
    }
    
    // Update script to with new settings
    [self updatePostProcessScript:postProcessScript codesign:(self.codeSignCheckbox.state == NSOnState) entitlements:(self.entitlementsCheckbox.state == NSOnState) packaging:(self.packagingCheckbox.state == NSOnState)];

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
    [self updatePostProcessScript:postProcessScript codesign:NO entitlements:NO packaging:NO];
    
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
    if (self.codeSignCheckbox.state) {
        [self setEntitlementsBoxActive];
        [self setPackagingBoxActive];
    } else {
        [self setEntitlementsBoxInactive];
        [self setPackagingBoxInactive];
    }
}

- (IBAction)provisioningProfilePicked:(id)sender {
    // Set the provisioning profile using the certificate name
    provisioningCertificate = [[provisioningProfileCertificates objectAtIndex:self.provisioningProfilePopUpButton.indexOfSelectedItem] objectAtIndex:0];
    provisioningProfilePath = [provisioningProfilePaths objectAtIndex:self.provisioningProfilePopUpButton.indexOfSelectedItem];
    
    // Update bundle identifier
    NSString *appId = [provisioningProfileAppIds objectAtIndex:self.provisioningProfilePopUpButton.indexOfSelectedItem];
    
    // Update AppID & cert list
    [self.provisioningProfileAppIdLabel setStringValue:appId];
    [self.provisioningProfileCertificatePopUpButton removeAllItems];
    [self.provisioningProfileCertificatePopUpButton addItemsWithTitles:[provisioningProfileCertificates objectAtIndex:self.provisioningProfilePopUpButton.indexOfSelectedItem]];
}


- (IBAction)provisioningProfileCertificatePicked:(id)sender {
    // Update cert
    provisioningCertificate = [[provisioningProfileCertificates objectAtIndex:self.provisioningProfilePopUpButton.indexOfSelectedItem] objectAtIndex:provisioningProfileCertificatePopUpButton.indexOfSelectedItem];
}

- (IBAction)bundleIdentifierTextFieldEdited:(id)sender {
    // Update bundle identifier
    bundleIdentifier = [self.bundleIdentifierTextField stringValue];
}

- (IBAction)appStoreCategoryPicked:(id)sender {
    // Update app store category
    NSInteger index = self.macAppStoreCategoryPopUpButton.indexOfSelectedItem;
    
    if (index < macAppStoreCategories.count)
        applicationCategory = [macAppStoreCategories objectAtIndex:index];
    else {
        [self.macAppStoreCategoryPopUpButton selectItemAtIndex:0];
        applicationCategory = [macAppStoreCategories objectAtIndex:0];
    }
}

- (IBAction)versionNumberTextFieldEdited:(id)sender {
    // Update version number
    versionNumber = [self.versionNumberTextField stringValue];
}

- (IBAction)bundleGetInfoTextFieldEdited:(id)sender {
    // Update bundle get info
    bundleGetInfo = [self.bundleGetInfoTextField stringValue];
}

- (IBAction)setCustomIconButtonPressed:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    openPanel.delegate = self;
    openPanel.title = @"Pick Custom Icon File";
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"icns"]];
    openPanel.allowsOtherFileTypes = NO;
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            customIconPath = [[[openPanel URLs] lastObject] path];
            [self.customIconImageWell setImage:[[NSImage alloc] initWithContentsOfFile:customIconPath]];
        }
    }];
}

- (IBAction)unsetCustomIconButtonPressed:(id)sender {
    [self.customIconImageWell setImage:nil];
    customIconPath = nil;
}

- (IBAction)customIconWellAction:(id)sender {
    customIconPath = [[(NSImageView *)sender image] name];
}

- (IBAction)customSplashScreenWellAction:(id)sender {
    customSplashScreenPath = [[(NSImageView *)sender image] name];
}

- (IBAction)setCustomSplashScreenButtonPressed:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    openPanel.delegate = self;
    openPanel.title = @"Pick Custom Splash Screen File";
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"tif"]];
    openPanel.allowsOtherFileTypes = NO;
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            customSplashScreenPath = [[[openPanel URLs] lastObject] path];
            [self.customSplashScreenImageWell setImage:[[NSImage alloc] initWithContentsOfFile:customSplashScreenPath]];
        }
    }];
}

- (IBAction)unsetCustomSplashScreenButtonPressed:(id)sender {
    [self.customSplashScreenImageWell setImage:nil];
    customSplashScreenPath = nil;
}

//////////////////////////
// Entitlements Actions //
//////////////////////////

#pragma mark Entitlements Actions

- (IBAction)entitlementsCheckboxPressed:(id)sender {
    if (self.entitlementsCheckbox.state)
        [self setSandboxingBoxActive];
    else {
        [self setSandboxingBoxInactive];

        // No entitlements = no sandboxing
        self.sandboxingCheckbox.state = NSOffState;
    }
    
    // Fake this call to trigger some updates on the sandboxing side
    [self sandboxingCheckboxPressed:self.sandboxingCheckbox];
}

- (IBAction)entitlementsApplicationIdentifierTextFieldEdited:(id)sender {
    if ([[sender stringValue] isEqualToString:@""]) {
        [entitlements removeObjectForKey:@"com.apple.application-identifier"];
    } else {
        [entitlements setObject:[sender stringValue] forKey:@"com.apple.application-identifier"];
    }
}

- (IBAction)iCloudKeyValueStoreTextFieldEdited:(id)sender {
    if ([[sender stringValue] isEqualToString:@""]) {
        [entitlements removeObjectForKey:@"com.apple.developer.ubiquity-kvstore-identifier"];
    } else {
        [entitlements setObject:[sender stringValue] forKey:@"com.apple.developer.ubiquity-kvstore-identifier"];
    }
}

- (IBAction)iCloudContainerTextFieldEdited:(id)sender {
    if ([[sender stringValue] isEqualToString:@""]) {
        [entitlements removeObjectForKey:@"com.apple.developer.ubiquity-container-identifiers"];
    } else {
        [entitlements setObject:[NSArray arrayWithObject:[sender stringValue]] forKey:@"com.apple.developer.ubiquity-container-identifiers"];
    }
}

- (IBAction)entitlementsOptionCheckboxPressed:(id)sender {
    // Just pass any checkbox change to our entitlements dictionary
    
    if (sender == self.entitlementsGameCenterCheckbox) {
        if (self.entitlementsGameCenterCheckbox.state)
            [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.developer.game-center"];
        else
            [entitlements removeObjectForKey:@"com.apple.developer.game-center"];
    }
}

- (IBAction)entitlementsApsEnvironmentPicked:(id)sender {
    // Just pass any pop-up button change to our entitlements dictionary
    
    // Clear first
    [entitlements removeObjectForKey:@"com.apple.developer.aps-environment"];
    
    // Set any new object
    switch (self.entitlementApsPopUpButton.indexOfSelectedItem) {
        case 1:
            [entitlements setObject:@"development" forKey:@"com.apple.developer.aps-environment"];
            break;
        case 2:
            [entitlements setObject:@"production" forKey:@"com.apple.developer.aps-environment"];
            break;
            
        default:
            break;
    }
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
        switch (self.sbMusicFolderAccessPopUpButton.indexOfSelectedItem) {
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
        switch (self.sbMoviesFolderAccessPopUpButton.indexOfSelectedItem) {
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
        switch (self.sbPicturesFolderAccesPopUpButton.indexOfSelectedItem) {
            case 1:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.assets.pictures.read-only"];
                break;
            case 2:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.assets.pictures.read-write"];
                break;
                
            default:
                break;
        }
    } else if (sender == self.sbDownloadsFolderAccessPopUpButton) {
        // Clear first
        [entitlements removeObjectForKey:@"com.apple.security.files.downloads.read-only"];
        [entitlements removeObjectForKey:@"com.apple.security.files.downloads.read-write"];
        
        // Set any new object
        switch (self.sbDownloadsFolderAccessPopUpButton.indexOfSelectedItem) {
            case 1:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.files.downloads.read-only"];
                break;
            case 2:
                [entitlements setObject:[NSNumber numberWithBool:YES] forKey:@"com.apple.security.files.downloads.read-write"];
                break;
                
            default:
                break;
        }
    }
}

- (IBAction)sandboxingOptionCheckboxPressed:(id)sender {
    // Just pass any checkbox change to our entitlements dictionary

    if (sender == self.sbAllowIncomingNetworkConnectionsCheckbox) {
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
            [entitlements removeObjectForKey:@"com.apple.security.personal-information.calendars"];
    }
}


///////////////////////
// Packaging Actions //
///////////////////////

#pragma mark Packaging Actions

- (IBAction)packagingCheckboxPressed:(id)sender {
}

- (IBAction)installerCertificatePicked:(id)sender {
    // Set new cert
    packagingCertificate = [packagingCertificates objectAtIndex:self.installerCertificatePopUpButton.indexOfSelectedItem];
}

////////////////////////////////////////////
// NSOpenSavePanelDelegate Implementation //
////////////////////////////////////////////

#pragma mark NSOpenSavePanelDelegate Implementation

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError {
    if (((NSOpenPanel *)sender).canChooseFiles)
        return YES;
    
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
