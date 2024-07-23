//
//  stock.swift
//  StocksApp
//
//  Created by Swathi Asok on 4/11/24.
//

import Foundation

// Wallet Money
struct WalletInfo: Codable {
    let wallet: Double
    let flag: Bool
}

// Watchlist Data
struct WatchlistItem: Codable {
    let symbol: String
    var name: String?
    let price: Double?
    let change: Double?
    let change_percent: Double?
    var quoteData: QuoteData?
}

//Portfolio Data
struct PortfolioItem: Decodable {
    let name: String
    let symbol: String
    let buyPrice: String
    let quantity: String
    let buyTotal: String
    var quoteData: QuoteData?
    
    private enum CodingKeys: String, CodingKey {
        case name, symbol, quantity
        case buyPrice = "buy_price"
        case buyTotal = "buy_total"
    }
}

//Autocomplete Response
struct APIResponse: Codable {
    let result: [Symbol]
    let count: Int
}

//Lookup Symbol
struct Symbol: Codable, Hashable {
    let description: String
    let displaySymbol: String
    let symbol: String
    let type: String
}

struct CompanyDetailsResponse: Codable {
    let companyProfileData: CompanyProfileData
    let quotesData: QuoteData
    let peersData: [String]
}

// Company Profile Data
struct CompanyProfileData: Codable {
    let exchange: String
    let finnhubIndustry: String
    let ipo: String
    let logo: String
    let ticker: String
    let weburl: String
    let name: String
}

// Quote Data
struct QuoteData: Codable {
    let c: Double
    let d: Double
    let dp: Double
    let h: Double
    let l: Double
    let o: Double
    let pc: Double
    let t: String
}

struct QuotesData: Decodable {
    let quotesData: QuoteData

    private enum CodingKeys: String, CodingKey {
        case quotesData = "quotesData"
    }
}


// Company News
struct CompanyNewsItem: Codable, Hashable, Identifiable {
    var id: Int
    let datetime: Int
    let headline: String
    let image: String
    let source: String
    let summary: String
    let url: String
}

// Chart Data
struct ChartData: Codable {
    let ticker: String
    let ohlc: [[Int]]
}

// Hourly Chart Data
struct HourlyChartData: Codable {
    let ticker: String
    let time: [TimeInterval]
    let stocks: [Double]
    let chartColor: String
}

// Company Insights
struct CompanyInsights: Codable {
    let insiderSentiments: InsiderSentiments
    let sentimentsData: SentimentsDataContainer
    let recommendationsData: [RecommendationData]
    let earningsData: [EarningsData]
}

struct InsiderSentiments: Codable {
    let avgMspr: Double
    let positiveMspr: Double
    let negativeMspr: Double
    let avgChange: Double
    let positiveChange: Double
    let negativeChange: Double

    enum CodingKeys: String, CodingKey {
        case avgMspr = "avg_mspr"
        case positiveMspr = "positive_mspr"
        case negativeMspr = "negative_mspr"
        case avgChange = "avg_change"
        case positiveChange = "positive_change"
        case negativeChange = "negative_change"
    }
}

struct SentimentsDataContainer: Codable {
    let data: [SentimentData]
    let symbol: String
}

struct SentimentData: Codable {
    let symbol: String
    let year: Int
    let month: Int
    let change: Double
    let mspr: Double
}

struct RecommendationData: Codable {
    let buy: Int
    let hold: Int
    let period: String
    let sell: Int
    let strongBuy: Int
    let strongSell: Int
    let symbol: String
}

struct EarningsData: Codable {
    let actual: Double
    let estimate: Double
    let period: String
    let quarter: Int
    let surprise: Double
    let surprisePercent: Double
    let symbol: String
    let year: Int
}

struct Toast: Equatable {
  var message: String
  var duration: Double = 3
  var width: Double = .infinity
}


