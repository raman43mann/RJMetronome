import AVFoundation
import Combine
import SwiftUI
 
class MetronomeViewModels: ObservableObject {
    @Published var bpm: Double = 120 {
        didSet {
            if isRunning {
                setupTimer()
            }
        }
    }
    @Published var timeSignature: Int = 4 {
        didSet {
            if isRunning {
                setupTimer()
            }
        }
    }
    @Published var subdivision: Int = 1 {
        didSet {
            if isRunning {
                setupTimer()
            }
        }
    }
    @Published var isRunning: Bool = false {
        didSet {
            if isRunning {
                startMetronome()
            } else {
                stopMetronome()
            }
        }
    }
    @Published var tickCount = 0
    
    private var timer: AnyCancellable?
    private var tickPlayer: AVAudioPlayer?
    private var tockPlayer: AVAudioPlayer?
    
    init() {
        loadSounds()
    }
    
    private func loadSounds() {
        guard let tickPath = Bundle.main.path(forResource: "tick", ofType: "wav") else { return }
        let tickUrl = URL(fileURLWithPath: tickPath)
        tickPlayer = try? AVAudioPlayer(contentsOf: tickUrl)
        
        guard let tockPath = Bundle.main.path(forResource: "tock", ofType: "wav") else { return }
        let tockUrl = URL(fileURLWithPath: tockPath)
        tockPlayer = try? AVAudioPlayer(contentsOf: tockUrl)
    }
    
    private func startMetronome() {
        tickCount = 0
        setupTimer()
    }
    
    private func stopMetronome() {
        timer?.cancel()
        timer = nil
    }
    
    private func setupTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 60 / (bpm * Double(subdivision)), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
 
    
    private func tick() {
        // Play the appropriate sound based on the subdivision
        if (tickCount % subdivision) == 0 {
            playTick()
        } else {
            playTock()
        }
        
        // Increment tickCount
        tickCount += 1
        
        // Reset tickCount after completing a measure
        if tickCount >= subdivision * timeSignature {
            tickCount = 0
        }
    }

     func getCircleIndex() -> Int {
        return (tickCount / subdivision) % timeSignature
    }
 
    private func playTick() {
        tickPlayer?.play()
    }
    
    private func playTock() {
        tockPlayer?.play()
    }
    
    func shuffleBPM() {
        bpm = Double(Int.random(in: 40...208))
    }
}

