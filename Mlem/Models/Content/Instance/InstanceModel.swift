//
//  InstanceModel.swift
//  Mlem
//
//  Created by Sjmarf on 13/01/2024.
//

import SwiftUI

struct InstanceModel {
    var displayName: String!
    var description: String?
    var avatar: URL?
    var banner: URL?
    var administrators: [UserModel]?
    var url: URL!
    var version: SiteVersion?
    var creationDate: Date?
    
    // From APISiteView
    var userCount: Int?
    var communityCount: Int?
    var postCount: Int?
    var commentCount: Int?
    var activeUserCount: ActiveUserCount?
    
    // From APILocalSite (only accessible via SiteResponse)
    var `private`: Bool?
    var federates: Bool?
    var federationSignedFetch: Bool?
    var allowsDownvotes: Bool?
    var allowsNSFW: Bool?
    var allowsCommunityCreation: Bool?
    var requiresEmailVerification: Bool?
    var slurFilterRegex: Regex<AnyRegexOutput>?
    var slurFilterString: String?
    var captchaDifficulty: APICaptchaDifficulty?
    var registrationMode: APIRegistrationMode?
    var defaultFeedType: APIListingType?
    var hideModlogModNames: Bool?
    var applicationsEmailAdmins: Bool?
    var reportsEmailAdmins: Bool?
    
    init(from response: SiteResponse) {
        update(with: response)
    }
    
    init(from siteView: APISiteView) {
        self.update(with: siteView)
    }
    
    init(from site: APISite) {
        update(with: site)
    }
    
    init(from stub: InstanceStub) {
        self.update(with: stub)
    }
    
    var name: String { url.host() ?? displayName }
    
    mutating func update(with response: SiteResponse) {
        administrators = response.admins.map {
            var user = UserModel(from: $0)
            user.usesExternalData = true
            user.isAdmin = true
            return user
        }
        version = SiteVersion(response.version)
        
        let localSite = response.siteView.localSite
        self.allowsDownvotes = localSite.enableDownvotes
        self.allowsNSFW = localSite.enableNsfw
        self.allowsCommunityCreation = !localSite.communityCreationAdminOnly
        self.requiresEmailVerification = localSite.requireEmailVerification
        self.captchaDifficulty = localSite.captchaEnabled ? localSite.captchaDifficulty : nil
        self.private = localSite.privateInstance
        self.federates = localSite.federationEnabled
        self.federationSignedFetch = localSite.federationSignedFetch
        self.defaultFeedType = localSite.defaultPostListingType
        self.hideModlogModNames = localSite.hideModlogModNames
        self.applicationsEmailAdmins = localSite.applicationEmailAdmins
        self.reportsEmailAdmins = localSite.reportsEmailAdmins

        self.registrationMode = localSite.registrationMode
        do {
            if let regex = localSite.slurFilterRegex {
                self.slurFilterString = regex
                self.slurFilterRegex = try .init(regex)
            }
        } catch {
            print("Invalid slur filter regex")
        }
        
        self.update(with: response.siteView)
    }
    
    mutating func update(with siteView: APISiteView) {
        userCount = siteView.counts.users
        communityCount = siteView.counts.communities
        postCount = siteView.counts.posts
        commentCount = siteView.counts.comments
        
        self.activeUserCount = .init(
            sixMonths: siteView.counts.usersActiveHalfYear,
            month: siteView.counts.usersActiveMonth,
            week: siteView.counts.usersActiveWeek,
            day: siteView.counts.usersActiveDay
        )
        
        self.update(with: siteView.site)
    }
    
    mutating func update(with site: APISite) {
        displayName = site.name
        description = site.sidebar
        avatar = site.iconUrl
        banner = site.bannerUrl
        creationDate = site.published
        
        if var components = URLComponents(string: site.inboxUrl) {
            components.path = ""
            url = components.url
        }
    }
    
    mutating func update(with stub: InstanceStub) {
        displayName = stub.name
        url = URL(string: "https://\(stub.host)")
        version = stub.version
        userCount = stub.userCount
        if let avatar = stub.avatar {
            self.avatar = URL(string: avatar)
        }
    }
    
    func firstSlurFilterMatch(_ input: String) -> String? {
        do {
            if let slurFilterRegex {
                if let output = try slurFilterRegex.firstMatch(in: input.lowercased()) {
                    return String(input[output.range])
                }
            }
        } catch {
            print("REGEX FAILED")
        }
        return nil
    }
}

extension InstanceModel: Identifiable {
    var id: Int { hashValue }
}

extension InstanceModel: Hashable {
    static func == (lhs: InstanceModel, rhs: InstanceModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    /// Hashes all fields for which state changes should trigger view updates.
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(creationDate)
    }
}
