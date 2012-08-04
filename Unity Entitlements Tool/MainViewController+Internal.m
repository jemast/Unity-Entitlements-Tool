/********************************************************************************
 Copyright (c) 2011-2012, jemast software
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


@implementation MainViewController (Internal)


//////////////////////
// Internal Methods //
//////////////////////

#pragma mark Internal Methods

- (BOOL)importProjectBuildPipeline:(NSError *__autoreleasing *)error {
    // Check we have Editor directory
    BOOL isDirectory;
    NSURL *editorURL = [projectURL URLByAppendingPathComponent:@"Assets/Editor" isDirectory:YES];
    if (![[NSFileManager defaultManager] fileExistsAtPath:editorURL.path isDirectory:&isDirectory]) {
        NSError *createDirectoryError = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtURL:editorURL withIntermediateDirectories:NO attributes:nil error:&createDirectoryError]) {
            if (createDirectoryError) {
                if (error != nil)
                    *error = createDirectoryError;
                
                return NO;
            }
        }
    } else {
        // This should be a directory, we can't continue opening this project
        if (!isDirectory) {
            NSError *editorIsFileError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Editor asset already exists as a file. It should be a folder." forKey:NSLocalizedDescriptionKey]];
            if (error != nil)
                *error = editorIsFileError;
            
            return NO;
        }
    }
    
    // We're sure that Editor directory exists, check if we have a post-process script
    postProcessScriptURL = [projectURL URLByAppendingPathComponent:@"Assets/Editor/PostprocessBuildPlayer" isDirectory:NO];
    if (![[NSFileManager defaultManager] fileExistsAtPath:postProcessScriptURL.path isDirectory:&isDirectory]) {
        NSError *writeError = nil;
        if (![@"#!/usr/bin/perl" writeToURL:postProcessScriptURL atomically:YES encoding:NSUTF8StringEncoding error:&writeError]) {
            if (error != nil)
                *error = writeError;

            return NO;
        }
    } else {
        // It shouldn't be a directory, we can't continue opening this project
        if (isDirectory) {
            NSError *postProcessScriptIsDirectoryError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"PostprocessBuildPlayer asset already exists as a folder. It should be a file." forKey:NSLocalizedDescriptionKey]];
            if (error != nil)
                *error = postProcessScriptIsDirectoryError;
            
            return NO;
        }
        
        // Check if we have some provisioning profile set in our script
        NSError *scriptReadError = nil;
        NSString *scriptString = [NSString stringWithContentsOfURL:postProcessScriptURL encoding:NSUTF8StringEncoding error:&scriptReadError];
        if (scriptReadError != nil) {
            if (error != nil)
                *error = scriptReadError;
            
            return NO;
        }
        
        // Narrow down to our entitlements
        bool hasPreviousSettings = NO;
        NSRange beginRange = [scriptString rangeOfString:@"\n\n\n#BEGIN APPLY ENTITLEMENTS"];
        if (beginRange.location == NSNotFound)
            beginRange = [scriptString rangeOfString:@"#BEGIN APPLY ENTITLEMENTS"];
        
        if (beginRange.location != NSNotFound) {
            NSRange endRange = [scriptString rangeOfString:@"#END APPLY ENTITLEMENTS\n\n"];
            if (endRange.location == NSNotFound)
                endRange = [scriptString rangeOfString:@"#END APPLY ENTITLEMENTS"];
            
            if (endRange.location != NSNotFound) {
                scriptString = [scriptString substringWithRange:NSMakeRange(beginRange.location, endRange.location + endRange.length - beginRange.location)];
                hasPreviousSettings = YES;
            }
        }
        
        if (hasPreviousSettings) {
            // Attempt to retrieve profile path
            NSRegularExpression *profileRegex = [NSRegularExpression regularExpressionWithPattern:@"system\\(\\\"cp \\\\\\\".*?\\\\\\\" \\\\\\\"\\$EntitlementsPublishFile\\/Contents\\/embedded\\.provisionprofile\\\\\\\"\\\"\\);" options:0 error:nil];
            NSRange profileBeginRange = [profileRegex rangeOfFirstMatchInString:scriptString options:0 range:NSMakeRange(0, scriptString.length)];
            if (profileBeginRange.location != NSNotFound) {
                NSString *scriptSubstring = [scriptString substringFromIndex:(profileBeginRange.location + 13)];
                NSRange profileEndRange = [scriptSubstring rangeOfString:@"\\\""];
                if (profileEndRange.location != NSNotFound) {
                    postProcessScriptHasCodesign = YES;
                    provisioningProfilePath = [scriptSubstring substringToIndex:profileEndRange.location];
                }
            }
            
            // Attempt to retrieve bundle identifier
            NSRange bundleIdBeginRange = [scriptString rangeOfString:@"\\\"CFBundleIdentifier\\\" -string \\\""];
            if (bundleIdBeginRange.location != NSNotFound) {
                NSString *scriptSubstring = [scriptString substringFromIndex:(bundleIdBeginRange.location + bundleIdBeginRange.length)];
                NSRange bundleIdEndRange = [scriptSubstring rangeOfString:@"\\\""];
                if (bundleIdEndRange.location != NSNotFound) {
                    bundleIdentifier = [scriptSubstring substringToIndex:bundleIdEndRange.location];
                }
            }
            
            // Attempt to retrieve Mac App Store category
            NSRange masCategoryBeginRange = [scriptString rangeOfString:@"\\\"LSApplicationCategoryType\\\" -string \\\""];
            if (masCategoryBeginRange.location != NSNotFound) {
                NSString *scriptSubstring = [scriptString substringFromIndex:(masCategoryBeginRange.location + masCategoryBeginRange.length)];
                NSRange masCategoryEndRange = [scriptSubstring rangeOfString:@"\\\""];
                if (masCategoryEndRange.location != NSNotFound) {
                    applicationCategory = [scriptSubstring substringToIndex:masCategoryEndRange.location];
                }
            }
            
            // Attempt to retrieve version number
            NSRange versionNumberBeginRange = [scriptString rangeOfString:@"\\\"CFBundleVersion\\\" -string \\\""];
            if (versionNumberBeginRange.location != NSNotFound) {
                NSString *scriptSubstring = [scriptString substringFromIndex:(versionNumberBeginRange.location + versionNumberBeginRange.length)];
                NSRange versionNumberEndRange = [scriptSubstring rangeOfString:@"\\\""];
                if (versionNumberEndRange.location != NSNotFound) {
                    versionNumber = [scriptSubstring substringToIndex:versionNumberEndRange.location];
                }
            }
            
            // Attempt to retrieve bundle getinfo
            NSRange bundleGetInfoBeginRange = [scriptString rangeOfString:@"\\\"CFBundleGetInfoString\\\" -string \\\""];
            if (bundleGetInfoBeginRange.location != NSNotFound) {
                NSString *scriptSubstring = [scriptString substringFromIndex:(bundleGetInfoBeginRange.location + bundleGetInfoBeginRange.length)];
                NSRange bundleGetInfoEndRange = [scriptSubstring rangeOfString:@"\\\""];
                if (bundleGetInfoEndRange.location != NSNotFound) {
                    bundleGetInfo = [scriptSubstring substringToIndex:bundleGetInfoEndRange.location];
                }
            }
            
            // Attempt to retrieve custom icon
            NSRegularExpression *customIconRegex = [NSRegularExpression regularExpressionWithPattern:@"system\\(\\\"cp \\\\\\\".*?\\\\\\\" \\\\\\\"\\$EntitlementsPublishFile\\/Contents\\/Resources\\/UnityPlayer\\.icns\\\\\\\"\\\"\\);" options:0 error:nil];
            NSRange customIconBeginRange = [customIconRegex rangeOfFirstMatchInString:scriptString options:0 range:NSMakeRange(0, scriptString.length)];
            if (customIconBeginRange.location != NSNotFound) {
                NSString *scriptSubstring = [scriptString substringFromIndex:(customIconBeginRange.location + 13)];
                NSRange customIconEndRange = [scriptSubstring rangeOfString:@"\\\""];
                if (customIconEndRange.location != NSNotFound) {
                   customIconPath = [scriptSubstring substringToIndex:customIconEndRange.location];
                }
            }

            
            // Attempt to retrieve certificate signature
            NSRange codeSignBeginRange = [scriptString rangeOfString:@"/usr/bin/codesign --force --sign \\\""];
            if (codeSignBeginRange.location != NSNotFound) {
                NSString *scriptSubstring = [scriptString substringFromIndex:(codeSignBeginRange.location + codeSignBeginRange.length)];
                NSRange codeSignEndRange = [scriptSubstring rangeOfString:@"\\\""];
                if (codeSignEndRange.location != NSNotFound) {
                    postProcessScriptHasCodesign = YES;
                    provisioningCertificate = [scriptSubstring substringToIndex:codeSignEndRange.location];
                }
            }
            
            // Attempt to retrieve packaging
            NSRange packagingBeginRange = [scriptString rangeOfString:@"/usr/bin/productbuild --component \\\"$EntitlementsPublishFile\\\" /Applications --sign \\\""];
            if (packagingBeginRange.location != NSNotFound) {
                NSString *scriptSubstring = [scriptString substringFromIndex:(packagingBeginRange.location + packagingBeginRange.length)];
                NSRange packagingEndRange = [scriptSubstring rangeOfString:@"\\\""];
                if (packagingEndRange.location != NSNotFound) {
                    postProcessScriptHasPackaging = YES;
                    packagingCertificate = [scriptSubstring substringToIndex:packagingEndRange.location];
                }
            }
        }
    }
    
    // We're sure that Editor directory exists, check if we have an entitlements file
    entitlementsURL = [projectURL URLByAppendingPathComponent:@"Assets/Editor/entitlements.entitlements" isDirectory:NO];
    if (![[NSFileManager defaultManager] fileExistsAtPath:postProcessScriptURL.path isDirectory:&isDirectory]) {
        // No entitlements, make a new one
        entitlements = [NSMutableDictionary dictionary];
        
        // Write to file
        if (![[entitlements xmlData] writeToURL:entitlementsURL atomically:YES]) {
            NSError *couldNotCreateEntitlementsError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Entitlements file could not be created." forKey:NSLocalizedDescriptionKey]];
            if (error != nil)
                *error = couldNotCreateEntitlementsError;
            
            return NO;
        }
    } else {
        // It shouldn't be a directory, we can't continue opening this project
        if (isDirectory) {
            NSError *entitlementsIsDirectoryError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"entitlements.entitlements asset already exists as a folder. It should be a file." forKey:NSLocalizedDescriptionKey]];
            if (error != nil)
                *error = entitlementsIsDirectoryError;
            
            return NO;
        }
        
        // Attempt to load entitlements or make a new one
        entitlements = [NSMutableDictionary dictionaryWithXMLData:[NSData dataWithContentsOfURL:entitlementsURL]];
        if (entitlements == nil)
            entitlements = [NSMutableDictionary dictionary];
    }
    
    return YES;
}

- (BOOL)updateProvisioningProfileList:(NSError *__autoreleasing *)error {
    // Make sure our arrays are ready and empty
    if (provisioningProfilePaths == nil)
        provisioningProfilePaths = [NSMutableArray array];
    else
        [provisioningProfilePaths removeAllObjects];
    
    if (provisioningProfileNames == nil)
        provisioningProfileNames = [NSMutableArray array];
    else
        [provisioningProfileNames removeAllObjects];
    
    if (provisioningProfileAppIds == nil)
        provisioningProfileAppIds = [NSMutableArray array];
    else
        [provisioningProfileAppIds removeAllObjects];
    
    if (provisioningProfileCertificates == nil)
        provisioningProfileCertificates = [NSMutableArray array];
    else
        [provisioningProfileCertificates removeAllObjects];
    
    // Get provisioning profiles URL
    NSURL *libraryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    NSURL *profilesURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/MobileDevice/Provisioning Profiles", libraryURL.path] isDirectory:YES];
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:profilesURL.path isDirectory:&isDirectory]) {
        NSError *profileError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Could not open or locate any valid provisioning profile." forKey:NSLocalizedDescriptionKey]];
        if (error != nil)
            *error = profileError;

        return NO;
    }
    
    if (!isDirectory) {
        NSError *profileError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Could not open or locate any valid provisioning profile." forKey:NSLocalizedDescriptionKey]];
        if (error != nil)
            *error = profileError;
        
        return NO;
    }
    
    // List provisioning profiles
    NSError *fetchContentsError = nil;
    NSArray *profiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:profilesURL includingPropertiesForKeys:[NSArray arrayWithObject:NSURLTypeIdentifierKey] options:0 error:&fetchContentsError];
    if (fetchContentsError != nil) {
        NSError *profileError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Could not open or locate any valid provisioning profile." forKey:NSLocalizedDescriptionKey]];
        if (error != nil)
            *error = profileError;
        
        return NO;
    }
    
    if ((profiles == nil) || (profiles.count == 0)) {
        NSError *profileError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Could not open or locate any valid provisioning profile." forKey:NSLocalizedDescriptionKey]];
        if (error != nil)
            *error = profileError;
        
        return NO;
    }
    
    for (NSURL *url in profiles) {
        if (![url.pathExtension isEqualToString:@"provisionprofile"])
            continue;
        
        // Provisioning Profiles are CMS signed xml plists, we need to get their content first
        NSData *signedProfileData = [NSData dataWithContentsOfURL:url];
        
        CMSDecoderRef cmsDecoder;
        CMSDecoderCreate(&cmsDecoder);
        if (cmsDecoder == nil)
            continue;
        
        CMSDecoderUpdateMessage(cmsDecoder, signedProfileData.bytes, signedProfileData.length);
        CMSDecoderFinalizeMessage(cmsDecoder);
        
        CFDataRef profileDataRef;
        CMSDecoderCopyContent(cmsDecoder, &profileDataRef);
        CFRelease(cmsDecoder);
        
        if (profileDataRef == nil)
            continue;
        
        // We have the profile data, read it as an XML dictionary
        NSDictionary *profileDictionary = [NSDictionary dictionaryWithXMLData:(__bridge_transfer NSData *)profileDataRef];
        
        // Make sure this profile has Name string
        NSString *profileName = [profileDictionary objectForKey:@"Name"];
        if ((profileName == nil) || (![profileName isKindOfClass:[NSString class]]))
            continue;
        
        // Make sure this profile has Entitlements dictionary
        NSDictionary *profileEntitlementsDictionary = [profileDictionary objectForKey:@"Entitlements"];
        if ((profileEntitlementsDictionary == nil) || (![profileEntitlementsDictionary isKindOfClass:[NSDictionary class]]))
            continue;
        
        // Make sure this profile has com.apple.application-identifier string in its entitlements dictionary
        NSString *profileAppId = [profileEntitlementsDictionary objectForKey:@"com.apple.application-identifier"];
        if ((profileAppId == nil) || (![profileAppId isKindOfClass:[NSString class]]))
            continue;
        
        // Make sure this profile has certificate data
        NSData *certData = [[profileDictionary objectForKey:@"DeveloperCertificates"] objectAtIndex:0];
        if ((certData == nil) || (![certData isKindOfClass:[NSData class]]))
            continue;
        
        SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
        CFStringRef certificateNameRef;
        SecCertificateCopyCommonName(certificate, &certificateNameRef);
        CFRelease(certificate);
        
        if (certificateNameRef == nil)
            continue;
        
        //////////////////////////////////////////////////////////////////
        // That's a valid certificate, we can add it to our lists
        
        [provisioningProfilePaths addObject:url.path];
        [provisioningProfileNames addObject:profileName];
        [provisioningProfileAppIds addObject:profileAppId];
        [provisioningProfileCertificates addObject:(__bridge_transfer NSString *)certificateNameRef];
    }

    // Look for Developer ID certificates (they are not tied to a profile)
    // Search certificates
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           kSecClassCertificate, kSecClass,
                           kCFBooleanTrue, kSecReturnRef,
                           kSecMatchLimitAll, kSecMatchLimit,
                           kCFBooleanTrue, kSecAttrCanSign,
                           nil];
    
    CFTypeRef attributes;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&attributes);
    NSArray *items = (__bridge_transfer NSArray *)attributes;
    
    // Make sure we succeeded in fetching certs
    if (status) {
        if (error != nil)
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Can't search keychain." forKey:NSLocalizedDescriptionKey]];
        
        return NO;
    }
    
    // Filter out Mac Dev certificates
    for (id object in items) {
        CFStringRef certificateNameRef;
        OSStatus result = SecCertificateCopyCommonName((__bridge SecCertificateRef)object, &certificateNameRef);
        
        // Make sure we did get that name
        if ((result == 0) && (certificateNameRef != nil)) {
            NSString *certName = (__bridge_transfer NSString *)certificateNameRef;
            if (certName != nil) {
                if ([certName isKindOfClass:[NSString class]]) {
                    // Simple check to test if this is a valid Mac dev certificate
                    if ([certName hasPrefix:@"Developer ID Installer"] || [certName hasPrefix:@"Developer ID Application"]) {
                        [provisioningProfilePaths addObject:@""];
                        [provisioningProfileNames addObject:certName];
                        [provisioningProfileAppIds addObject:@""];
                        [provisioningProfileCertificates addObject:certName];
                    }
                }
            }
        }
    }
    
    // No profile ? No need to open anything...
    if (provisioningProfileNames.count == 0) {
        /*NSAlert *alertView = [NSAlert alertWithMessageText:@"Provisioning Profile Error" defaultButton:@"Locate Profile" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Could not open or locate any valid provisioning profile."];
        NSInteger alertReturnValue = [alertView runModal];
        
        // Do we want to locate a profile?
        if (alertReturnValue == 1) {
            NSOpenPanel *openPanel = [NSOpenPanel openPanel];
            [openPanel setCanChooseFiles:YES];
            [openPanel setCanChooseDirectories:NO];
            [openPanel setAllowsMultipleSelection:NO];
        }*/
        
        NSError *profileError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Cannot open project if no provisioning profile is available." forKey:NSLocalizedDescriptionKey]];
        if (error != nil)
            *error = profileError;
        
        return NO;
    }
    
    // Update list
    [self.provisioningProfilePopUpButton removeAllItems];
    [self.provisioningProfilePopUpButton addItemsWithTitles:provisioningProfileNames];
    [self.provisioningProfileAppIdLabel setStringValue:[provisioningProfileAppIds objectAtIndex:0]];
    [self.provisioningProfileCertificateLabel setStringValue:[provisioningProfileCertificates objectAtIndex:0]];
    
    return YES;
}

