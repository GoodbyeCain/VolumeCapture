// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import MediaPlayer

class VolumeCapture: NSObject {
    private let volumeView = {
        let view = MPVolumeView()
        view.frame = CGRectMake(-300, -300, 100, 100)
        view.showsVolumeSlider = true
        return view
    }()
    private let audioSession = AVAudioSession.sharedInstance()
    private var volume: Float = 0.1
    private var block:(() -> Void)? = nil
    
    deinit {
        audioSession.removeObserver(self, forKeyPath: "outputVolume")
        NotificationCenter.default.removeObserver(self)
    }
    
    public func configWithView(view: UIView, volumeChangedBlock: @escaping() ->Void, defaultVolume:Float = 0.1) {
        block = volumeChangedBlock
        volume = defaultVolume
        
        view.addSubview(volumeView)

        audioSession.addObserver(self, forKeyPath: "outputVolume", options: [.new], context: nil)
        configVolumeCapture()
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.configVolumeCapture()
        }
    }
    
    private func configVolumeCapture() {
        do {
            try audioSession.setActive(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.volumeView.updateVolume(value: 0.1)
            }
        } catch {
            print("VolumeCapture config error: \(error)")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        if keyPath == "outputVolume" {
            if let newVolume = change?[.newKey] as? Float {
                if newVolume != 0.1 {
                    block?()
                    DispatchQueue.main.async {
                        self.volumeView.updateVolume(value: 0.1)
                    }
                }
            }
        }
    }
}

private extension MPVolumeView {
    func updateVolume(value: Float) {
        if let slider = volumeSlider() {
            slider.setValue(value, animated: false)
        }
    }
    
    func volumeSlider() -> UISlider? {
        for view in subviews {
            if let slider = view as? UISlider {
                return slider
            }
        }
        
        return nil
    }
}
