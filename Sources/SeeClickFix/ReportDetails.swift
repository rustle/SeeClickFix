//
//  ReportDetails.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation

public struct ReportDetails : JSONContainer {
    public let organization: String?
    public let title: String
    public let questions: [Question]
    public struct Question : Codable {
        public let primary_key: String
        public let question: String
        public enum QuestionType : String, Codable {
            case datetime
            case file
            case note
            case select
            case text
            case textarea
            case multivaluelist
        }
        public let question_type: QuestionType
        public let answer_kept_private: Bool
        public let response_required: Bool
        public let select_values: [SelectValue]?
        public struct SelectValue : Codable {
            public let key: String
            public let name: String
        }
    }
}
