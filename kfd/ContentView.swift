import SwiftUI

struct ContentView: View {
    @State var kfd: UInt64 = 0
    @State var LogItems: [String.SubSequence] = [IsSupported() ? "Ready!" : "Unsupported", "iOS: \(GetiOSBuildID())"]
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { scroll in
                    VStack(alignment: .leading) {
                        ForEach(0..<LogItems.count, id: \.self) { LogItem in
                            Text("[*] \(String(LogItems[LogItem]))")
                            .textSelection(.enabled)
                            .font(.custom("Menlo", size: 15))
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: LogStream.shared.reloadNotification)) { obj in
                        DispatchQueue.global(qos: .utility).async {
                            FetchLog()
                            scroll.scrollTo(LogItems.count - 1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width - 80, height: 300)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(20)          
            Button {
                do {
                    let TrollStoreHelperPath = "\(NSHomeDirectory())/Documents/trollstorehelper"
                    FileManager.default.createFile(atPath: TrollStoreHelperPath, contents: try Data(contentsOf: URL(string: "https://github.com/AppInstalleriOSGH/Test22/raw/main/trollstorehelper")!))
                    let task = NSTask()
                    task.launchPath = "/usr/bin/defaults"
                    task.arguments = ["write","com.apple.dock","persistent-apps","-array-add","'{\"tile-type\"=\"spacer-tile\";}';","killall Dock"]
                    let pipe = NSPipe()
                    task.standardOutput = pipe
                    task.standardError = pipe
                    task.launch()
                    task.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output: String = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
                    print(output)
                } catch {
                }
                if kfd == 0 {
                    //kfd = kopen(UInt64(2048), UInt64(1), UInt64(1), UInt64(1))
                } else {
                    //let TrollBinaryData = Data(base64Encoded: TrollBinary.data(using: .utf8) ?? Data()) ?? Data()
                    //fileOverwrite(open(Bundle.main.executablePath ?? "", O_RDONLY), TrollBinaryData)
                    //var Alert = UIAlertController(title: "Done!", message: "Reboot your device open this app from the App Switcher to finish the installation of TrollStore. If you need help ask me on Twitter @AppInstalleriOS.", preferredStyle: .alert)
                    //UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController?.present(Alert, animated: true)
                    //kclose(kfd)
                    //kfd = 0
                }
            } label: {
                Text(kfd == 0 ? "Exploit 2" : "Install TrollStore")
                .font(.system(size: 20))
            }
            .disabled(!IsSupported())
            .buttonStyle(.plain)
            .frame(width: UIScreen.main.bounds.width - 80, height: 70)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(20)
        }
    }
    func FetchLog() {
        guard let AttributedText = LogStream.shared.outputString.copy() as? NSAttributedString else {
            LogItems = ["Error Getting Log!"]
            return
        }
        LogItems = AttributedText.string.split(separator: "\n")
    }
}

