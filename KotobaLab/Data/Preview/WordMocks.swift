//
//  WordMocks.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/05/05.
//

extension WordSummary {
    static let sample = WordSummary(
        id: 1,
        term: "食べる",
        reading: "たべる",
        previewPartOfSpeech: "verb",
        previewMeaning: "to eat"
    )

    static let list: [WordSummary] = [
        .sample,
        WordSummary(
            id: 2,
            term: "食器",
            reading: "しょっき",
            previewPartOfSpeech: "noun",
            previewMeaning: "tableware"
        ),
        WordSummary(
            id: 3,
            term: "食欲",
            reading: "しょくよく",
            previewPartOfSpeech: "noun",
            previewMeaning: "appetite"
        ),
    ]
}

extension WordDetail {
    static let sample = WordDetail(
        id: 1,
        term: "食べる",
        reading: "たべる",
        meanings: [
            Meaning(id: 1, partOfSpeech: "verb", definition: "to eat"),
            Meaning(id: 2, partOfSpeech: "verb", definition: "to live on"),
        ]
    )

    static let list: [WordDetail] = [
        .sample,
        WordDetail(
            id: 2,
            term: "食器",
            reading: "しょっき",
            meanings: [
                Meaning(id: 3, partOfSpeech: "noun", definition: "tableware")
            ]
        ),
    ]
}
