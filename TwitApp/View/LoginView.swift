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
        // MARK: Register View VIA Sheets
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        // MARK: Display Alert
        .alert(errorMessage ,isPresented: $showError, actions: {})
    }
    
    func loginUser() {
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
    
    func resetPassword() {
        Task {
            do {
                // With the help of Swift Concurrency AUth can be done with Single line
                try await Auth.auth().signIn(withEmail: emailId, password: password)
                print("User found")
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
        })
    }
}
// MARK: Register View
struct RegisterView: View {
    //MARK: User Details
    @State var emailId: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilePicData: Data?
    // MARK: View Properties
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    // MARK: UserDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    var body: some View {
        VStack(spacing: 10) {
            Text("Let's Register\nAccount")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Hello user, have a wondeful journey")
                .font(.title3)
                .hAlign(.leading)
            
            // MARK: For smaller size optimization
            ViewThatFits {
                ScrollView(.vertical, showsIndicators: false) {
                    helperView()
                }
                helperView()
            }
            
            // MARK: Register Button
            HStack{
                Text("Already have an account")
                    .foregroundColor(.gray)
                    
                Button("Login now") {
                    dismiss()
                }
                .fontWeight(.medium)
                .foregroundColor(.blue)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { newValue in
            // MARK: Extracting UIImage From PhotoItem
            if let newValue {
                Task{
                    do {
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else {return}
                        // MARK: UI must be updated on maim thread
                        await MainActor.run(body: {
                            userProfilePicData = imageData
                        })
                    } catch {}
                }
            }
        }
        
        // MARK: Displaying Alert
        
        .alert(errorMessage, isPresented: $showError, actions: {})
            
        }
    @ViewBuilder
    func helperView() -> some View {
        VStack(spacing: 12) {
            ZStack{
                if let userProfilePicData,let image = UIImage(data: userProfilePicData){
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image("h")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top,25)
            
            TextField("Username", text: $userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                
            
            TextField("Email", text: $emailId)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            SecureField("Password", text: $password)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("About u", text: $userBio, axis: .vertical)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Bio Link (Optional)", text: $userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            
            Button (action: registerUser) {
                // MARK: Login Button
                Text("Sign up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.blue)
            }
            .disableWithOpacity(userName == "" || userBio == "" || emailId == "" || password == "" || userProfilePicData == nil)
            .padding(.top,15)

        }
    }
    
    func registerUser() {
        Task {
            do {
                // MARK:  Step 1: create firebase ac
                try await Auth.auth().createUser(withEmail: emailId, password: password)
                // MARK:  Step 2: Uploading Profile Photo into firebase storage
                guard let userUID = Auth.auth().currentUser?.uid else {return}
                guard let imageData = userProfilePicData else {return}
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                // MARK: Step 3: Donload photo URL
                let downloadUrl = try await storageRef.downloadURL()
                //MARK: Step 4: Creating a user firebasestore object
                let user = User(username: userName, userBio: userBio, userBioLink: userBioLink, userUID: userUID, userEmail: emailId, userProfileURL: downloadUrl)
                    // MARK: step 5: Saving User Doc into Firestore DataBase
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: { error in
                    if error == nil {
                        // MARK: print saved success
                        print("Saved success")
                        userNameStored = userName
                        self.userUID = userUID
                        profileURL = downloadUrl
                        logStatus = true
                    }
                })
            } catch {
                // MARK: Deleting created ac in case
                try await Auth.auth().currentUser?.delete() // ignore this lile because this will delete the already exiting user, mistakenly added
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
        })
    }
    
    }


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
        //RegisterView()
    }
}

//MARK: View Extention
extension View{
    // MARK: Disabling with Opacity
    func disableWithOpacity(_ condition: Bool) -> some View {
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1)
    }
    
    
    func hAlign(_ aligment: Alignment) -> some View {
        self
            .frame(maxWidth: .infinity, alignment:  aligment)
    }
    
    func vAlign(_ aligment: Alignment) -> some View {
        self
            .frame(maxHeight: .infinity, alignment:  aligment)
    }
    
    // MARK: Custom Border View With Padding, рамка
    func border(_ width: CGFloat,_ color: Color) -> some View {
        self
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(color, lineWidth: width)
            }
    }
    
    // MARK: Custom Fill View With Padding
    func fillView(_ color: Color) -> some View {
        self
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color)
            }
    }
}
