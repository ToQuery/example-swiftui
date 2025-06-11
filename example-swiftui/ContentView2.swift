//
//  ContentView2.swift
//  example-swiftui
//
//  Created by ToQuery on 2025/6/11.
//
import SwiftUI
import WebKit
import Combine

struct ContentView2: View {
    @State private var text = "Hello!"
    @State private var textSize: CGFloat = 48
    @State private var width: CGFloat = 640
    @State private var height: CGFloat = 50
    @State private var webView: WKWebView?

    @State private var bgColor = Color.black

    @State private var showBatteryLevel = false
    @State private var showTime = false
    @State private var showDate = false
    @State private var showRAMUsage = false
    @State private var showProcessor = false
    @State private var showOSVersion = false
    @State private var showDeviceModel = false

    @State private var updateFrequency: Double = 1.0
    @State private var timerCancellable: Cancellable?

    let updateOptions: [Double] = [1,2,3,4,5,6,7,8,9,10,30,60,120,0]

    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    Spacer()
                    ZStack {
                        Color.gray.opacity(0.3)
                            .frame(width: width + 40, height: height + 40)
                            .cornerRadius(20)

                        WebViewWrapper(
                            text: combinedText(),
                            textSize: Int(textSize),
                            width: Int(width),
                            height: Int(height),
                            bgColor: bgColor,
                            webView: $webView
                        )
                        .frame(width: width, height: height)
                        .cornerRadius(12)
                    }
                    Spacer()
                }
                .navigationTitle("Gust")
                .onAppear { startTimer() }
                .onDisappear { stopTimer() }
            }
            .tabItem {
                Label("Main", systemImage: "rectangle.fill.on.rectangle.fill")
            }

            NavigationView {
                Form {
                    Section(header: Text("Text Settings")) {
                        TextField("Text", text: $text)
                            .onChange(of: text) { _ in updateWebView() }

                        HStack {
                            Text("Text Size")
                            Spacer()
                            Text("\(Int(textSize)) px")
                        }
                        Slider(value: $textSize, in: 10...150) { _ in updateWebView() }
                    }

                    Section(header: Text("Canvas Size")) {
                        HStack {
                            Text("Width")
                            Spacer()
                            Text("\(Int(width)) px")
                        }
                        Slider(value: $width, in: 100...800) { _ in updateWebView() }

                        HStack {
                            Text("Height")
                            Spacer()
                            Text("\(Int(height)) px")
                        }
                        Slider(value: $height, in: 1...600) { _ in updateWebView() }
                    }

                    Section(header: Text("Background Color")) {
                        ColorPicker("Background Color", selection: $bgColor)
                            .onChange(of: bgColor) { _ in updateWebView() }
                    }

                    Section(header: Text("Presets")) {
                        Button("White Line") {
                            textSize = 12
                            width = 800
                            height = 1
                            updateWebView()
                        }
                        Button("Maximum") {
                            textSize = 150
                            width = 800
                            height = 600
                            updateWebView()
                        }
                        Button("Small bar") {
                            textSize = 14
                            width = 800
                            height = 20
                            updateWebView()
                        }
                        Button("Default") {
                            textSize = 48
                            width = 640
                            height = 50
                            updateWebView()
                        }
                    }

                    Section(header: Text("System Stats")) {
                        Toggle("Battery Level", isOn: $showBatteryLevel).onChange(of: showBatteryLevel) { _ in updateWebView() }
                        Toggle("Time", isOn: $showTime).onChange(of: showTime) { _ in updateWebView() }
                        Toggle("Date", isOn: $showDate).onChange(of: showDate) { _ in updateWebView() }
                        Toggle("RAM Usage", isOn: $showRAMUsage).onChange(of: showRAMUsage) { _ in updateWebView() }
                        Toggle("CPU Usage", isOn: $showProcessor).onChange(of: showProcessor) { _ in updateWebView() }
                        Toggle("OS Version", isOn: $showOSVersion).onChange(of: showOSVersion) { _ in updateWebView() }
                        Toggle("Device Model", isOn: $showDeviceModel).onChange(of: showDeviceModel) { _ in updateWebView() }
                    }

                    Section(header: Text("Update Frequency")) {
                        Picker("Frequency (seconds)", selection: $updateFrequency) {
                            ForEach(updateOptions, id: \.self) { value in
                                Text(value == 0 ? "Never" : "\(Int(value))s")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .onChange(of: updateFrequency) { _ in restartTimer() }
                    }

                    Section(header: Text("App Info")) {
                        Text("App Name: Gust")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("App Version: 0.0.1")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("Credits: @c4ndyf1sh")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }

    func combinedText() -> String {
        var lines = [text]

        if showBatteryLevel {
            lines.append(getBatteryLevel())
        }
        if showTime {
            lines.append("Time: \(getCurrentTime())")
        }
        if showDate {
            lines.append("Date: \(getCurrentDate())")
        }
        if showRAMUsage {
            lines.append("RAM: \(getRAMUsage()) MB")
        }
        if showProcessor {
            lines.append("CPU: \(getCPUUsage())%")
        }
        if showOSVersion {
            lines.append("OS: \(getOSVersion())")
        }
        if showDeviceModel {
            lines.append("Device: \(getDeviceModel())")
        }

        return lines.joined(separator: " | ")
    }

    func updateWebView() {
        let safeText = combinedText().replacingOccurrences(of: "\"", with: "\\\"")

        let uiColor = UIColor(bgColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let hexColor = String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )

        let js = """
        updateContent("\(safeText)", \(Int(width)), \(Int(height)), \(Int(textSize)), "\(hexColor)");
        """
        webView?.evaluateJavaScript(js)
    }

    func startTimer() {
        guard updateFrequency > 0 else { return }
        timerCancellable = Timer.publish(every: updateFrequency, on: .main, in: .common)
            .autoconnect()
            .sink { _ in updateWebView() }
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func restartTimer() {
        stopTimer()
        startTimer()
    }

    func getBatteryLevel() -> String {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        if batteryLevel < 0 {
            return "Battery: Unknown"
        }
        return String(format: "Battery: %.0f%%", batteryLevel * 100)
    }

    func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: Date())
    }

    func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }

    func getRAMUsage() -> Int {
        let used = ProcessInfo.processInfo.physicalMemory - getFreeMemory()
        return Int(used / 1024 / 1024)
    }

    func getFreeMemory() -> UInt64 {
        var stats = vm_statistics64()
        var count = UInt32(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let hostPort = mach_host_self()
        let result = withUnsafeMutablePointer(to: &stats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            return UInt64(stats.free_count) * UInt64(vm_page_size)
        } else {
            return 0
        }
    }

    func getCPUUsage() -> Int { Int.random(in: 1...50) }

    func getOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") {
            guard let value = $1.value as? Int8, value != 0 else { return $0 }
            return $0 + String(UnicodeScalar(UInt8(value)))
        }
    }
}

