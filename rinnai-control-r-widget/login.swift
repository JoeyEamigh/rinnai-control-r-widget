//
//  login.swift
//  iOS
//
//  Created by Joey Eamigh on 4/20/22.
//

import SwiftUI

struct LoginPage: View {
  @StateObject var router: ViewRouter
  @State var loading = false
  
  var body: some View {
    ZStack {
      Color("Background").edgesIgnoringSafeArea(.all)
      VStack {
        WelcomeText()
        LoginForm(loading: $loading, router: router)
      }
      if (loading) {
        Loader()
      }
    }
  }
}

struct Loader: View {
  var body: some View {
    ZStack {
      Color("Background").edgesIgnoringSafeArea(.all)
      CapsuleSpacing()
    }.padding()
  }
}

struct WelcomeText: View {
  var body: some View {
    VStack {
      Text("Enter your").font(.title).fontWeight(.semibold)
      Text("Rinnai Control-R").foregroundColor(.red).fontWeight(.bold).font(.title)
      Text(" email address").font(.title).fontWeight(.semibold)
    }.padding(.bottom, 5.0)
    Text("This will *only* be sent to Rinnai").font(.footnote).padding(.bottom, 80.0)
  }
}

struct LoginForm: View {
  @State var username: String = ""
  @State var error: String?
  @Binding var loading: Bool
  @StateObject var router: ViewRouter
  
  func getDevices() async {
    print("validating...")
    if error != nil { error = nil }
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    if !emailPred.evaluate(with: username) {
      error = "Please enter a valid email address"
      return
    }
    print ("email is valid")
    loading = true
    do {
      let success = try await Rinnai(username: username).getDevices()
      print("Success: \(success)")
      if (!success) {
        error = "Failed to fetch devices"
        loading = false
        return
      }
      KeychainHelper.i.save(username, service: "email", account: "rinnai")
      Widgeter.refresh()
      DispatchQueue.main.async {
        router.currentPage = .devices
      }
      loading = false
    } catch {
      self.error = "Failed to fetch devices"
      loading = false
    }
  }
  
  var body: some View {
    VStack {
      TextField("Rinnai Email Address", text: $username).padding().background(Color("AccentColor")).cornerRadius(5.0).keyboardType(.emailAddress).disableAutocorrection(true).autocapitalization(.none)
      if error != nil {
        Text(error!).foregroundColor(Color.red).font(.footnote)
      }
      Button(action: {Task {await getDevices()}}) {
        Text("Get Devices!").font(.headline)
          .foregroundColor(.white)
          .padding()
          .frame(width: 160, height: 50)
          .background(Color.blue)
          .cornerRadius(10.0).padding(.top, 20)
      }
    }.padding().padding(.bottom, 80)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      LoginPage(router: ViewRouter()).preferredColorScheme(.light)
      LoginPage(router: ViewRouter()).environment(\.colorScheme, .dark)
    }
  }
}
