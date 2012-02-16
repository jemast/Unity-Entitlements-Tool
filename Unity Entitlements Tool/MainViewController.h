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


#import <Cocoa/Cocoa.h>

@interface MainViewController : NSViewController <NSOpenSavePanelDelegate> {
    NSArray *macAppStoreCategories;
    NSArray *macAppStoreCategoriesFullNames;
    
    NSURL *projectURL;
    NSURL *postProcessScriptURL;
    NSURL *entitlementsURL;
    
    NSString *bundleIdentifier;
    NSString *applicationCategory;
    NSString *provisioningCertificate;
    NSString *provisioningProfilePath;
    NSMutableDictionary *entitlements;
    BOOL postProcessScriptHasCodesign;
    BOOL postProcessScriptHasPackaging;
    
    NSMutableArray *provisioningProfilePaths;
    NSMutableArray *provisioningProfileNames;
    NSMutableArray *provisioningProfileAppIds;
    NSMutableArray *provisioningProfileCertificates;
}

///////////////////
// PROJECT ITEMS //
///////////////////

// Labels
@property (unsafe_unretained) IBOutlet NSTextField *projectNameLabel;

// Image Views
@property (unsafe_unretained) IBOutlet NSImageView *projectIconImageView;
@property (unsafe_unretained) IBOutlet NSImageView *codeSignIconImageView;
@property (unsafe_unretained) IBOutlet NSImageView *entitlementsIconImageView;
@property (unsafe_unretained) IBOutlet NSImageView *sandboxingIconImageView;
@property (unsafe_unretained) IBOutlet NSImageView *packagingIconImageView;

// Buttons
@property (unsafe_unretained) IBOutlet NSButton *pickProjectDirectoryButton;
@property (unsafe_unretained) IBOutlet NSButton *updateBuildPipelineButton;
@property (unsafe_unretained) IBOutlet NSButton *clearBuildPipelineButton;

// Actions
- (IBAction)pickProjectDirectoryPressed:(id)sender;
- (IBAction)updateBuildPipelinePressed:(id)sender;
- (IBAction)clearBuildPipelinePressed:(id)sender;


////////////////////
// CODESIGN ITEMS //
////////////////////

@property (unsafe_unretained) IBOutlet NSBox *codeSignBox;

// Labels
@property (unsafe_unretained) IBOutlet NSTextField *provisioningProfileAppIdLabel;
@property (unsafe_unretained) IBOutlet NSTextField *provisioningProfileCertificateLabel;

// Buttons
@property (unsafe_unretained) IBOutlet NSPopUpButton *provisioningProfilePopUpButton;
@property (unsafe_unretained) IBOutlet NSPopUpButton *macAppStoreCategoryPopUpButton;

// Checkboxes
@property (unsafe_unretained) IBOutlet NSButton *codeSignCheckbox;

// Text fields
@property (unsafe_unretained) IBOutlet NSTextField *bundleIdentifierTextField;

// Actions
- (IBAction)codeSignCheckboxPressed:(id)sender;
- (IBAction)provisioningProfilePicked:(id)sender;
- (IBAction)bundleIdentifierTextFieldEdited:(id)sender;
- (IBAction)appStoreCategoryPicked:(id)sender;


////////////////////////
// ENTITLEMENTS ITEMS //
////////////////////////

@property (unsafe_unretained) IBOutlet NSBox *entitlementsBox;

// Checkboxes
@property (unsafe_unretained) IBOutlet NSButton *entitlementsCheckbox;

// Text fields
@property (unsafe_unretained) IBOutlet NSTextField *iCloudKeyValueStoreTextField;
@property (unsafe_unretained) IBOutlet NSTextField *iCloudContainerTextField;

// Actions
- (IBAction)entitlementsCheckboxPressed:(id)sender;
- (IBAction)iCloudKeyValueStoreTextFieldEdited:(id)sender;
- (IBAction)iCloudContainerTextFieldEdited:(id)sender;


//////////////////////
// SANDBOXING ITEMS //
//////////////////////

@property (unsafe_unretained) IBOutlet NSBox *sandboxingBox;

// Checkboxes
@property (unsafe_unretained) IBOutlet NSButton *sandboxingCheckbox;

@property (unsafe_unretained) IBOutlet NSButton *sbAllowDownloadsFolderAccessCheckbox;
@property (unsafe_unretained) IBOutlet NSButton *sbAllowIncomingNetworkConnectionsCheckbox;
@property (unsafe_unretained) IBOutlet NSButton *sbAllowOutgoingNetworkConnectionsCheckbox;
@property (unsafe_unretained) IBOutlet NSButton *sbAllowCameraAccessCheckbox;
@property (unsafe_unretained) IBOutlet NSButton *sbAllowMicrophoneAccessCheckbox;
@property (unsafe_unretained) IBOutlet NSButton *sbAllowUSBAccessCheckbox;
@property (unsafe_unretained) IBOutlet NSButton *sbAllowPrintingCheckbox;
@property (unsafe_unretained) IBOutlet NSButton *sbAllowAddressBookDataAccessCheckbox;
@property (unsafe_unretained) IBOutlet NSButton *sbAllowLocationServicesAccessCheckbox;
@property (unsafe_unretained) IBOutlet NSButton *sbAllowCalendarDataAccessCheckbox;

// Buttons
@property (unsafe_unretained) IBOutlet NSPopUpButton *sbFileSystemAccessPopUpButton;
@property (unsafe_unretained) IBOutlet NSPopUpButton *sbMusicFolderAccessPopUpButton;
@property (unsafe_unretained) IBOutlet NSPopUpButton *sbMoviesFolderAccessPopUpButton;
@property (unsafe_unretained) IBOutlet NSPopUpButton *sbPicturesFolderAccesPopUpButton;

// Actions
- (IBAction)sandboxingCheckboxPressed:(id)sender;
- (IBAction)sandboxingPopUpButtonPicked:(id)sender;
- (IBAction)sandboxingOptionCheckboxPressed:(id)sender;


/////////////////////
// PACKAGING ITEMS //
/////////////////////

@property (unsafe_unretained) IBOutlet NSBox *packagingBox;

// Checkboxes
@property (unsafe_unretained) IBOutlet NSButton *packagingCheckbox;

// Actions
- (IBAction)packagingCheckboxPressed:(id)sender;


@end


//////////////////////////////////
// INTERNAL METHODS DELCARATION //
//////////////////////////////////
// We're not attempting to hide them, we're just separating them in another .m file for clarity's sake
@interface MainViewController (Internal)

- (BOOL)importProjectBuildPipeline:(NSError *__autoreleasing *)error;
- (BOOL)updateProvisioningProfileList:(NSError *__autoreleasing *)error;

- (void)updateProjectStatus;
- (void)syncUIWithEntitlements;
- (void)reset;

- (void)setCodeSignBoxActive;
- (void)setCodeSignBoxInactive;
- (void)setEntitlementsBoxActive;
- (void)setEntitlementsBoxInactive;
- (void)setSandboxingBoxActive;
- (void)setSandboxingBoxInactive;
- (void)setPackagingBoxActive;
- (void)setPackagingBoxInactive;

- (void)updatePostProcessScript:(NSMutableString *)script codesign:(BOOL)withCodesign entitlements:(BOOL)withEntitlements packaging:(BOOL)withPackaging;


@end