- (BOOL)updateInstallerProfileList:(NSError *__autoreleasing *)error {
    // Make sure our arrays are ready and empty
    if (packagingCertificates == nil)
        packagingCertificates = [NSMutableArray array];
    else
        [packagingCertificates removeAllObjects];
    
    // Clear list
    [self.installerCertificatePopUpButton removeAllItems];
    
    // Search certificates
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           kSecClassCertificate, kSecClass,
                           kCFBooleanTrue, kSecReturnRef,
                           kSecMatchLimitAll, kSecMatchLimit,
                           kCFBooleanTrue, kSecAttrCanSign,
                           nil];
    
    CFTypeRef attributes;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&attributes);
    NSArray *items = (__bridge_transfer NSArray *)attributes;
    
    // Make sure we succeeded in fetching certs
    if (status) {
        if (error != nil)
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Can't search keychain." forKey:NSLocalizedDescriptionKey]];
        
        return NO;
    }
    
    // Filter out Mac Dev certificates
    for (id object in items) {
        CFStringRef certificateNameRef;
        OSStatus result = SecCertificateCopyCommonName((__bridge SecCertificateRef)object, &certificateNameRef);
        
        // Make sure we did get that name
        if ((result == 0) && (certificateNameRef != nil)) {
            NSString *certName = (__bridge_transfer NSString *)certificateNameRef;
            if (certName != nil) {
                if ([certName isKindOfClass:[NSString class]]) {
                    // Simple check to test if this is a valid Mac dev certificate
                    if ([certName hasPrefix:@"3rd Party Mac Developer "] || [certName hasPrefix:@"Developer ID Installer"] || [certName hasPrefix:@"Developer ID Application"])
                        [packagingCertificates addObject:certName];
                }
            }
        }
    }
    
    // No cert ? No need to open anything...
    if (packagingCertificates.count == 0) {
        if (error != nil)
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Cannot open project if no packaging certificate is available." forKey:NSLocalizedDescriptionKey]];
        
        return NO;
    }
    
    // Populate list
    [self.installerCertificatePopUpButton addItemsWithTitles:packagingCertificates];
    
    return YES;
}

