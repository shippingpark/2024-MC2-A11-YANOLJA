//
//  DetailRecordView.swift
//  Yanolja
//
//  Created by 박혜운 on 5/13/24.
//  Copyright © 2024 com.mc2.yanolja. All rights reserved.
//

import SwiftUI
import UIKit

// 내가 보이는 뷰를 생성하거나 편집하는 enum
enum RecordViewEditType {
  case create
  case edit
}

struct DetailRecordView: View {
  @Environment(\.dismiss) var dismiss
  var recordUseCase: RecordUseCase
  
  @State var recording: GameRecordWithScoreModel = .init() // 수정할 때
  
  @State private var realRecordInfoList: [GameRecordWithScoreModel] = []
  @State private var showingAlert: Bool = false
  @State private var isDataLoading = false
  @State private var changeMyTeam: BaseballTeam?
  
  private let editType: RecordViewEditType
  private let changeRecords: ([GameRecordWithScoreModel]) -> Void
  
  @State private var selectedOption: String = ""
  private let doubleHeader = [0: "DH1", 1: "DH2"]
  private var isDH: Bool { recording.isDoubleHeader != -1 }
  
  @State private var showImagePicker = false
  @State private var selectedUIImage: UIImage?
  @State private var image: Image?
  
  @State private var makeBlur: Bool = false
  
  // 이벤트 기록 여부를 추적
  @State private var trackUploadPicture: Bool = false
  
  init(
    to editType: RecordViewEditType,
    record: GameRecordWithScoreModel = .init(),
    usecase: RecordUseCase,
    changeRecords: @escaping ([GameRecordWithScoreModel]) -> Void
  ) {
    self.editType = editType
    self._recording = State(initialValue: record)
    self.recordUseCase = usecase
    self.changeRecords = changeRecords
  }
  
