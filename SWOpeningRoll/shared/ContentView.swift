import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var worldManager : WorldManager

    var body: some View {
        VStack {
          MetalView()
        }//.padding()
    }
}