- (void)updateProjectStatus {
    // This function just updates our status icons
    if (projectURL == nil) {
        [self.codeSignIconImageView setImage:[NSImage imageNamed:@"grey-line-icon.png"]];
        [self.entitlementsIconImageView setImage:[NSImage imageNamed:@"grey-line-icon.png"]];
        [self.sandboxingIconImageView setImage:[NSImage imageNamed:@"grey-line-icon.png"]];
        [self.packagingIconImageView setImage:[NSImage imageNamed:@"grey-line-icon.png"]];
    } else {
        [self.codeSignIconImageView setImage:(self.codeSignCheckbox.state ? [NSImage imageNamed:@"green-check-icon.png"] : [NSImage imageNamed:@"red-cross-icon.png"])];
        [self.entitlementsIconImageView setImage:(self.entitlementsCheckbox.state ? [NSImage imageNamed:@"green-check-icon.png"] : [NSImage imageNamed:@"red-cross-icon.png"])];
        [self.sandboxingIconImageView setImage:(self.sandboxingCheckbox.state ? [NSImage imageNamed:@"green-check-icon.png"] : [NSImage imageNamed:@"red-cross-icon.png"])];
        [self.packagingIconImageView setImage:(self.packagingCheckbox.state ? [NSImage imageNamed:@"green-check-icon.png"] : [NSImage imageNamed:@"red-cross-icon.png"])];
    }
}

