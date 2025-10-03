import SwiftUI

@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            TestContentView()
        }
    }
}

struct TestContentView: View {
    var body: some View {
        VStack {
            Text("Hello, iPhone!")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("If you see this, the simulator is working!")
                .font(.body)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct TestContentView_Previews: PreviewProvider {
    static var previews: some View {
        TestContentView()
    }
}