  var body: some View {
    NavigationStack {
      List {
        Section(
          "직관 정보",
          content: {
            selectDate
            
            // 경기장 Picker
            Picker(
              "경기장",
              selection: $recording.stadiums
            ) {
              ForEach(BaseballStadiums.nameList, id: \.self) {
                Text($0)
              }
            }
            .accentColor(.gray)
            .pickerStyle(.menu)
            
            HStack(spacing: 10) {
              SelectTeamBlock(
                type: .my, // 나의 팀
                selectedTeam: .init( // 이미지와 팀이름 선택
                  get: { recording.myTeam },
                  set: { selectedMyTeam in
                    showingAlert = true
                    changeMyTeam = selectedMyTeam
                  }
                                   )
              )
              .padding(.top, 4)
              .alert(isPresented: $showingAlert) {
                Alert(
                  title: Text("알림"),
                  message: Text("모든 직관 기록은 \n 나의 직관 승률에 반영됩니다. \n 그래도 나의 팀을 변경하시겠습니까?"),
                  primaryButton:
                      .destructive(Text("취소")) {
                        
                      },
                  secondaryButton:
                      .default( Text("확인") ) {
                        // MARK: - 나의 팀 변경: 동시에 상태 팀 선택 리스트 제한
                        if let myTeam = changeMyTeam {
                          recording.myTeam = myTeam
                          if recording.vsTeam == myTeam {
                            recording.vsTeam = recording.vsTeam.anyOtherTeam()
                          }
                          Task {
                            realRecordInfoList = await loadRealGameRecordsInfo()
                            recording = realRecordInfoList.first?.keepMemoPhoto(in: recording) ?? resetScoreCancelDoubleHeaderAbout(recording)
                          }
                        }
                      }
                )
              }
              
              Text("VS")
                .font(.title2)
                .foregroundStyle(.gray)
              
              SelectTeamBlock(
                type: .vs(myteam: recording.myTeam),
                selectedTeam: $recording.vsTeam
              )
            }
            
            Toggle(isOn: .init(get: { isDH }, set: { isDH in recording.isDoubleHeader = isDH ? 0 : -1 })) {
              Text("더블헤더")
            }
          }
        )
        
        // 더블헤더 선택
        if isDH {
          Picker("더블헤더 선택", selection: .init(
            get: { recording.isDoubleHeader },
            set: { doubleHeaderNum in
              recording.isDoubleHeader = doubleHeaderNum
              if doubleHeaderNum == 1 {
                recording = realRecordInfoList.last?.keepMemoPhoto(in: recording) ?? recording
              } else {
                recording = realRecordInfoList.first?.keepMemoPhoto(in: recording) ?? recording
              }
            }
          )) {
            ForEach(doubleHeader.keys.sorted(), id: \.self) { key in
              Text(doubleHeader[key] ?? "")
            }
          }
          .pickerStyle(.inline)
        }
        
        // 경기 결과 표시
        Section(
          "경기 결과",
          content: {
            HStack(spacing: 0) {
              Text("스코어")
                .foregroundStyle(recording.isCancel ? .gray : .black)
              Spacer()
              
              // 스코어 입력 : 취소 시 disabled
              TextField(
                "--",
                text: Binding(
                  get: {
                    recording.myTeamScore == "--" ? "" : recording.myTeamScore
                  },
                  set: { newValue in
                    recording.myTeamScore = newValue.isEmpty ? "" : newValue
                  }))
              .keyboardType(.numberPad)
              .multilineTextAlignment(.center)
              .frame(width: 94, height: 32)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .foregroundStyle(recording.isCancel ? .noTeam2.opacity(0.4) : .noTeam2)
              )
              .font(.headline)
              .foregroundStyle(recording.isCancel ? .gray : .black)
              
              Text(":")
                .foregroundStyle(recording.isCancel ? .gray.opacity(0.4) : .gray)
                .padding(.horizontal, 21)
              
              TextField(
                "--",
                text: Binding(
                  get: {
                    recording.vsTeamScore == "--" ? "" : recording.vsTeamScore
                  },
                  set: { newValue in
                    recording.vsTeamScore = newValue.isEmpty ? "" : newValue
                  }))
              .keyboardType(.numberPad)
              .multilineTextAlignment(.center)
              .frame(width: 94, height: 32)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .foregroundStyle(recording.isCancel ? .noTeam2.opacity(0.4) : .noTeam2)
              )
              .font(.headline)
              .foregroundStyle(recording.isCancel ? .gray : .black)
            }
            .disabled(recording.isCancel)
            
            Toggle(isOn: $recording.isCancel) {
              Text("취소")
            }
          })
        
        // (Optional) 메모 추가
        Section(
          "메모 (선택)",
          content: {
            TextField("한 줄 메모를 남겨 보세요.", text: Binding(
              get: { recording.memo ?? "" },
              set: { recording.memo = $0.isEmpty ? nil : $0 }
            ))
            .overlay(
              alignment: .trailing,
              content: {
                Text("\(recording.memo?.count ?? 0) / 15")
                  .font(.callout)
                  .foregroundStyle(Color(uiColor: .systemGray2))
              }
            )
            .onChange(of: recording.memo ?? "") { oldValue, newValue in
              if newValue.count > 15 {
                recording.memo = String(newValue.prefix(15))
              }
            }
          })
        
        // (Optional) 사진 추가
        Section(
          "사진 (선택)",
          content: {
            if let image = recording.photo {
              VStack {
                if makeBlur {
                  ZStack {
                    Image(uiImage: image)
                      .resizable()
                      .scaledToFill()
                      .frame(width: UIScreen.main.bounds.width - 50, height: UIScreen.main.bounds.width - 50)
                      .clipped()
                      .cornerRadius(8)
                      .blur(radius: 3)
                    Image(systemName: "trash")
                      .resizable()
                      .frame(width: 36, height: 42)
                      .aspectRatio(1, contentMode: .fill)
                      .foregroundStyle(.white)
                      .onTapGesture {
                        recording.photo = nil
                        makeBlur.toggle()
                      }
                  }
                } else {
                  Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width - 50, height: UIScreen.main.bounds.width - 50)
                    .clipped()
                    .cornerRadius(8)
                }
              }
              .frame(height: UIScreen.main.bounds.width - 50)
              .onTapGesture {
                makeBlur.toggle()
              }
            } else {
              HStack(spacing: 0) {
                Image(systemName: "plus")
                Text(" 사진 추가하기")
                Spacer()
              }
              .contentShape(Rectangle())
              .onTapGesture {
                showImagePicker.toggle()
                // 사진 업로드 이벤트
                // uploadPicture()
              }
              .sheet(
                isPresented: $showImagePicker,
                onDismiss: {
                  loadImage()
                }) {
                  ImagePicker(image: $selectedUIImage)
                }
            }
          })
        