- (void)syncUIWithEntitlements {
    // No valid project, no dice
    if (projectURL == nil)
        return;
    
    // We have a valid project, activate code sign box
    [self setCodeSignBoxActive];
    
    // Sync codesign UI
    if ((provisioningCertificate != nil) && (postProcessScriptHasCodesign == YES)) {
        self.codeSignCheckbox.state = NSOnState;
        [self setEntitlementsBoxActive];
        [self setPackagingBoxActive];
    } else {
        self.codeSignCheckbox.state = NSOffState;
        [self setEntitlementsBoxInactive];
        [self setPackagingBoxInactive];
    }
    
    // Set bundle id (may be overridden if profile was not found/invalid)
    if (bundleIdentifier == nil)
        bundleIdentifier = @"";
    
    [self.bundleIdentifierTextField setStringValue:bundleIdentifier];
    
    // Set Mac App Store category
    if ([macAppStoreCategories containsObject:applicationCategory]) {
        [self.macAppStoreCategoryPopUpButton selectItemAtIndex:[macAppStoreCategories indexOfObject:applicationCategory]];
    } else {
        [self.macAppStoreCategoryPopUpButton selectItemAtIndex:0];
        applicationCategory = [macAppStoreCategories objectAtIndex:0];
    }
    
    // Set version number
    if (versionNumber == nil)
        versionNumber = @"";
    
    [self.versionNumberTextField setStringValue:versionNumber];
    
    // Set bundle GetInfo
    if (bundleGetInfo == nil)
        bundleGetInfo = @"";
    
    [self.bundleGetInfoTextField setStringValue:bundleGetInfo];
    
    // Set custom icon
    if (customIconPath != nil)
        [self.customIconImageWell setImage:[[NSImage alloc] initWithContentsOfFile:customIconPath]];
    
    // Do we have some provisioning profile loaded ?
    BOOL didFindValidProfile = NO;
    BOOL didFindInvalidProfile = NO;
    if (provisioningProfilePath != nil) {
        if ([provisioningProfilePaths containsObject:provisioningProfilePath]) { // Do we have it locally ?
            NSInteger index = [provisioningProfilePaths indexOfObject:provisioningProfilePath];
            [self.provisioningProfilePopUpButton selectItemAtIndex:index];
            [self.provisioningProfileAppIdLabel setStringValue:[provisioningProfileAppIds objectAtIndex:index]];
            [self.provisioningProfileCertificateLabel setStringValue:[provisioningProfileCertificates objectAtIndex:index]];
            
            // Update iCloud key-value store text field
            [self.iCloudKeyValueStoreTextField setStringValue:[provisioningProfileAppIds objectAtIndex:index]];
            
            // Update iCloud container text field
            [self.iCloudContainerTextField setStringValue:[provisioningProfileAppIds objectAtIndex:index]];
            
            // Mark we did find a valid profile
            didFindValidProfile = YES;
        } else {
            // Mark we did find an invalid profile
            didFindInvalidProfile = YES;
        }
    } else if (provisioningCertificate != nil) {
        // We have Developer ID code signing
        if ([provisioningProfileCertificates containsObject:provisioningCertificate]) { // Do we have it locally ?
            NSInteger index = [provisioningProfileCertificates indexOfObject:provisioningCertificate];
            [self.provisioningProfilePopUpButton selectItemAtIndex:index];
            [self.provisioningProfileAppIdLabel setStringValue:[provisioningProfileAppIds objectAtIndex:index]];
            [self.provisioningProfileCertificateLabel setStringValue:[provisioningProfileCertificates objectAtIndex:index]];
            
            // Update iCloud key-value store text field
            [self.iCloudKeyValueStoreTextField setStringValue:[provisioningProfileAppIds objectAtIndex:index]];
            
            // Update iCloud container text field
            [self.iCloudContainerTextField setStringValue:[provisioningProfileAppIds objectAtIndex:index]];
            
            // Mark we did find a valid profile
            didFindValidProfile = YES;
        } else {
            // Mark we did find an invalid profile
            didFindInvalidProfile = YES;
        }
    }
    
    if (!didFindValidProfile) {
        if (didFindInvalidProfile) {
            // This is codesigned with a profile we don't have... warn and pick our first profile in our list
            NSAlert *alert = [NSAlert alertWithMessageText:@"Provisioning Profile Not Found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The provisioning profile used to codesign this project was not found. You should pick a new provisioning profile or re-install the original profile."];
            [alert runModal];
        }
        // This obviously was not codesigned -- just pick our first available profile
        [self.provisioningProfilePopUpButton selectItemAtIndex:0];
        [self.provisioningProfileAppIdLabel setStringValue:[provisioningProfileAppIds objectAtIndex:0]];
        [self.provisioningProfileCertificateLabel setStringValue:[provisioningProfileCertificates objectAtIndex:0]];

        provisioningCertificate = [provisioningProfileCertificates objectAtIndex:0];
        provisioningProfilePath = [provisioningProfilePaths objectAtIndex:0];
        
        // Update bundle identifier
        NSString *appId = [provisioningProfileAppIds objectAtIndex:0];
        NSRange appIdFirstPart = [appId rangeOfString:@"."];
        if (appIdFirstPart.location != NSNotFound) {
            NSString *strippedAppId = [appId substringFromIndex:(appIdFirstPart.location + appIdFirstPart.length)];
            bundleIdentifier = [strippedAppId stringByReplacingOccurrencesOfString:@"*" withString:@""];
        } else {
            bundleIdentifier = @"";
        }
        [self.bundleIdentifierTextField setStringValue:bundleIdentifier];
        
        // Update iCloud key-value store text field
        [self.iCloudKeyValueStoreTextField setStringValue:[provisioningProfileAppIds objectAtIndex:0]];
        
        // Update iCloud container text field
        [self.iCloudContainerTextField setStringValue:[provisioningProfileAppIds objectAtIndex:0]];
    }
    
    // Do we have packaging certificate loaded?
    BOOL didFindValidCert = NO;
    BOOL didFindInvalidCert = NO;
    if (packagingCertificate != nil) {
        if ([packagingCertificates containsObject:packagingCertificate]) { // Do we have it locally ?
            NSInteger index = [packagingCertificates indexOfObject:packagingCertificate];
            [self.installerCertificatePopUpButton selectItemAtIndex:index];
            
            // Mark we did find a valid profile
            didFindValidCert = YES;
        } else {
            // Mark we did find an invalid profile
            didFindInvalidCert = YES;
        }
    }
    
    if (!didFindValidCert) {
        if (didFindInvalidCert) {
            // This is codesigned with a profile we don't have... warn and pick our first profile in our list
            NSAlert *alert = [NSAlert alertWithMessageText:@"Packaging Certificate Not Found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The packaging certificate used to codesign this project installer was not found. You should pick a new packaging certificate or re-install the original certificate."];
            [alert runModal];
        }
        
        // This obviously was not codesigned -- just pick our first available profile
        [self.installerCertificatePopUpButton selectItemAtIndex:0];
        
        packagingCertificate = [packagingCertificates objectAtIndex:0];
    }
    
    // Sync entitlements UI
    if (entitlements.count != 0) {
        self.entitlementsCheckbox.state = NSOnState;
        [self setSandboxingBoxActive];
    } else {
        self.entitlementsCheckbox.state = NSOffState;
        [self setSandboxingBoxInactive];
    }
    if ([entitlements objectForKey:@"com.apple.developer.ubiquity-kvstore-identifier"])
        [self.iCloudKeyValueStoreTextField setStringValue:[entitlements objectForKey:@"com.apple.developer.ubiquity-kvstore-identifier"]];
    
    if ([[entitlements objectForKey:@"com.apple.developer.ubiquity-container-identifiers"] isKindOfClass:[NSArray class]])
        [self.iCloudContainerTextField setStringValue:[[entitlements objectForKey:@"com.apple.developer.ubiquity-container-identifiers"] objectAtIndex:0]];
    
    // Sync sandboxing UI
    self.sandboxingCheckbox.state = ([[entitlements objectForKey:@"com.apple.security.app-sandbox"] boolValue] == YES) ? NSOnState : NSOffState;
    
    if ([[entitlements objectForKey:@"com.apple.security.files.user-selected.read-write"] boolValue] == YES)
        [self.sbFileSystemAccessPopUpButton selectItemAtIndex:2];
    else if ([[entitlements objectForKey:@"com.apple.security.files.user-selected.read-only"] boolValue] == YES)
        [self.sbFileSystemAccessPopUpButton selectItemAtIndex:1];
    else
        [self.sbFileSystemAccessPopUpButton selectItemAtIndex:0];
    
    [self.sbAllowDownloadsFolderAccessCheckbox setState:(([[entitlements objectForKey:@"com.apple.security.files.downloads.read-write"] boolValue] == YES) ? NSOnState : NSOffState)];
    [self.sbAllowIncomingNetworkConnectionsCheckbox setState:(([[entitlements objectForKey:@"com.apple.security.network.server"] boolValue] == YES) ? NSOnState : NSOffState)];
    [self.sbAllowOutgoingNetworkConnectionsCheckbox setState:(([[entitlements objectForKey:@"com.apple.security.network.client"] boolValue] == YES) ? NSOnState : NSOffState)];
    [self.sbAllowCameraAccessCheckbox setState:(([[entitlements objectForKey:@"com.apple.security.device.camera"] boolValue] == YES) ? NSOnState : NSOffState)];
    [self.sbAllowMicrophoneAccessCheckbox setState:(([[entitlements objectForKey:@"com.apple.security.device.microphone"] boolValue] == YES) ? NSOnState : NSOffState)];
    [self.sbAllowUSBAccessCheckbox setState:(([[entitlements objectForKey:@"com.apple.security.device.usb"] boolValue] == YES) ? NSOnState : NSOffState)];
    [self.sbAllowPrintingCheckbox setState:(([[entitlements objectForKey:@"com.apple.security.print"] boolValue] == YES) ? NSOnState : NSOffState)];
    [self.sbAllowAddressBookDataAccessCheckbox setState:(([[entitlements objectForKey:@"com.apple.security.personal-information.addressbook"] boolValue] == YES) ? NSOnState : NSOffState)];
    [self.sbAllowLocationServicesAccessCheckbox setState:(([[entitlements objectForKey:@"com.apple.security.personal-information.location"] boolValue] == YES) ? NSOnState : NSOffState)];
    [self.sbAllowCalendarDataAccessCheckbox setState:(([[entitlements objectForKey:@"com.apple.security.personal-information.calendars"] boolValue] == YES) ? NSOnState : NSOffState)];
    
    if ([[entitlements objectForKey:@"com.apple.security.assets.music.read-write"] boolValue] == YES)
        [self.sbMusicFolderAccessPopUpButton selectItemAtIndex:2];
    else if ([[entitlements objectForKey:@"com.apple.security.assets.music.read-only"] boolValue] == YES)
        [self.sbMusicFolderAccessPopUpButton selectItemAtIndex:1];
    else
        [self.sbMusicFolderAccessPopUpButton selectItemAtIndex:0];
    
    if ([[entitlements objectForKey:@"com.apple.security.assets.movies.read-write"] boolValue] == YES)
        [self.sbMoviesFolderAccessPopUpButton selectItemAtIndex:2];
    else if ([[entitlements objectForKey:@"com.apple.security.assets.movies.read-only"] boolValue] == YES)
        [self.sbMoviesFolderAccessPopUpButton selectItemAtIndex:1];
    else
        [self.sbMoviesFolderAccessPopUpButton selectItemAtIndex:0];
    
    if ([[entitlements objectForKey:@"com.apple.security.assets.pictures.read-write"] boolValue] == YES)
        [self.sbPicturesFolderAccesPopUpButton selectItemAtIndex:2];
    else if ([[entitlements objectForKey:@"com.apple.security.assets.pictures.read-only"] boolValue] == YES)
        [self.sbPicturesFolderAccesPopUpButton selectItemAtIndex:1];
    else
        [self.sbPicturesFolderAccesPopUpButton selectItemAtIndex:0];
    
    // Sync packaging UI
    if (postProcessScriptHasPackaging) {
        self.packagingCheckbox.state = NSOnState;
    } else {
        self.packagingCheckbox.state = NSOffState;
    }
    
    
    // Update project status
    [self updateProjectStatus];
}

