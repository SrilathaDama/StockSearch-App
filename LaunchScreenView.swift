import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        Image("launch-screen")
            .resizable()
            .scaledToFit()
            .edgesIgnoringSafeArea(.all)  // Make the image fill the entire screen
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
    }
}
