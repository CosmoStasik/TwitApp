//
//  LoginView.swift
//  TwitApp
//
//  Created by Stanislav Sobolevsky on 15.12.22.
//

import SwiftUI
import PhotosUI // For Native SwiftUI image Picker
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct LoginView: View {
    //MARK: User Details
    @State var emailId: String = ""
    @State var password: String = ""
    // MARK: View Propetties
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    // MARK: User Defaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    var body: some View {
        VStack(spacing: 10) {
            Text("Sign you in")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Welcome Back, \nYou have been missed")
                .font(.title3)
                .hAlign(.leading)
            
            VStack(spacing: 10) {
                TextField("Email", text: $emailId)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top,25)
                
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                Button("Reset password?", action: resetPassword)
                    .font(.callout)
                    .fontWeight(.medium)
                    .hAlign(.trailing)
                
                Button (action: loginUser) {
                    // MARK: Login Button
                    Text("Sign in")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.blue)
                }
                .padding(.top,15)

            }
            
            // MARK: Register Button
            HStack{
                Text("Don't have an account")
                    .foregroundColor(.black)
                    
                Button("Register now") {
                    createAccount.toggle()
                }
                .fontWeight(.medium)
                .foregroundColor(.blue)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        // MARK: Register View VIA Sheets
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        // MARK: Display Alert
        .alert(errorMessage ,isPresented: $showError, actions: {})
    }
    
    func loginUser() {
        isLoading = true
        closeKeyBoard()
        Task {
            do {
                // With the help of Swift Concurrency AUth can be done with Single line
                try await Auth.auth().signIn(withEmail: emailId, password: password)
                print("User found")
                try await fetchUser()
            } catch {
                await setError(error)
            }
        }
    }
    // MARK: if user if found then fetching user data from Firestore
    func fetchUser()async throws {
        guard let userUID = Auth.auth().currentUser?.uid else {return}
        let user = try await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self)
        // MARK: UI updating must be run on main thread
        await MainActor.run(body: {
            // MARK: setting userdefaults data and chaning Apps Auth Status
            self.userUID = userUID
            userNameStored = user.username
            profileURL = user.userProfileURL
            logStatus = true
        })
    }
    
    func resetPassword() {
        Task {
            do {
                // With the help of Swift Concurrency AUth can be done with Single line
                try await Auth.auth().sendPasswordReset(withEmail: emailId)
                print("Link Sent")
            } catch {
                await setError(error)
            }
        }
    }
    
    // MARK: Displaing Errors VIA Alert
    func setError(_ error: Error) async {
        // MARK: UI must be updated on main thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}



struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
        
    }
}