- (void)reset {
    // Reset data
    projectURL = nil;
    postProcessScriptURL = nil;
    entitlementsURL = nil;
    
    bundleIdentifier = nil;
    applicationCategory = nil;
    versionNumber = nil;
    bundleGetInfo = nil;
    provisioningCertificate = nil;
    provisioningProfilePath = nil;
    packagingCertificate = nil;
    entitlements = nil;
    postProcessScriptHasCodesign = NO;
    postProcessScriptHasPackaging = NO;
    
    provisioningProfilePaths = nil;
    provisioningProfileNames = nil;
    provisioningProfileAppIds = nil;
    provisioningProfileCertificates = nil;
    packagingCertificates = nil;
    
    // Make sure Mac App Store categories are populated
    if (self.macAppStoreCategoryPopUpButton.numberOfItems == 0) {
        // Populate Mac App Store category pop up list
        for (NSString *title in macAppStoreCategoriesFullNames)
            [self.macAppStoreCategoryPopUpButton addItemWithTitle:title];
    }

    
    // Reset UI
    // Make all UI inactive
    [self.updateBuildPipelineButton setEnabled:NO];
    [self.clearBuildPipelineButton setEnabled:NO];
    [self setCodeSignBoxInactive]; // this will recursively make entitlements box and sandboxing box inactive
    
    // Reset project name
    [self.projectNameLabel setStringValue:@"No Open Project"];
    
    // Reset project status
    [self updateProjectStatus];
    
    // Reset user modifiable UI elements
    [self.codeSignCheckbox setState:NSOffState];
    [self.provisioningProfilePopUpButton removeAllItems];
    [self.bundleIdentifierTextField setStringValue:@""];
    [self.macAppStoreCategoryPopUpButton selectItemAtIndex:0];
    [self.versionNumberTextField setStringValue:@""];
    [self.bundleGetInfoTextField setStringValue:@""];
    
    [self.entitlementsCheckbox setState:NSOffState];
    [self.iCloudKeyValueStoreTextField setStringValue:@""];
    [self.iCloudContainerTextField setStringValue:@""];
    
    [self.sandboxingCheckbox setState:NSOffState];
    [self.sbFileSystemAccessPopUpButton selectItemAtIndex:0];
    [self.sbAllowDownloadsFolderAccessCheckbox setState:NSOffState];
    [self.sbAllowIncomingNetworkConnectionsCheckbox setState:NSOffState];
    [self.sbAllowOutgoingNetworkConnectionsCheckbox setState:NSOffState];
    [self.sbAllowCameraAccessCheckbox setState:NSOffState];
    [self.sbAllowMicrophoneAccessCheckbox setState:NSOffState];
    [self.sbAllowUSBAccessCheckbox setState:NSOffState];
    [self.sbAllowPrintingCheckbox setState:NSOffState];
    [self.sbAllowAddressBookDataAccessCheckbox setState:NSOffState];
    [self.sbAllowLocationServicesAccessCheckbox setState:NSOffState];
    [self.sbAllowCalendarDataAccessCheckbox setState:NSOffState];
    [self.sbMusicFolderAccessPopUpButton selectItemAtIndex:0];
    [self.sbMoviesFolderAccessPopUpButton selectItemAtIndex:0];
    [self.sbPicturesFolderAccesPopUpButton selectItemAtIndex:0];
    
    [self.packagingCheckbox setState:NSOffState];
    [self.installerCertificatePopUpButton selectItemAtIndex:0];
}

