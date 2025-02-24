//
//  SettingsRoutes.swift
//  Mlem
//
//  Created by Bosco Ho on 2023-08-18.
//

import Foundation

enum SettingsPage: DestinationValue {
    case currentAccount
    case editProfile
    case signInAndSecurity
    case accountGeneral
    case accountAdvanced
    case accountLocal
    case accountDiscussionLanguages
    case linkMatrixAccount
    case accounts
    case quickSwitcher
    case general
    case sorting
    case contentFilters
    case accessibility
    case appearance
    case about
    case advanced
}

enum AboutSettingsPage: DestinationValue {
    case contributors
    /// e.g. `Privacy Policy` or `EULA`.
    case document(Document)
    case licenses
}

enum AppearanceSettingsPage: DestinationValue {
    case theme
    case appIcon
    case posts
    case comments
    case communities
    case users
    case tabBar
}

enum CommentSettingsPage: DestinationValue {
    case layoutWidget
}

enum PostSettingsPage: DestinationValue {
    case customizeWidgets
}

enum LicensesSettingsPage: DestinationValue {
    case licenseDocument(Document)
}
