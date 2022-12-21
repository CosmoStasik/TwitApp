//
//  ProfileView.swift
//  TwitApp
//
//  Created by Stanislav Sobolevsky on 15.12.22.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct ProfileView: View {
    // MARK: My Profile Data
    @State private var myProfile: User?
    @AppStorage("log_status") var logStatus: Bool = false
    // MARK: Error Message / View Properties
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading:Bool = false
    var body: some View {
        NavigationStack{
            VStack{
                if let myProfile{
                   ReusProfileContent(user: myProfile)
                        .refreshable {
                            // MARK: Refresh User Data / tip loading
                            self.myProfile = nil
                            await fetchUserData()
                        }
                } else {
                    ProgressView()
                }
//            ScrollView(.vertical, showsIndicators: false) {
//                if let myProfile{
//                    Text(myProfile.username)
//                }
            }
          
            .navigationTitle("My Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            // MARK: Two Actions
                            // 1. Logout
                            //2. Delete ac
                            Button("Logout", action: logOutUser)
                            
                            
                            Button("Delete Account", role: .destructive, action: deleteAccount)
                            
                        } label: {
                            Image(systemName: "ellipsis.bubble")
                                .rotationEffect(.init(degrees: 90))
                                .tint(.black)
                                .scaleEffect(0.8)
                        }
                    }
                }
        }
        .overlay {
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError) {
            
        }
        .task {
            //This Modifer is like onAppear
            //so fetching for the first Time Only
            if myProfile != nil {return}
            // MARK: Initial Fetch
            await fetchUserData()
        }
    }
    
    //MARK: Fetching User Data
    func fetchUserData()async {
        guard let userUID = Auth.auth().currentUser?.uid else {return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else {return}
        await MainActor.run(body: {
            myProfile = user
        })
    }
    
    
    // MARK: Logging User Out
    
    func logOutUser() {
        try? Auth.auth().signOut()
        logStatus = false
    }
    // Mark: Deleting User Entire Account
    func deleteAccount(){
        isLoading = true
        Task {
            do{
                guard let userUID = Auth.auth().currentUser?.uid else {return}
                // Step 1: First Deleting Profile Image From Storage
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                // Step 2: Deleting FireStore User Document
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                // Final step: Deleting Auth Account and Setting Log Status to False
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            } catch {
               await setError(error)
            }
        }
    }
    
    // MARK: Settings Errors
    
    func setError(_ error: Error)async{
        //MARK: UI must be run on maim thread
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
