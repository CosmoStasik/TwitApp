//
//  CreateNewPost.swift
//  TwitApp
//
//  Created by Stanislav Sobolevsky on 26.12.22.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct CreateNewPost: View {
    ///- Callbacks
    var onPost: (Post) ->()
    // - Post Properties
    @State private var postText: String = ""
    @State private var postImageData: Data?
    //- Stored USer Data from UserDefaults(AppStorage)
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    //- View Prop Properties
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem? //for native image Picker
    @FocusState private var showKeyboards: Bool // @FocusState is used to toggle the keyboard on and off
    var body: some View {
        VStack {
            HStack {
                Menu {
                    Button("Cancel", role: .destructive){
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.black)
                }
                .hAlign(.leading)
                
                Button(action: createPost) {
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical,6)
                        .background(.black, in: Capsule())
                    
                }
                .disableWithOpacity(postText == "")

            }
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background{
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    TextField("What happening", text: $postText, axis: .vertical)
                        .focused($showKeyboards)
                    
                    if let postImageData, let image = UIImage(data: postImageData) {
                        GeometryReader{
                            let size = $0.size
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            //- Delete Button
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            self.postImageData = nil
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .fontWeight(.bold)
                                            .tint(.red)
                                    }
                                    .padding(10)

                                }
                        }
                        .clipped()
                        .frame(height: 220)
                    }
                }
                .padding(15)
            }
            Divider() // снизу пространство
            
            HStack{
                Button {
                    showImagePicker.toggle()
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                }
                .hAlign(.leading)
                
                Button("Done") {
                    showKeyboards = false
                }

            }
            .foregroundColor(.black)
            .padding(.horizontal,15)
            .padding(.vertical,10)
            
        }
        .vAlign(.top)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { newValue in
            if let newValue {
                Task {
                    // Сжатие
                    if let rawImageData = try? await newValue.loadTransferable(type: Data.self),let image = UIImage(data: rawImageData), let compressedImageData = image.jpegData(compressionQuality: 0.5){
                        /// UI must be done on Main Thread
                        await MainActor.run(body: {
                            postImageData = compressedImageData
                            photoItem = nil
                        })
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
            // Loading View
        .overlay {
            LoadingView(show: $isLoading)
        }
        
    }
    
    // MARK: Post Content to FireBase
    func createPost() {
        isLoading = true
        showKeyboards = false
        Task {
            do {
                guard let profileURL = profileURL else {return}
                //Step 1 Uploading Image if any
                
                let imageReferenceID = "\(userUID)\(Date())"
                let storageRef = Storage.storage().reference().child("Post_Images").child(imageReferenceID)
                if let postImageData {
                    let _ = try await storageRef.putDataAsync(postImageData)
                    let downloadURL = try await storageRef.downloadURL()
                    // Step 3: Create Post Object With Image id and URL
                    let post = Post(text: postText, imageURL: downloadURL, imageReferenceID: imageReferenceID, userName: userName, userUID: userUID, userProfileURL: profileURL)
                    try await createDocimentAtFirebase(post)
                } else {
                    /// Step 2 : Directly Post Text Data to FireBase( since there is no Images Present)
                    let post = Post(text: postText, userName: userName, userUID: userUID, userProfileURL: profileURL)
                    try await createDocimentAtFirebase(post)
                }
                
            } catch {
                await setError(error)
                
            }
        }
    }
    
    func createDocimentAtFirebase(_ post: Post)async throws {
        // Document to Firebase Firestore
        let doc = Firestore.firestore().collection("Posts").document()
        let _ = try doc.setData(from: post, completion: { error in
            if error == nil {
                // Post Success Stored at Firebase
                isLoading = false
                var updatePost = post
                updatePost.id = doc.documentID
                onPost(updatePost)
                dismiss()
            }
        })
    }
    
    // MARK: Displaing Errors as Alert
    func setError(_ error: Error)async {
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct CreateNewPost_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewPost{_ in
            
        }
    }
}
