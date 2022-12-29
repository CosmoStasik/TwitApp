//
//  ContentView.swift
//  TwitApp
//
//  Created by Stanislav Sobolevsky on 15.12.22.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    var body: some View {
     // MARK: Redirecting user based on log status
       
        if logStatus{
            MainView()
        } else {
             LoginView()
        }
//        CreateNewPost { _ in
//
//        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
