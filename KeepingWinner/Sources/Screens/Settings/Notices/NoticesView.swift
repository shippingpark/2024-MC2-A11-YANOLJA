//
//  AnnouncementsView.swift
//  Practice_Setting
//
//  Created by 이연정 on 10/8/24.
//

import SwiftUI

struct NoticesView: View {
  let notices: [NoticeModel]
  
  var body: some View {
    List {
      ForEach(notices) { notice in
        NoticeBlock(notice: notice)
      }
    }
    .padding(.top, -20)
    .tint(.black)
  }
}

private struct NoticeBlock: View {
  @State private var isExpanded: Bool = false
  let notice: NoticeModel
  
  var body: some View {
    Button(action: {
      withAnimation(.bouncy(duration: 0.25)) {
        isExpanded.toggle()
      }
    }) {
      HStack{
        VStack(alignment: .leading) {
          Text(notice.title)
          Text(notice.date)
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        Spacer()
        Image("chevron")
          .padding(0)
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
      }
    }
    
    if isExpanded {
      Text(notice.contents)
        .font(.footnote)
        .padding(.vertical, 5)
    }
  }
}

#Preview {
  NoticesView(notices: [.init(date: "2024-10-13", title: "🍁더위가 가고 가을 야구가 찾아왔어요! 1.0.0 업데이트 안내", contents: "1️⃣ ver 1.0.0 출시!!\n\n깔끔하고 단순한 화면은 물론, 더 편하고 확실하게 나의 직관 승률을 확인해봐요. 우리 함께 승률에 따라 변화하는 캐릭터를 보며 직관 기록을 이어가요! 승률 정보를 한 눈에 확인해봐요!\n\n2️⃣ 자동 경기 기록!!\n\n직관 기록을 자동으로 기입해 이전보다 편리하게 직관을 기록해봐요! 스코어, 직관 한 줄 일기, 경기와 함께한 사진을 남겨 추억해봐요! 내가 가장 기억하고 싶은 순간을 간단하게 기록해보는 것은 어때요?\n\n3️⃣ 새로운 분석 화면 등장!!\n\n내가 직관을 봤을 때 가장 잘 이기는 상대팀은 어디일까? 나는 어디 구장에서 승률이 가장 높을까? 나의 승률 데이터를 여러 분석을 통해서 재미를 느껴봐요!\n\n⭐️앱스토어 리뷰,📱인스타그램 팔로우는 저희에게 정말 큰 힘이 됩니다.\n\n\n- 제대로 가을 타고 있는 중인 팀 승리지쿄- "), .init(date: "2024-10-12", title: "더위가 가고 가을 야구가 찾아왔어요🍁\n승리지쿄 1.0 업데이트 안내", contents: "#승리지쿄 ver 1.0 출시!\n\n깔끔하고 단순한 화면은 물론, 더 편하고 확실하게 나의 직관 승률을 확인해봐요!\n나의 승률에 따라 변화하는 캐릭터를 보며 직관 기록을 이어가 보는 것은 어때요? 승률 정보를 한 눈에 확인해봐요~\n\n# 나의 기록은 어떻게 확인하고 싶나요?\n\n직관 기록을 자동으로 기입해봐요. 경기가 끝난 후 전보다 간편하게 직관 기록을 기입해봐요!\n스코어, 직관 한 줄 일기, 경기와 함께한 추억을 남겨보세요!\n내가 가장 기억하고 싶은 순간을 간단하게 기록해보는 것은 어때요?\n\n# 나는 어떨 때 가장 승률이 높을까?\n\n내가 직관을 봤을 때 가장 잘 이기는 상대 팀은 어디일까?\n나는 어디 구장에서 승률이 가장 높을까?\n나의 승률 데이터를 여러 분석을 통해서 재미를 느껴봐요:)\n\n\n제대로 가을 타고 있는 중인\n@승리지쿄 팀원들 올림")])
}
