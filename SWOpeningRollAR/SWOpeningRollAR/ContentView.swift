import SwiftUI

struct ContentView: View {

    @EnvironmentObject var worldManager: WorldManager

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {

        if verticalSizeClass == .compact {
            HStack {
                MetalView().padding()
            }

        } else {
            VStack(alignment: .center) {
                MetalView().padding()
            }
        }
    }
}