        if editType == .edit {
          Button(
            action: {
              recordUseCase.effect(.tappedDeleteRecord(recording.id))
              changeRecords(recordUseCase.state.recordList)
              dismiss()
            },
            label: {
              HStack{
                Spacer()
                Text("기록 삭제")
                  .foregroundStyle(.red)
                Spacer()
              }
            }
          )
        }
      }
      .loadingIndicator(isLoading: isDataLoading)
      .toolbar(
        content: {
          ToolbarItem(placement: .topBarTrailing) {
            Button(
              action: {
                if editType == .create { // 생성 시
                  // 만약 스코어를 입력하지 않고 저장했다면 리스트에 "--" 반영
                  if recording.myTeamScore.isEmpty {
                    recording.myTeamScore = "0"
                  }
                  if recording.vsTeamScore.isEmpty {
                    recording.vsTeamScore = "0"
                  }
                  if recording.isCancel {
                    recording.isCancel = true
                  }
                  
                  recordUseCase.effect(.tappedSaveNewRecord(recording))
                  changeRecords(recordUseCase.state.recordList)
                } else { // 수정 시
                  // 만약 스코어를 입력하지 않고 저장했다면 리스트에 "--" 반영
                  if recording.myTeamScore.isEmpty {
                    recording.myTeamScore = "0"
                  }
                  if recording.vsTeamScore.isEmpty {
                    recording.vsTeamScore = "0"
                  }
                  if recording.isCancel {
                    recording.isCancel = true
                  }
                  
                  recordUseCase.effect(.tappedEditNewRecord(recording))
                  changeRecords(recordUseCase.state.recordList)
                  dismiss()
                }
                TrackUserActivityManager.shared.effect(.tappedConfirmButtonToRecord(recording: recording))
              },
              label: {
                Text("완료")
                  .bold()
              }
            )
          }
          ToolbarItem(placement: .topBarLeading) {
            Button(
              action: {
                if editType == .create { // 생성 시
                  recordUseCase.effect(.tappedCreateRecordSheet(false))
                } else { // 수정 시
                  recordUseCase.effect(.tappedRecordCellToEditRecordSheet(false))
                  dismiss()
                }
              },
              label: {
                Text("취소")
              }
            )
          }
        }
      )
      .tint(.black)
      .navigationTitle("오늘의 직관")
      .navigationBarTitleDisplayMode(.inline)
    }
    .task {
      realRecordInfoList = await loadRealGameRecordsInfo()
      if editType == .create {
        recording = realRecordInfoList.first ?? recording
      }
    }
  }

  private var selectDate: some View {
    DatePicker(
      "날짜",
      selection: .init(
        get: {
          recording.date
        },
        set: { date in
          recording.date = date
          Task {
            realRecordInfoList = await loadRealGameRecordsInfo()
            recording = realRecordInfoList.first?.keepMemoPhoto(in: recording) ?? resetScoreCancelDoubleHeaderAbout(recording)
          }
        }
      ),
      displayedComponents: [.date]
    )
  }
  
  private func loadImage() {
    guard let selectedImage = selectedUIImage else { return }
    recording.photo = selectedImage
  }
  
  private func loadRealGameRecordsInfo() async -> [GameRecordWithScoreModel] {
    isDataLoading = true
    let service = GameRecordInfoService.live
    let result = await service.gameRecord(recording.date, recording.myTeam.sliceName)
    isDataLoading = false
    guard case var .success(recordList) = result else { return [] }
    recordList.indices.forEach { recordList[$0].id = recording.id }
    return recordList
  }
  
  private func resetScoreCancelDoubleHeaderAbout(_ record: GameRecordWithScoreModel) -> GameRecordWithScoreModel {
    var new = record
    new.myTeamScore = "0"
    new.vsTeamScore = "0"
    new.isDoubleHeader = -1
    new.isCancel = false
    
    return new
  }
}

private extension GameRecordWithScoreModel {
  func keepMemoPhoto(in exRecord: GameRecordWithScoreModel) -> GameRecordWithScoreModel {
    var new = self
    new.id = exRecord.id
    new.memo = exRecord.memo
    new.photo = exRecord.photo
    
    return new
  }
}

#Preview {
  DetailRecordView(
    // 현재 보여지는 뷰는 편집(삭제 버튼 추가)
    to: .edit,
    usecase: RecordUseCase(
      recordService: RecordDataService()
    ),
    changeRecords: { _ in }
  )
}