struct MetronomeView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = MetronomeViewModels()

    let bpmRange = Array(40...208)
    let timeSignatureRange = Array(2...16)
    let subdivisionOptions = [1, 2, 3, 4]
    
    
    init() {
           let appearance = UINavigationBarAppearance()
           appearance.configureWithOpaqueBackground()
           appearance.backgroundColor = UIColor.white // Custom background color
           appearance.titleTextAttributes = [.foregroundColor: UIColor.black] // Custom title color

           UINavigationBar.appearance().standardAppearance = appearance
           UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().backgroundColor = .white
       }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    BPMPickerView(viewModel: viewModel, bpmRange: bpmRange).padding(.bottom,20)
                    TimeSignatureAndSubdivisionPickerView(viewModel: viewModel, timeSignatureRange: timeSignatureRange, subdivisionOptions: subdivisionOptions).padding(.bottom,20)
                 
                    MetronomeCircleView(viewModel: viewModel)
                }
                .padding(.top, 0) // Ensure content starts below the navigation bar// Set the background color of the scroll view
                .edgesIgnoringSafeArea(.bottom)
            }.padding(.all)
            
         }
        .background(Color.white)
        .navigationBarTitle("Metronome", displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())
        .background(Color.white)
        
    }
    
    // Custom back button
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "arrow.left")
            }
        }.frame(width: 40,height: 40)
    }
    
    // BPM Picker View
    struct BPMPickerView: View {
        @ObservedObject var viewModel: MetronomeViewModels
        let bpmRange: [Int]
        
        var body: some View {
            VStack {
                Text("BPM")
                    .font(.headline)
                
                
                Picker("BPM", selection: $viewModel.bpm) {
                    ForEach(bpmRange, id: \.self) { bpm in
                        Text("\(bpm) BPM").tag(Double(bpm))
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
                .clipped()
                .disabled(viewModel.isRunning)
                .opacity(viewModel.isRunning ? 0.5 : 1.0)
                .padding(.bottom,10)
                
                Button(action: {
                    viewModel.shuffleBPM()
                }) {
                    Text("Shuffle BPM")
                        .font(.footnote)
                        .frame(width: 140, height: 50, alignment: .center)
                }
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(25)
            }
        }
    }
    
    // Time Signature and Subdivision Picker View
    struct TimeSignatureAndSubdivisionPickerView: View {
        @ObservedObject var viewModel: MetronomeViewModels
        let timeSignatureRange: [Int]
        let subdivisionOptions: [Int]
        
        var body: some View {
            HStack {
                Spacer()
                VStack {
                    Text("Time Signature")
                        .font(.headline)
                    Picker("Time Signature", selection: $viewModel.timeSignature) {
                        ForEach(timeSignatureRange, id: \.self) { timeSignature in
                            Text("\(timeSignature)").tag(timeSignature)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                Spacer()
                
                VStack {
                    Text("Subdivision")
                        .font(.headline)
                    Picker("Subdivision", selection: $viewModel.subdivision) {
                        ForEach(subdivisionOptions, id: \.self) { subdivision in
                            Text("\(subdivision)").tag(subdivision)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                Spacer()
            }
            .padding(.all, 20)
            
        }
    }
    
    struct MetronomeCircleView: View {
        @ObservedObject var viewModel: MetronomeViewModels
        
        var body: some View {
            ZStack {
                ForEach(0..<viewModel.timeSignature, id: \.self) { index in
                    createCircle(index: index)
                }
                
                Button(action: {
                    viewModel.isRunning.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.isRunning ? Color.red : Color.blue)
                            .frame(width: 150, height: 150)
                        
                        VStack {
                            Text(viewModel.isRunning ? "STOP" : "START")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom)
                            
                            Text("\(Int(viewModel.bpm))")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .frame(width: 200, height: 200)
        }
        
        private func createCircle(index: Int) -> some View {
            Circle()
                .fill(viewModel.isRunning && index != viewModel.getCircleIndex() ? Color.gray.opacity(0.5) : (viewModel.isRunning == false ? Color.gray.opacity(0.5) : Color.green))
                .frame(width: 20, height: 20)
                .offset(x: CGFloat(cos(Double(index) * (2 * .pi / Double(viewModel.timeSignature)))) * 100,
                        y: CGFloat(sin(Double(index) * (2 * .pi / Double(viewModel.timeSignature)))) * 100)
        }
    }

}


struct ContentView: View {
    var body: some View {
        MetronomeView()
    }
}

struct NavigationBarModifier: ViewModifier {

    var backgroundColor: UIColor?
    var titleColor: UIColor?
    

    init(backgroundColor: Color, titleColor: UIColor?) {
        self.backgroundColor = UIColor(backgroundColor)
        
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
        coloredAppearance.backgroundColor = .clear // The key is here. Change the actual bar to clear.
        coloredAppearance.titleTextAttributes = [.foregroundColor: titleColor ?? .white]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor ?? .white]
        coloredAppearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UINavigationBar.appearance().tintColor = titleColor
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .top){
            content
            Rectangle() .foregroundColor(Color(self.backgroundColor ?? .clear))
                            .frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
                            .edgesIgnoringSafeArea(.all)
        }
    }
}

extension View {
    func navigationBarColor(backgroundColor: Color, titleColor: UIColor?) -> some View {
        self.modifier(NavigationBarModifier(backgroundColor: backgroundColor, titleColor: titleColor))
    }
}

