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
    var basedOnUID: Bool = false
    var uid: String = ""
    @Binding var posts: [Post]
    // View Properties
    @State private var isFetching: Bool = true
    // Pagination
    @State private var paginationDoc: QueryDocumentSnapshot?
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
            // Disbaling Refresh for UID based Posts
            guard !basedOnUID else {return}
        isFetching = true
            posts = []
            // Resetting Pagination Doc
            paginationDoc = nil
            await fetchPosts() // т,к Выражиение асинхронно оно должен быть помеченно "ожиданием" await
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
            .onAppear {
                // When last Post Appears, Fetching New Post (If There)
                ///Разбиение на тсраницы, проверяем пусто ли, тк на тсранице я указал видно 20 постов/или 20 абзацов, а значит
                ///если будет 40, то переход на новую, если будет пусто, то не будет происходить лишнего поиска/загрузки(который может привести к крашу
                if post.id == posts.last?.id && paginationDoc != nil {
                    //print("Fetch New Post")
                    Task{await fetchPosts()}
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
            // Implementing Pagination
            if let paginationDoc {
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20) //limit post's on page
            } else {
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 20)
            }
            // New Query for UID Based Document Fetch
            // Simply Filter the Posts Which not belongs to this UID
            if basedOnUID{
                query = query
                    .whereField("userUID", isEqualTo: uid)
            }
           
            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
            await MainActor.run(body: {
                posts.append(contentsOf: fetchedPosts)
                paginationDoc = docs.documents.last
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
