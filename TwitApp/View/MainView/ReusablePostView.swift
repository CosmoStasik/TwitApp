//
//  ReusablePostView.swift
//  TwitApp
//
//  Created by Stanislav Sobolevsky on 27.12.22.
//

import SwiftUI
import Firebase
import FirebaseFirestore


struct ReusablePostView: View {
    @Binding var posts: [Post]
    // View Properties
    @State var isFetching: Bool = true
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack{
                if isFetching{
                    ProgressView()
                        .padding(.top,30)
                } else {
                    if posts.isEmpty {
                        // No posts found on Firestore
                        Text("No Posts Found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top,30)
                    } else {
                        // Displaing Posts
                        Posts()
                        
                    }
                    
                }
                    
            }
            .padding(15)
        }
        .refreshable {
            // Scroll to Refresh
        isFetching = true
            posts = []
            await fetchPosts() // т,к Выражиение асинхронно оно должен быть помеченно "ожиданием"
        }
        
        .task {
            // Fetching for one Time
            guard posts.isEmpty else {return}
            await fetchPosts()
        }
    }
    // Displaing Fetched Posts
    @ViewBuilder
    func Posts() -> some View {
        ForEach(posts) { post in
            PostCardView(post: post) { updatedPost in
                // Updating Post in the Arrray
                if let index = posts.firstIndex(where: { post in
                    post.id == updatedPost.id
                }){
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs = updatedPost.dislikedIDs
                }
            } onDelete: {
                // Removing Post from the array
                withAnimation(.easeInOut(duration: 0.25)){
                    posts.removeAll{post.id == $0.id}
                }
            }

               Divider()
                .padding(.horizontal,-15)
           
            
            
        }
    }
    // Fetching Posts
    func fetchPosts()async{
        do {
            var query: Query!
            query = Firestore.firestore().collection("Posts")
                .order(by: "publishedDate", descending: true)
                .limit(to: 20)
            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
            await MainActor.run(body: {
                posts = fetchedPosts
                isFetching = false
            })
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct ReusablePostView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