- (void)setCodeSignBoxActive {
    [self.codeSignCheckbox setEnabled:YES];
    [self.provisioningProfilePopUpButton setEnabled:YES];
    [self.bundleIdentifierTextField setEnabled:YES];
    [self.macAppStoreCategoryPopUpButton setEnabled:YES];
    [self.versionNumberTextField setEnabled:YES];
    [self.bundleGetInfoTextField setEnabled:YES];
    [self.customIconImageWell setEnabled:YES];
    [self.setCustomIconButton setEnabled:YES];
    [self.unsetCustomIconButton setEnabled:YES];
    
    // No IBOutletCollection ? No problem...
    for (id view in self.codeSignBox.recursiveSubviews)
        if ([view tag] == 666)
            [view setTextColor:[NSColor controlTextColor]];
    
    // Maybe we should enable entitlements box as well ?
    if (self.codeSignCheckbox.state == NSOnState) {
        [self setEntitlementsBoxActive];
        [self setPackagingBoxActive];
    }
}

- (void)setCodeSignBoxInactive {
    // Disable components
    [self.codeSignCheckbox setEnabled:NO];
    [self.provisioningProfilePopUpButton setEnabled:NO];
    [self.bundleIdentifierTextField setEnabled:NO];
    [self.macAppStoreCategoryPopUpButton setEnabled:NO];
    [self.versionNumberTextField setEnabled:NO];
    [self.bundleGetInfoTextField setEnabled:NO];
    [self.customIconImageWell setEnabled:NO];
    [self.setCustomIconButton setEnabled:NO];
    [self.unsetCustomIconButton setEnabled:NO];
   
    // Grey out all labels
    // No IBOutletCollection ? No problem...
    for (id view in self.entitlementsBox.recursiveSubviews)
        if ([view tag] == 666)
            [view setTextColor:[NSColor disabledControlTextColor]];
    
    // Recursively set entitlements inactive
    [self setEntitlementsBoxInactive];
    [self setPackagingBoxInactive];
}

