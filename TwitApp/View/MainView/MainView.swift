//
//  MainView.swift
//  TwitApp
//
//  Created by Stanislav Sobolevsky on 15.12.22.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        // MARK: TabView with resent posts and profile tabs
        TabView {
            PostsView()
                .tabItem {
                    Image(systemName: "rectangle.on.rectangle.angled")
                    Text("Post")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }

        }
        // Changing tab Labl Tint
        .tint(.black)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
