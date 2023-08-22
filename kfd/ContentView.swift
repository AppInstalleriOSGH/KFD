/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

import SwiftUI

struct ContentView: View {
    @State var kfd: UInt64 = 0
    @State var LogItems: [String.SubSequence] = [IsSupported() ? "Ready!" : "Unsupported", "iOS: \(GetiOSBuildID())"]
    @State var ShowFileManager = false
    @State var ProfileToRemoveName = ""
    var body: some View {
        if ShowFileManager {
            NavigationView {
                FilesView(Path: "/var", ShowFileManager: $ShowFileManager)
            }
        } else {
            VStack {
                TextField("Name of Profile to Make (Un)Removable", text: $ProfileToRemoveName)
                .padding(.horizontal, 10)
                .frame(width: UIScreen.main.bounds.width - 80, height: 50)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(20)
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
                    if kfd == 0 {
                        kfd = kopen(UInt64(2048), UInt64(1), UInt64(1), UInt64(1))
                        if !ProfileToRemoveName.isEmpty {
                            print("⬇️ TESTING ⬇️")
                            let ProfilesPath = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles"
                            for Profile in contentsOfDirectory(ProfilesPath).filter({$0.hasPrefix("profile-")}) {
                                if let ProfileData = dataFromFileCopy(ProfilesPath, Profile) {
                                    do {
                                        if let Dictionary = try PropertyListSerialization.propertyList(from: ProfileData, format: nil) as? NSDictionary {
                                            let MutableDictionary: NSMutableDictionary = NSMutableDictionary(dictionary: Dictionary)
                                            let ProfileName = (MutableDictionary.value(forKey: "PayloadDisplayName") as? String) ?? "error: no name?"
                                            print(ProfileName)
                                            if ProfileName == ProfileToRemoveName || ProfileToRemoveName == "all" {
                                                let ProfileWasLocked = (MutableDictionary.allKeys as! [String]).contains("ProfileWasLocked") ? MutableDictionary.value(forKey: "ProfileWasLocked") as! Bool : false
                                                print("\(ProfileName): \(ProfileWasLocked ? "Unremovable" : "Removable")")
                                                MutableDictionary.setValue(!ProfileWasLocked, forKey: "ProfileWasLocked")
                                                let XMLData = try PropertyListSerialization.data(fromPropertyList: MutableDictionary, format: .xml, options: 0)
                                                writeDataToFile(XMLData, ProfilesPath, Profile)
                                                print("Tried to write \(!ProfileWasLocked ? "true" : "false") to ProfileWasLocked for profile \(ProfileName)")
                                            }
                                        } else {
                                            print("Invalid Plist")
                                        }
                                    } catch {
                                        print(error)
                                    }
                                } else {
                                    print("Failed to read \(Profile), reboot and try again!")
                                }
                            }
                        }
                    } else {
                        let vnode = getVnodeAtPathByChdir("/Applications".cString())
                        funVnodeIterateByVnode(vnode)
                        //procNameFindOffsets()
                        kclose(kfd)
                        kfd = 0
                    }
                } label: {
                    Text(kfd == 0 ? "Exploit (2)" : "Finish")
                    .font(.system(size: 20))
                }
                .disabled(!IsSupported())
                .buttonStyle(.plain)
                .frame(width: UIScreen.main.bounds.width - 80, height: 70)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(20)
                if kfd != 0 {
                    VStack {
                        Button("Show File Manager") {
                            ShowFileManager = true
                        }
                        .font(.system(size: 20))
                        Button("Test") {
                            funVnodeIterateByVnode(getVnodeAtPathByChdir("/var/db/MobileIdentityData".cString()))
                        }
                        .font(.system(size: 20))
                    }
                }
            }
            .onChange(of: ShowFileManager) { ShowFileManager in
                if !ShowFileManager {
                    DispatchQueue.global(qos: .utility).async {
                        FetchLog()
                    }
                }
            }
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

extension String {
    func cString() -> UnsafeMutablePointer<CChar>? {
        return CStringFromNSString(self)
    }
}

struct FilesView: View {
    @State var Path: String
    @Binding var ShowFileManager: Bool
    @State var Items: [String] = []
    @State var SearchString = ""
    var body: some View {
        Form {
            ForEach(Items.filter({SearchString.isEmpty ? true : $0.contains(SearchString)}), id: \.self) { File in
                if isDirectory("\(Path)/\(File)") {
                    NavigationLink {
                        FilesView(Path: "\(Path)/\(File)", ShowFileManager: $ShowFileManager)
                    } label: {
                        Label(File, systemImage: "folder.fill")
                    }
                    .disabled("\(Path)/\(File)" == "/var/root")
                } else {
                    NavigationLink {
                        TXTView(Path: Path, File: File)
                    } label: {
                        Label(File, systemImage: "doc")
                    }
                }
            }
            .onDelete { IndexSet in
                let FileName = Items[IndexSet.first!]
                let Alert = UIAlertController(title: "Delete \(FileName)", message: "Are you sure?", preferredStyle: .alert)
                Alert.addAction(UIAlertAction(title: "No", style: .cancel))
                Alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
                    //Make removable?
                    if isDirectory("\(Path)/\(FileName)") {
                        funVnodeChown(getVnodeAtPathByChdir("\(Path)/\(FileName)".cString()), 501, 501)
                    } else {
                        funVnodeChown(getVnodeAtPath("\(Path)/\(FileName)".cString()), 501, 501)
                    }
                    if let Error = removeFile(Path, FileName) {
                        let ErrorAlert = UIAlertController(title: "Error removing \(FileName)", message: Error, preferredStyle: .alert)
                        ErrorAlert.addAction(UIAlertAction(title: "Done", style: .cancel))
                        UIApplication.shared.windows.last?.rootViewController?.present(ErrorAlert, animated: true)
                        //Items.insert(FileName, at: IndexSet.first!)
                    }
                }))
                UIApplication.shared.windows.last?.rootViewController?.present(Alert, animated: true)
            }
        }
        .navigationTitle(URL(fileURLWithPath: Path).lastPathComponent)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    ShowFileManager = false
                } label: {
                    Text("Done")
                }
            }
        }
        .searchable(text: $SearchString, placement: .automatic)
        .onAppear {
            Items = contentsOfDirectory(Path)
        }
    }
}

struct TXTView: View {
    @State var Path: String
    @State var File: String
    var TextString: String {
        if isFileReadable(Path, File) {
            if let FileData = dataFromFileCopy(Path, File) {
                if let XMLPlist = GetXMLFromPlistData(FileData) {
                    return XMLPlist
                } else {
                    if let FileString = String(data: FileData, encoding: .utf8) {
                        return FileString
                    } else {
                        return FileData.base64EncodedString()
                    }
                }
            } else {
                return "Error: No File Data"
            }
        } else {
            return "Error: File Not Readable"
        }
    }
    var body: some View {
        ScrollView {
            Text(TextString)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(File)
        .navigationBarTitleDisplayMode(.inline)
    }
}

func GetXMLFromPlistData(_ PlistData: Data) -> String? {
    do {
        if let Dictionary = try PropertyListSerialization.propertyList(from: PlistData, format: nil) as? NSDictionary {
            let XMLData = try PropertyListSerialization.data(fromPropertyList: Dictionary, format: .xml, options: 0)
            return String(data: XMLData, encoding: .utf8)
        } else {
            return nil
        }
    } catch {
        print(error)
        return nil
    }
}

func isDirectory(_ Path: String) -> Bool {
    var isDirectory: ObjCBool = false
    FileManager.default.fileExists(atPath: Path, isDirectory: &isDirectory)
    return isDirectory.boolValue
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