- (void)setEntitlementsBoxActive {
    // Enable components
    [self.entitlementsCheckbox setEnabled:YES];
    [self.iCloudKeyValueStoreTextField setEnabled:YES];
    [self.iCloudContainerTextField setEnabled:YES];
    
    // Dark out all labels
    // No IBOutletCollection ? No problem...
    for (id view in self.entitlementsBox.recursiveSubviews)
        if ([view tag] == 666)
            [view setTextColor:[NSColor controlTextColor]];
    
    // Maybe we should enable sandboxing box as well ?
    if (self.entitlementsCheckbox.state == NSOnState)
        [self setSandboxingBoxActive];
}

- (void)setEntitlementsBoxInactive {
    // Disable components
    [self.entitlementsCheckbox setEnabled:NO];
    [self.iCloudKeyValueStoreTextField setEnabled:NO];
    [self.iCloudContainerTextField setEnabled:NO];
    
    // Grey out all labels
    // No IBOutletCollection ? No problem...
    for (id view in self.entitlementsBox.recursiveSubviews)
        if ([view tag] == 666)
            [view setTextColor:[NSColor disabledControlTextColor]];
    
    // Recursively set sandboxing inactive
    [self setSandboxingBoxInactive];
}

- (void)setSandboxingBoxActive {
    // Enable components
    [self.sandboxingCheckbox setEnabled:YES];
    [self.sbFileSystemAccessPopUpButton setEnabled:YES];
    [self.sbAllowDownloadsFolderAccessCheckbox setEnabled:YES];
    [self.sbAllowIncomingNetworkConnectionsCheckbox setEnabled:YES];
    [self.sbAllowOutgoingNetworkConnectionsCheckbox setEnabled:YES];
    [self.sbAllowCameraAccessCheckbox setEnabled:YES];
    [self.sbAllowMicrophoneAccessCheckbox setEnabled:YES];
    [self.sbAllowUSBAccessCheckbox setEnabled:YES];
    [self.sbAllowPrintingCheckbox setEnabled:YES];
    [self.sbAllowAddressBookDataAccessCheckbox setEnabled:YES];
    [self.sbAllowLocationServicesAccessCheckbox setEnabled:YES];
    [self.sbAllowCalendarDataAccessCheckbox setEnabled:YES];
    [self.sbMusicFolderAccessPopUpButton setEnabled:YES];
    [self.sbMoviesFolderAccessPopUpButton setEnabled:YES];
    [self.sbPicturesFolderAccesPopUpButton setEnabled:YES];
    
    // Dark out all labels
    // No IBOutletCollection ? No problem...
    for (id view in self.sandboxingBox.recursiveSubviews)
        if ([view tag] == 666)
            [view setTextColor:[NSColor controlTextColor]];
}

- (void)setSandboxingBoxInactive {
    // Disable components
    [self.sandboxingCheckbox setEnabled:NO];
    [self.sbFileSystemAccessPopUpButton setEnabled:NO];
    [self.sbAllowDownloadsFolderAccessCheckbox setEnabled:NO];
    [self.sbAllowIncomingNetworkConnectionsCheckbox setEnabled:NO];
    [self.sbAllowOutgoingNetworkConnectionsCheckbox setEnabled:NO];
    [self.sbAllowCameraAccessCheckbox setEnabled:NO];
    [self.sbAllowMicrophoneAccessCheckbox setEnabled:NO];
    [self.sbAllowUSBAccessCheckbox setEnabled:NO];
    [self.sbAllowPrintingCheckbox setEnabled:NO];
    [self.sbAllowAddressBookDataAccessCheckbox setEnabled:NO];
    [self.sbAllowLocationServicesAccessCheckbox setEnabled:NO];
    [self.sbAllowCalendarDataAccessCheckbox setEnabled:NO];
    [self.sbMusicFolderAccessPopUpButton setEnabled:NO];
    [self.sbMoviesFolderAccessPopUpButton setEnabled:NO];
    [self.sbPicturesFolderAccesPopUpButton setEnabled:NO];
    
    // Grey out all labels
    // No IBOutletCollection ? No problem...
    for (id view in self.sandboxingBox.recursiveSubviews)
        if ([view tag] == 666)
            [view setTextColor:[NSColor disabledControlTextColor]];
}

- (void)setPackagingBoxActive {
    // Enable components
    [self.packagingCheckbox setEnabled:YES];
    [self.installerCertificatePopUpButton setEnabled:YES];
    
    // Dark out all labels
    // No IBOutletCollection ? No problem...
    for (id view in self.packagingBox.recursiveSubviews)
        if ([view tag] == 666)
            [view setTextColor:[NSColor controlTextColor]];
}

- (void)setPackagingBoxInactive {
    // Disable components
    [self.packagingCheckbox setEnabled:NO];
    [self.installerCertificatePopUpButton setEnabled:NO];
    
    // Grey out all labels
    // No IBOutletCollection ? No problem...
    for (id view in self.packagingBox.recursiveSubviews)
        if ([view tag] == 666)
            [view setTextColor:[NSColor disabledControlTextColor]];
}

