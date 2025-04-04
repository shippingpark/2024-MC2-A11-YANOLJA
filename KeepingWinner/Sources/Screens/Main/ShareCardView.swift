//
//  ShareCardView.swift
//  KeepingWinner
//
//  Created by 유지수 on 3/22/25.
//

import SwiftUI
import Photos

struct ShareCardView: View {
  @Bindable var winRateUseCase: WinRateUseCase
  @Bindable var userInfoUseCase: UserInfoUseCase
  let characterModel: CharacterModel
  
  @Binding var cardButtonTapped: Bool
  @State private var saveState: SaveState = .idle
  @State private var showPermissionDeniedAlert = false
  
  var body: some View {
    ZStack {
      DarkBlurView()
        .ignoresSafeArea()
      
      VStack(spacing: 0) {
        VStack(alignment: .trailing, spacing: 0) {
          Button(action: {
            cardButtonTapped = false
          }) {
            Rectangle()
              .foregroundStyle(.clear)
              .frame(width: 24, height: 24)
              .overlay(
                Image(systemName: "xmark")
                  .font(.callout)
                  .bold()
                  .foregroundStyle(.white)
              )
          }
          .padding(.bottom, 8)
          
          cardView
        }
        .padding(.bottom, 16)
        
        shareCardActionButtons
      }
      
      if saveState == .saved {
        overlayView("저장됨", systemImage: "checkmark")
      }
    }
    .alert("'승리지쿄'가 사용자의 사진에 카드를 저장하려고 합니다.", isPresented: $showPermissionDeniedAlert) {
      Button("취소") {}
      Button("설정") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      }
    } message: {
      Text("설정에서 사진 접근 권한을 허용해 주세요.")
    }
  }
  
  private var cardView: some View {
    CardView(
      recordWinRate: winRateUseCase.state.recordWinRate,
      myTeam: userInfoUseCase.state.myTeam?
        .name(type: .full) ?? KeepingWinningRule.noTeamName,
      myNickname: userInfoUseCase.state.myNickname,
      characterModel: characterModel
    )
  }
  
  @ViewBuilder
  private var shareCardActionButtons: some View {
    if winRateUseCase.state.recordWinRate != nil {
      HStack(spacing: 0) {
        saveButton
        
        Spacer().frame(width: 8)
        
        shareButton
      }
    }
  }
  
  private var saveButton: some View {
    Button(action: {
      DispatchQueue.main.async {
        let image = cardView
          .drawingGroup()
          .asUIImage(size: CGSize(width: 280, height: 470))
          .clipped(cornerRadius: 20)
        
        saveImageToAlbum(image)
        
        TrackUserActivityManager.shared
          .effect(.tappedSaveButtonToDownloadCard)
      }
    }) {
      Label("이미지 저장", image: .saveIcon)
        .font(.callout.bold())
        .padding(.horizontal, 26.5)
        .padding(.vertical, 12.5)
        .foregroundStyle(.white)
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
  }
  
  private var shareButton: some View {
    Button(action: {
      DispatchQueue.main.async {
        let image = cardView
          .drawingGroup()
          .asUIImage(size: CGSize(width: 280, height: 470))
          .clipped(cornerRadius: 20)
        
        sharedToInstagramStory(image)
        
        TrackUserActivityManager.shared
          .effect(.tappedShareButtonToShareInsta)
      }
    }) {
      Label("스토리 공유", image: .instagramIcon)
        .font(.callout.bold())
        .padding(.horizontal, 26.5)
        .padding(.vertical, 12.5)
        .foregroundStyle(.white)
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
  }
  
  // 이미지 저장했을 때 알림
  private func overlayView(_ text: String, systemImage: String? = nil) -> some View {
    Rectangle()
      .foregroundStyle(Color(hexString: "252525", opacity: 0.55))
      .ignoresSafeArea()
      .overlay(
        VStack(spacing: 23) {
          if let systemImage = systemImage {
            Image(systemName: systemImage)
              .font(.system(size: 64, weight: .semibold))
              .foregroundStyle(.secondary)
          } else {
            ActivityIndicator(isAnimating: .constant(true), style: .large)
          }
          
          Text(text)
            .font(.callout)
            .foregroundStyle(Color.primary)
        }
        .frame(width: 155, height: 157)
        .background(.regularMaterial)
        .cornerRadius(8)
      )
  }
  
  // 이미지 공유 버튼을 통한 PNG 이미지 저장
  @MainActor
  private func saveImageToAlbum(_ image: UIImage) {
    saveState = .saving
    
    guard let pngData = image.pngData() else {
      saveState = .idle
      return
    }
    
    handlePhotoLibraryPermission { granted in
      if granted {
        self.saveImageDataToAlbum(pngData)
      } else {
        self.saveState = .idle
      }
    }
  }
  
  @MainActor
  private func handlePhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
    let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    
    switch currentStatus {
    case .authorized:
      completion(true)
      
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
        DispatchQueue.main.async {
          UserDefaults.standard.set(true, forKey: "didJustRequestPhotoPermission")
          completion(newStatus == .authorized)
        }
      }
      
    default:
      let justRequested = UserDefaults.standard.bool(forKey: "didJustRequestPhotoPermission")
      UserDefaults.standard.set(false, forKey: "didJustRequestPhotoPermission")
      
      if !justRequested {
        openSettingsAlert()
      }
      
      completion(false)
    }
  }
  
  @MainActor
  private func saveImageDataToAlbum(_ data: Data) {
    PHPhotoLibrary.shared().performChanges({
      let options = PHAssetResourceCreationOptions()
      let creationRequest = PHAssetCreationRequest.forAsset()
      creationRequest.addResource(with: .photo, data: data, options: options)
    }) { success, error in
      if success {
        self.saveState = .saved
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          self.saveState = .idle
        }
      } else if error != nil {
        self.saveState = .idle
      }
    }
  }
  
  private func openSettingsAlert() {
    showPermissionDeniedAlert = true
  }
  
  // 인스타그램 공유 버튼을 통한 인스타그램 스토리 이동
  private func sharedToInstagramStory(_ image: UIImage) {
    guard let applicationID = PrivateKey.getInstgram else { return } // 예외처리 필요
    guard let urlScheme = URL(string: "instagram-stories://share?source_application=\(applicationID)") else {
      presentShareSheet(for: image)
      return
    }
    
    guard UIApplication.shared.canOpenURL(urlScheme) else {
      presentShareSheet(for: image)
      return
    }
    
    let pasteboardItems: [String: Any] = [
      "com.instagram.sharedSticker.backgroundTopColor": "#\(characterModel.colorHex)",
      "com.instagram.sharedSticker.backgroundBottomColor": "#\(characterModel.colorHex)",
      "com.instagram.sharedSticker.stickerImage": image.pngData() as Any
    ]
    
    let pasteboardOptions = [UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(300)]
    UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
    
    UIApplication.shared.open(urlScheme)
  }
  
  // 공유 시트 함수
  private func presentShareSheet(for image: UIImage) {
    guard let pngData = image.pngData() else { return }
    
    let fileName = makeFileName()
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    try? pngData.write(to: tempURL)
    
    let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootVC = windowScene.windows.first?.rootViewController {
      rootVC.present(activityVC, animated: true)
    }
  }
  
  // 파일 이름 겹치지 않도록 설정
  private func makeFileName() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyMMddHHmmss"
    return "승리지쿄_\(formatter.string(from: Date())).png"
  }
}

enum SaveState {
  case idle, saving, saved
}

#Preview {
  ShareCardView(
    winRateUseCase: .init(
      recordService: RecordDataService(),
      myTeamService: UserDefaultsService(),
      gameRecordInfoService: .live
    ),
    userInfoUseCase: .init(
      myTeamService: UserDefaultsService(), myNicknameService: UserDefaultsService(),
      changeIconService: ChangeAppIconService(),
      settingsService: .preview
    ),
    characterModel: .init(
      symbol: KeepingWinningRule.noTeamSymbol,
      colorHex: KeepingWinningRule.noTeamColorHex,
      totalWinRate: 100
    ),
    cardButtonTapped: .constant(true)
  )
}
