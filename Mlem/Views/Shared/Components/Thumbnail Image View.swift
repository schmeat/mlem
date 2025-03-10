//
//  Thumbnail Image View.swift
//  Mlem
//
//  Created by Eric Andrews on 2023-07-29.
//

import Dependencies
import Foundation
import SwiftUI

struct ThumbnailImageView: View {
    @AppStorage("shouldBlurNsfw") var shouldBlurNsfw: Bool = true
    
    @Dependency(\.errorHandler) var errorHandler
    @Dependency(\.postRepository) var postRepository
    @Environment(\.openURL) private var openURL
    
    @ObservedObject var post: PostModel
    
    var showNsfwFilter: Bool { (post.post.nsfw || post.community.nsfw) && shouldBlurNsfw }
    
    let size = CGSize(width: AppConstants.thumbnailSize, height: AppConstants.thumbnailSize)
    
    var body: some View {
        Group {
            switch post.postType {
            case let .image(url):
                // just blur, no need for the whole filter viewModifier since this is just a thumbnail
                CachedImage(
                    url: url,
                    fixedSize: size,
                    blurRadius: showNsfwFilter ? 8 : 0,
                    contentMode: .fill,
                    onTapCallback: markPostAsRead
                )
            case let .link(url):
                CachedImage(
                    url: url,
                    shouldExpand: false,
                    fixedSize: size,
                    blurRadius: showNsfwFilter ? 8 : 0,
                    contentMode: .fill
                )
                .onTapGesture {
                    if let url = post.post.linkUrl {
                        openURL(url)
                        markPostAsRead()
                    }
                }
                .overlay {
                    Group {
                        WebsiteIndicatorView()
                            .frame(width: 20, height: 20)
                            .padding(6)
                    }
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                }
            case .text:
                Image(systemName: Icons.textPost)
            case .titleOnly:
                Image(systemName: Icons.titleOnlyPost)
            }
        }
        .foregroundColor(.secondary)
        .font(.title)
        .frame(width: AppConstants.thumbnailSize, height: AppConstants.thumbnailSize)
        .background(Color(UIColor.systemGray4))
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.smallItemCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: AppConstants.smallItemCornerRadius)
            .stroke(Color(UIColor.secondarySystemBackground), lineWidth: 1))
    }
    
    /// Synchronous void wrapper for postTracker.markRead to pass into CachedImage as dismiss callback
    func markPostAsRead() {
        Task(priority: .userInitiated) {
            await post.markRead(true)
        }
    }
}
