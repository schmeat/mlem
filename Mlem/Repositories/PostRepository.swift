//
//  PostRepository.swift
//  Mlem
//
//  Created by Eric Andrews on 2023-07-31.
//

import Dependencies
import Foundation

class PostRepository {
    @Dependency(\.apiClient) private var apiClient
    
    // swiftlint:disable function_parameter_count
    func loadPage(
        communityId: Int?,
        page: Int,
        cursor: String?,
        sort: PostSortType?,
        type: APIListingType,
        limit: Int,
        savedOnly: Bool? = nil,
        communityName: String? = nil
    ) async throws -> (items: [PostModel], cursor: String?) {
        let response = try await apiClient.loadPosts(
            communityId: communityId,
            page: page,
            cursor: cursor,
            sort: sort,
            type: type,
            limit: limit,
            savedOnly: savedOnly,
            communityName: communityName
        )
        
        let items = response.posts.map { PostModel(from: $0) }
        return (items, response.nextPage)
    }

    // swiftlint:enable function_parameter_count
    
    /// Loads a single post
    /// - Parameter postId: id of the post to load
    /// - Returns: PostModel of the requested post
    func loadPost(postId: Int) async throws -> PostModel {
        let postView = try await apiClient.loadPost(id: postId)
        return PostModel(from: postView)
    }
    
    /// Attempts to mark the given PostModel as read. On success, returns a new PostModel with the updated read state; on failure, returns the original PostModel.
    /// - Parameters:
    ///   - post: PostModel to attempt to read
    ///   - read: Intended read state of the post model (true to mark read, false to mark unread)
    func markRead(post: PostModel, read: Bool) async throws -> PostModel {
        let success = try await apiClient.markPostAsRead(for: post.postId, read: read).success
        return PostModel(from: post, read: success ? read : post.read)
    }

    /// Rates a given post. Does not care what the current vote state is; sends the given request no matter what (i.e., calling this with operation `.upvote` on an already upvoted post will not send a `.resetVote`, but will instead send a second idempotent `.upvote`)
    /// - Parameters:
    ///   - postId: id of the post to rate
    ///   - operation: ScoringOperation to apply to the given post id
    /// - Returns: PostModel representing the new state of the post
    func ratePost(postId: Int, operation: ScoringOperation) async throws -> PostModel {
        let postView = try await apiClient.ratePost(id: postId, score: operation)
        return PostModel(from: postView)
    }

    /// Saves a given post. Does not care what the current save state is; sends the given request no matter what (i.e., calling this operation with shouldSave: true on an already saved post will not unsave the post, but will instead send a second idempotent save: true)
    /// - Parameters:
    ///   - postId: id of the post to save
    ///   - shouldSave: bool indicating whether to save (true) or unsave (false)
    /// - Returns: PostModel representing the new state of the post
    func savePost(postId: Int, shouldSave: Bool) async throws -> PostModel {
        let postView = try await apiClient.savePost(id: postId, shouldSave: shouldSave)
        let ret: PostModel = .init(from: postView)
        ret.read = true // the API call sets read to true but doesn't include that in the response so we do it here
        return ret
    }
    
    func deletePost(postId: Int, shouldDelete: Bool) async throws -> PostModel {
        let postView = try await apiClient.deletePost(id: postId, shouldDelete: true)
        return PostModel(from: postView)
    }
    
    /// Edits a post. Any non-nil parameters will be updated
    /// - Parameters:
    ///   - postId: id of the post to edit
    ///   - name: new post name
    ///   - url: new post url
    ///   - body: new post body
    ///   - nsfw: new post nsfw status
    ///   - languageId: the language id for the post if available
    /// - Returns: PostModel with the new state of the post
    func editPost(
        postId: Int,
        name: String?,
        url: String?,
        body: String?,
        nsfw: Bool?,
        languageId: Int? = nil
    ) async throws -> PostModel {
        let response = try await apiClient.editPost(
            postId: postId,
            name: name,
            url: url,
            body: body,
            nsfw: nsfw,
            languageId: languageId
        )
        return PostModel(from: response.postView)
    }
}
