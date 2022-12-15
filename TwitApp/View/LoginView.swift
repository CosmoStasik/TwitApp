//
//  LoginView.swift
//  TwitApp
//
//  Created by Stanislav Sobolevsky on 15.12.22.
//

import SwiftUI
import PhotosUI // For Native SwiftUI image Picker
import Firebase

struct LoginView: View {
    //MARK: User Details
    @State var emailId: String = ""
    @State var password: String = ""
    // MARK: View Propetties
    @State var createAccount: Bool = false
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
                
                Button("Reset password?", action: {})
                    .font(.callout)
                    .fontWeight(.medium)
                    .hAlign(.trailing)
                
                Button {
                    
                } label: {
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
                    Image("NullProfile")
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
            
            
            Button {
                
            } label: {
                // MARK: Login Button
                Text("Sign up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.blue)
            }
            .padding(.top,15)

        }
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
