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

func IsSupported() -> Bool {
    let SupportedVersions = ["19A346", "19A348", "19A404", "19B75", "19C56", "19C63", "19D50", "19D52", "19E241", "19E258", "19F77", "19G71", "19G82", "19H12", "19H117", "19H218", "19H307", "19H321", "19H332", "19H349", "20A362", "20A371", "20A380", "20A392", "20B82", "20B101", "20B110", "20C65", "20D47", "20D67", "20E247", "20E252", "20F66", "20G5026e", "20G5037d", "20F5028e", "20F5039e", "20F5050f", "20F5059a", "20F65", "20E5212f", "20E5223e", "20E5229e", "20E5239b", "20E246", "20D5024e", "20D5035i", "20C5032e", "20C5043e", "20C5049e", "20C5058d", "20B5045d", "20B5050f", "20B5056e", "20B5064c", "20B5072b", "20B79"]
    return SupportedVersions.contains(GetiOSBuildID())
}

func GetiOSBuildID() -> String {
    NSDictionary(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist")!.value(forKey: "ProductBuildVersion") as! String
}

//From https://github.com/Odyssey-Team/Taurine/blob/main/Taurine/app/LogStream.swift
//Code from Taurine https://github.com/Odyssey-Team/Taurine under BSD 4 License
class LogStream {
    static let shared = LogStream()
    private(set) var outputString: NSMutableAttributedString = NSMutableAttributedString()
    public let reloadNotification = Notification.Name("LogStreamReloadNotification")
    private(set) var outputFd: [Int32] = [0, 0]
    private(set) var errFd: [Int32] = [0, 0]
    private let readQueue: DispatchQueue
    private let outputSource: DispatchSourceRead
    private let errorSource: DispatchSourceRead
    init() {
        readQueue = DispatchQueue(label: "org.coolstar.sileo.logstream", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        guard pipe(&outputFd) != -1,
            pipe(&errFd) != -1 else {
                fatalError("pipe failed")
        }
        let origOutput = dup(STDOUT_FILENO)
        let origErr = dup(STDERR_FILENO)
        setvbuf(stdout, nil, _IONBF, 0)
        guard dup2(outputFd[1], STDOUT_FILENO) >= 0,
            dup2(errFd[1], STDERR_FILENO) >= 0 else {
                fatalError("dup2 failed")
        }
        outputSource = DispatchSource.makeReadSource(fileDescriptor: outputFd[0], queue: readQueue)
        errorSource = DispatchSource.makeReadSource(fileDescriptor: errFd[0], queue: readQueue)
        outputSource.setCancelHandler {
            close(self.outputFd[0])
            close(self.outputFd[1])
        }
        errorSource.setCancelHandler {
            close(self.errFd[0])
            close(self.errFd[1])
        }
        let bufsiz = Int(BUFSIZ)
        outputSource.setEventHandler {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
            defer { buffer.deallocate() }
            let bytesRead = read(self.outputFd[0], buffer, bufsiz)
            guard bytesRead > 0 else {
                if bytesRead == -1 && errno == EAGAIN {
                    return
                }
                self.outputSource.cancel()
                return
            }
            write(origOutput, buffer, bytesRead)
            let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
            array.withUnsafeBufferPointer { ptr in
                let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                let textColor = UIColor.white
                let substring = NSMutableAttributedString(string: str, attributes: [NSAttributedString.Key.foregroundColor: textColor])
                self.outputString.append(substring)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: self.reloadNotification, object: nil)
                }
            }
        }
        errorSource.setEventHandler {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
            defer { buffer.deallocate() }
            let bytesRead = read(self.errFd[0], buffer, bufsiz)
            guard bytesRead > 0 else {
                if bytesRead == -1 && errno == EAGAIN {
                    return
                }
                self.errorSource.cancel()
                return
            }
            write(origErr, buffer, bytesRead)
            let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
            array.withUnsafeBufferPointer { ptr in
                let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                let textColor = UIColor(red: 219/255.0, green: 44.0/255.0, blue: 56.0/255.0, alpha: 1)
                let substring = NSMutableAttributedString(string: str, attributes: [NSAttributedString.Key.foregroundColor: textColor])
                self.outputString.append(substring)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: self.reloadNotification, object: nil)
                }
            }
        }
        outputSource.resume()
        errorSource.resume()
    }
}