- (void)updatePostProcessScript:(NSMutableString *)script codesign:(BOOL)withCodesign entitlements:(BOOL)withEntitlements packaging:(BOOL)withPackaging {
    // Failsafe
    if ((script == nil) || (![script isKindOfClass:[NSMutableString class]]))
        return;
    
    // Do we want to codesign or not?
    if (withCodesign == NO) {
        // Remove any existing script related to codesign&entitlements
        NSRange beginRange = [script rangeOfString:@"\n\n\n#BEGIN APPLY ENTITLEMENTS"];
        if (beginRange.location == NSNotFound)
            beginRange = [script rangeOfString:@"#BEGIN APPLY ENTITLEMENTS"];
        
        if (beginRange.location != NSNotFound) {
            NSRange endRange = [script rangeOfString:@"#END APPLY ENTITLEMENTS\n\n"];
            if (endRange.location == NSNotFound)
                endRange = [script rangeOfString:@"#END APPLY ENTITLEMENTS"];
            
            if (endRange.location != NSNotFound) {
                [script replaceCharactersInRange:NSMakeRange(beginRange.location, endRange.location + endRange.length - beginRange.location) withString:@""];
            }
        }
        
        // Mark as post process script as not having codesign
        postProcessScriptHasCodesign = NO;
        postProcessScriptHasPackaging = NO;
    } else {
        NSString *provisioningProfileCopyCommand = ([provisioningProfilePath isEqualToString:@""] || !provisioningProfilePath) ? @"" : [NSString stringWithFormat:@"system(\"cp \\\"%@\\\" \\\"$EntitlementsPublishFile/Contents/embedded.provisionprofile\\\"\");\n    ", provisioningProfilePath];
        
        // Prepare our perl operation string -- We will always embed provisioning profile so include this ; We will always update bundle identifier so include this as well
        NSMutableString *perlOperationString = [NSMutableString stringWithFormat:@"\nmy $EntitlementsPublishFile = $ARGV[0];\nmy $EntitlementsPublishTarget = $ARGV[1];\nmy $EntitlementsPackageFile = $ARGV[0]; chop($EntitlementsPackageFile); chop($EntitlementsPackageFile); chop($EntitlementsPackageFile); $EntitlementsPackageFile = $EntitlementsPackageFile . 'pkg';\nif (($EntitlementsPublishTarget eq \"standaloneOSXIntel\") || ($EntitlementsPublishTarget eq \"standaloneOSXUniversal\")) {\n    %@system(\"defaults write \\\"$EntitlementsPublishFile/Contents/Info.plist\\\" \\\"CFBundleIdentifier\\\" -string \\\"%@\\\"\");\n    system(\"defaults write \\\"$EntitlementsPublishFile/Contents/Info.plist\\\" \\\"LSApplicationCategoryType\\\" -string \\\"%@\\\"\");", provisioningProfileCopyCommand, bundleIdentifier, applicationCategory];
        
        // Add version number
        [perlOperationString appendFormat:@"\n    system(\"defaults write \\\"$EntitlementsPublishFile/Contents/Info.plist\\\" \\\"CFBundleVersion\\\" -string \\\"%@\\\"\");", versionNumber];
        [perlOperationString appendFormat:@"\n    system(\"defaults write \\\"$EntitlementsPublishFile/Contents/Info.plist\\\" \\\"CFBundleShortVersionString\\\" -string \\\"%@\\\"\");", versionNumber];
        
        // Add bundle getinfo if specified
        if ((bundleGetInfo != nil) && ! [bundleGetInfo isEqualToString:@""])
            [perlOperationString appendFormat:@"\n    system(\"defaults write \\\"$EntitlementsPublishFile/Contents/Info.plist\\\" \\\"CFBundleGetInfoString\\\" -string \\\"%@\\\"\");", bundleGetInfo];
        
        // Copy custom icon
        if ((customIconPath != nil) && ! [customIconPath isEqualToString:@""])
            [perlOperationString appendFormat:@"\n    system(\"cp \\\"%@\\\" \\\"$EntitlementsPublishFile/Contents/Resources/UnityPlayer.icns\\\"\");", customIconPath];
        
        // chmod bundle
        [perlOperationString appendString:@"\n    system(\"chmod -R a+xr \\\"$EntitlementsPublishFile\\\"\");"];
        
        // Do we want entitlements or not?
        if (withEntitlements == YES)
            [perlOperationString appendFormat:@"\n    system(\"/usr/bin/codesign --force --sign \\\"%@\\\" --entitlements \\\"%@\\\" \\\"$EntitlementsPublishFile\\\"\");", provisioningCertificate, entitlementsURL.path];
        else
            [perlOperationString appendFormat:@"\n    system(\"/usr/bin/codesign --force --sign \\\"%@\\\" \\\"$EntitlementsPublishFile\\\"\");", provisioningCertificate];
        
        // Do we want packaging?
        if (withPackaging == YES) {
            [perlOperationString appendFormat:@"\n    system(\"/usr/bin/productbuild --component \\\"$EntitlementsPublishFile\\\" /Applications --sign \\\"%@\\\" --product \\\"$EntitlementsPublishFile/Contents/Info.plist\\\" \\\"$EntitlementsPackageFile\\\"\");", packagingCertificate];
            postProcessScriptHasPackaging = YES;
        } else
            postProcessScriptHasPackaging = NO;
        
        // Append ending
        [perlOperationString appendString:@"\n}\n"];
        
        // Check wether we already had our scripting stuff
        NSRange beginRange = [script rangeOfString:@"#BEGIN APPLY ENTITLEMENTS"];
        if (beginRange.location != NSNotFound) {
            NSRange endRange = [script rangeOfString:@"#END APPLY ENTITLEMENTS"];
            if (endRange.location != NSNotFound) {
                [script replaceCharactersInRange:NSMakeRange(beginRange.location + beginRange.length, endRange.location - (beginRange.location + beginRange.length)) withString:perlOperationString];
            }
        } else {
            // No existing scripting stuff, append it
            [script appendFormat:@"\n\n\n#BEGIN APPLY ENTITLEMENTS%@#END APPLY ENTITLEMENTS\n\n", perlOperationString];
        }
        
        // Mark our post process script as having codesign
        postProcessScriptHasCodesign = YES;
    }
}


@end