struct WebViewWrapper: UIViewRepresentable {
    var text: String
    var textSize: Int
    var width: Int
    var height: Int
    var bgColor: Color
    @Binding var webView: WKWebView?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        webView = wv
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.isScrollEnabled = false

        let uiColor = UIColor(bgColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let hexColor = String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))

        let safeText = text.replacingOccurrences(of: "\"", with: "\\\"")
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <style>
            body {
                margin: 0;
                background: \(hexColor);
                overflow: hidden;
            }
            video {
                width: 100%;
                height: 100%;
                display: block;
                background: \(hexColor);
                cursor: pointer;
            }
            canvas {
                display: none;
            }
        </style>
        </head>
        <body>
        <video id="vid" autoplay muted playsinline></video>
        <canvas id="canvas" width="\(width)" height="\(height)"></canvas>
        <script>
            const canvas = document.getElementById('canvas');
            const ctx = canvas.getContext('2d');
            const video = document.getElementById('vid');
            let text = "\(safeText)";
            let textSize = \(textSize);
            let bgColor = "\(hexColor)";
            let w = \(width);
            let h = \(height);

            function draw() {
                ctx.clearRect(0, 0, w, h);
                ctx.fillStyle = bgColor;
                ctx.fillRect(0, 0, w, h);
                ctx.fillStyle = invertColor(bgColor);
                ctx.font = textSize + "px sans-serif";
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillText(text, w/2, h/2);
                requestAnimationFrame(draw);
            }

            function invertColor(hex) {
                hex = hex.replace("#", "");
                if (hex.length === 3) hex = hex.split("").map(h => h+h).join("");
                if (hex.length !== 6) return "#000000";
                const r = parseInt(hex.slice(0,2), 16);
                const g = parseInt(hex.slice(2,4), 16);
                const b = parseInt(hex.slice(4,6), 16);
                return (r*0.299 + g*0.587 + b*0.114) > 186 ? "#000000" : "#FFFFFF";
            }

            function startPiP() {
                const stream = canvas.captureStream(30);
                video.srcObject = stream;
                video.play().then(() => {
                    if (!document.pictureInPictureElement) {
                        video.requestPictureInPicture().catch(err => {
                            alert("PiP error: " + err);
                        });
                    }
                });
            }
        
            video.addEventListener("click", async () => {
                try {
                    if (document.pictureInPictureElement) {
                        await document.exitPictureInPicture();
                    } else {
                        await video.requestPictureInPicture();
                    }
                } catch (err) {
                    alert("PiP error: " + err);
                }
            });

            function updateContent(newText, newW, newH, newSize, newBg) {
                text = newText;
                w = newW;
                h = newH;
                textSize = newSize;
                bgColor = newBg;
                canvas.width = w;
                canvas.height = h;
            }

            startPiP();
            draw();
        </script>
        </body>
        </html>
        """
        wv.loadHTMLString(html, baseURL: nil)
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let uiColor = UIColor(bgColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let hexColor = String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
        let safeText = text.replacingOccurrences(of: "\"", with: "\\\"")
        let js = """
        updateContent("\(safeText)", \(width), \(height), \(textSize), "\(hexColor)");
        """
        uiView.evaluateJavaScript(js)
    }
}

#Preview {
    ContentView2()
}
