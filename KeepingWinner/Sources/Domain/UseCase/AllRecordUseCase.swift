//
//  RecordUseCase.swift
//  Yanolja
//
//  Created by 박혜운 on 5/13/24.
//  Copyright © 2024 com.mc2.yanolja. All rights reserved.
//

import SwiftUI

@Observable
final class AllRecordUseCase {
  // MARK: - State
  struct State {
    var isAscending: Bool = true
    var isPresentedYearFilterSheet: Bool = false
    var selectedYearFilter: String = YearFilter.initialValue
    var selectedFilterOptions: [String: [String]] = [:]
    
    var baseballTeams: [BaseballTeamModel] = []
    var stadiums: [StadiumModel] = []
    var recordList: [RecordModel] = []
    
    var stadiumFilterOptions: [String] {
      let yearStadiums = self.stadiums
        .filter {
          $0.isValid(in: Int(self.selectedYearFilter) ?? KeepingWinningRule.dataUpdateYear)
        }
      
      if self.selectedYearFilter != "전체" {
        return yearStadiums.map { $0.name(year: self.selectedYearFilter) }
          .sorted(by: { lhs, rhs in return lhs.sortKRPriority(rhs) })
      } else {
        var seenSymbols: Set<String> = Set(yearStadiums.map { $0.symbol })
        let extraStadium = self.recordList.filter {
          guard !seenSymbols.contains($0.stadium.symbol) else { return false }
          seenSymbols.insert($0.stadium.symbol)
          return true
        }
        
        return (yearStadiums.map { $0.name() } +
                extraStadium.map { $0.stadium.recentName() })
        .sorted(by: { lhs, rhs in return lhs.sortKRPriority(rhs) })
      }
    }
  }
  
  // MARK: - Action
  enum Action {
    case onAppear
    case _loadBaseballTeamNames
    case _loadStadiums
    
    case presentingYearFilter(Bool)
    case tappedAscending
    
    case setYearFilter(to: String)
    
    case renewAllRecord
    case newRecord(RecordModel)
    case editRecord(RecordModel)
    case removeRecord(UUID)
  }
  
  private var recordService: RecordDataServiceInterface
  private var userInfoService: MyTeamServiceInterface = UserDefaultsService()
  private var baseballTeamService: BaseballTeamService = .live
  private var stadiumService: StadiumService = .live
  private(set) var state: State = .init()
  
  init(
    recordService: RecordDataServiceInterface
  ) {
    self.recordService = recordService
  }
  
  // MARK: - View Action
  func effect(_ action: Action) {
    switch action {
    case .onAppear:
      effect(._loadBaseballTeamNames)
      effect(._loadStadiums)
      effect(.renewAllRecord)
      
    case ._loadBaseballTeamNames:
      self.state.baseballTeams = self.baseballTeamService.teams()
      return
      
    case ._loadStadiums:
      self.state.stadiums = self.stadiumService.stadiums()
      return
      
    case let .setYearFilter(year):
      state.selectedYearFilter = year
      
    case .presentingYearFilter(let presenting):
      state.isPresentedYearFilterSheet = presenting
      
    case .tappedAscending:
      state.isAscending.toggle()
      
    case .renewAllRecord:
      switch recordService
        .readAllRecord(
          baseballTeams: self.state.baseballTeams,
          stadiums: self.state
            .stadiums) {
      case .success(let dataList):
        state.recordList = dataList
      case .failure:
        return
      }
      
      // 데이터 저장 요청
    case let .newRecord(newRecord):
      state.recordList.append(newRecord)
      
      // 데이터 수정 요청
    case let .editRecord(editRecord):
      if let index = state.recordList.map({ $0.id }).firstIndex(of: editRecord.id) {
        state.recordList[index] = editRecord
      }
      
      // 데이터 삭제 요청
    case let .removeRecord(id):
      state.recordList = state.recordList.filter { $0.id != id }
      return
    }
  }
}
