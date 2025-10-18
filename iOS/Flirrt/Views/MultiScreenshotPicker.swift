//
//  MultiScreenshotPicker.swift
//  Vibe8
//
//  Multi-screenshot selection for chat analysis
//  Based on GPT-4O and Grok-4 best practices
//

import SwiftUI
import PhotosUI

struct MultiScreenshotPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedImagesData: [Data]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 3 // Max 3 screenshots for chat context
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiScreenshotPicker
        
        init(_ parent: MultiScreenshotPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard !results.isEmpty else { return }
            
            // Clear previous selections
            parent.selectedImages = []
            parent.selectedImagesData = []
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(image)
                                
                                // Also store as Data for API
                                if let imageData = image.jpegData(compressionQuality: 0.8) {
                                    self.parent.selectedImagesData.append(imageData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Multi-Screenshot Preview Grid

struct ScreenshotGrid: View {
    let images: [UIImage]
    let onRemove: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(images.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: images[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pink, lineWidth: 2)
                            )
                        
                        // Remove button
                        Button(action: {
                            onRemove(index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Screenshot Count Indicator

struct ScreenshotCountIndicator: View {
    let count: Int
    let maxCount: Int = 3
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "photo.stack")
                .foregroundColor(.pink)
            
            Text("\(count)/\(maxCount) screenshots")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            if count > 0 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.3))
        .cornerRadius(20)
    }
}

