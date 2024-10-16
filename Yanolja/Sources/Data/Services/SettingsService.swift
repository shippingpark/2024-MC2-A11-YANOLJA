//
//  SettingsService.swift
//  Yanolja
//
//  Created by 박혜운 on 10/12/24.
//  Copyright © 2024 com.mc2. All rights reserved.
//

import Foundation

extension SettingsService {
  static let live = {
    return Self(
      characterBubbleTexts: { myTeam in
        let result = await Provider<GameRecordInfoAPI>
          .init()
          .request(
            SettingsAPI.characterBubbleTexts(myTeam: myTeam),
            type: TeamLineDTO.self
          )
        switch result {
        case let .success(teamLineDto): return .success(teamLineDto.line)
        case let .failure(error): return .failure(error)
        }
      },  allStadiums: {
        let result = await Provider<GameRecordInfoAPI>
          .init()
          .request(
            SettingsAPI.allStadiums,
            type: StadiumsDTO.self
          )
        switch result {
        case let .success(stadiumsDTO): return .success(stadiumsDTO.stadiums)
        case let .failure(error): return .failure(error)
        }
      }, allNotices: {
        let result = await Provider<SettingsAPI>
          .init()
          .request(
            SettingsAPI.allNotices,
            type: NoticesDTO.self
          )
        
        switch result {
        case let .success(noticesDTO):
          let notices = noticesDTO.notices
          let newNotices: [NoticeModel] = notices.map { NoticeModel(date: $0.date, title: $0.noticeName, contents: $0.noticeComment) }
          return .success(newNotices)
        case let .failure(error): return .failure(error)
        }
      }
    )
  }()
}
