//
//  StockDetailsView.swift
//  StocksApp
//
//  Created by Swathi Asok on 4/12/24.
//

import SwiftUI
import Highcharts
import WebKit

struct StockDetailsView: View {
    var symbol: String
    
    private var hourlyChartOptions: HIOptions {
        let options = HIOptions()
        
        let chart = HIChart()
        chart.type = "line"
        options.chart = chart
        
        let title = HITitle()
        title.text = "\(symbol) Hourly Price Variation"
        let style = HICSSObject()
        style.color = "gray"
        title.style = style
        options.title = title
        
        let xAxis = HIXAxis()
        xAxis.categories = hourlyChartData?.time.map { milliseconds in
            let date = Date(timeIntervalSince1970: milliseconds / 1000) // Convert ms to seconds
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC time zone
            formatter.dateFormat = "HH:mm"  // Format hours and minutes
            return formatter.string(from: date)
        }
        xAxis.min = 0
        xAxis.max = 4
        options.xAxis = [xAxis]
        
        let yAxis = HIYAxis()
        let yAxisTitle = HITitle()
        yAxisTitle.text = ""
        yAxis.title = yAxisTitle
        yAxis.opposite = true
        yAxis.tickInterval = 1
        options.yAxis = [yAxis]
        
        let tooltip = HITooltip()
        tooltip.shared = true
        options.tooltip = tooltip
        
        let lineSeries = HISeries()
        lineSeries.type = "line"
        lineSeries.name = "\(symbol)"
        lineSeries.data = hourlyChartData?.stocks.map { NSNumber(value: $0) }
        lineSeries.color = HIColor(name: hourlyChartData?.chartColor ?? "red")
        lineSeries.showInLegend = false
        let marker = HIMarker()
        marker.enabled = false
        lineSeries.marker = marker
        
        options.series = [lineSeries]
        
        
        return options
    }
    
    private var historicalChartOptions: HIOptions {
        let options = HIOptions()
        
        let chart = HIChart()
        chart.type = "stockChart"
        chart.backgroundColor = HIColor(name: "f8f8f8")
        options.chart = chart
        
        return options
    }
    
    private var recommendationChartOptions: HIOptions {
        let options = HIOptions()
        
        let chart = HIChart()
        chart.type = "column"
        options.chart = chart
        
        let title = HITitle()
        title.text = "Recommendation Trends"
        options.title = title
        
        let xAxis = HIXAxis()
        xAxis.categories = recommendationsData.map { String($0.period.prefix(7)) }
        options.xAxis = [xAxis]
        
        let yAxis = HIYAxis()
        yAxis.tickInterval = 20
        yAxis.min = 0
        yAxis.title = HITitle()
        yAxis.title.text = "#Analysis"
        yAxis.title.align = "high"
        options.yAxis = [yAxis]
        
        let tooltip = HITooltip()
        tooltip.shared = true
        options.tooltip = tooltip
        
        let plotOptions = HIPlotOptions()
        let column = HIColumn()
        column.stacking = "normal"
        
        let dataLabels = HIDataLabels()
        dataLabels.enabled = true
        
        dataLabels.color = "white"
        dataLabels.format = "{point.y:.0f}"
        
        let style = HICSSObject()
        style.fontWeight = "bold"
        style.textOutline = "1px black"
        dataLabels.style = style
        
        column.dataLabels = [dataLabels]
        plotOptions.column = column
        options.plotOptions = plotOptions
        
        
        let seriesData = [
            ("Strong Buy", "#197940", recommendationsData.map { $0.strongBuy }),
            ("Buy", "#1ec160", recommendationsData.map { $0.buy }),
            ("Hold", "#c3951f", recommendationsData.map { $0.hold }),
            ("Sell", "#ec686a", recommendationsData.map { $0.sell }),
            ("Strong Sell", "#8b3737", recommendationsData.map { $0.strongSell })
        ]
        
        options.series = seriesData.map { item in
            let series = HISeries()
            series.name = item.0
            series.data = item.2.map { HIPoint()
                let point = HIPoint()
                point.y = NSNumber(value: $0)
                return point
            }
            series.color = HIColor(hexValue: String(item.1.dropFirst()))
            return series
        }
        
        return options
        
    }
    
    private var epsChartOptions: HIOptions {
        let options = HIOptions()
        
        let chart = HIChart()
        chart.type = "spline"
        options.chart = chart
        
        let title = HITitle()
        title.text = "Historical EPS Surprises"
        options.title = title
        
        let xAxis = HIXAxis()
        xAxis.categories = earningsData.map { "\($0.period) <br> Surprise: \($0.surprise)" }
        let labels = HILabels()
        let style = HICSSObject()
        style.fontSize = "12px"
        style.whiteSpace = "normal"
        labels.style = style
        xAxis.labels = labels
        options.xAxis = [xAxis]
        
        let yAxis = HIYAxis()
        yAxis.min = 1
        yAxis.title = HITitle()
        yAxis.title.text = "Quaterly EPS"
        options.yAxis = [yAxis]
        
        let tooltip = HITooltip()
        tooltip.shared = true
        options.tooltip = tooltip
        
        let actualSeries = HISpline()
        actualSeries.name = "Actual"
        actualSeries.data = earningsData.map { NSNumber(value: $0.actual) }
        
        let estimateSeries = HISpline()
        estimateSeries.name = "Estimate"
        estimateSeries.data = earningsData.map { NSNumber(value: $0.estimate) }
        
        options.series = [actualSeries, estimateSeries]
        
        return options
        
    }
    
    @State private var companyData: CompanyProfileData?
    @State private var quoteData: QuoteData?
    @State private var peersData: [String]?
    @State private var insiderSentiments: InsiderSentiments?
    @State private var sentimentsData: [SentimentData?] = []
    @State private var earningsData: [EarningsData] = []
    @State private var recommendationsData: [RecommendationData] = []
    @State private var portfolioData: PortfolioItem?
    @State private var newsData: [CompanyNewsItem] = []
    @State private var selectedNews: CompanyNewsItem? = nil
    @State private var hourlyChartData: HourlyChartData?
    @State private var chartData: ChartData?
    @State private var isLoading = true
    @State private var showingSheet = false
    @State private var selectedArticle: CompanyNewsItem?
    @State private var showingTradeSheet = false
    @State private var inWatchlist: Bool = false
    @State private var toast: Toast? = nil
    @State private var showToast: Bool = false
    
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading) {
                if isLoading {
                    Spacer()
                    ProgressView("Fetching Data...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    Spacer()
                }
                else {
                    if let company = companyData {
                        HStack(alignment: .top, spacing: 10) {
                            
                            VStack(alignment: .leading) {
                                Text(company.ticker)
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text(company.name)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            AsyncImage(url: URL(string: company.logo)) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 50, height: 50)
                            .padding(.top, 5)
                        }
                        
                    } else {
                        Text("Failed to load company details.")
                    }
                    if let quote = quoteData {
                        HStack{
                            Text(String(format: "$%.2f", quote.c))
                                .font(.title)
                                .fontWeight(.bold)
                            Image(systemName: quote.d >= 0 ? "arrow.up.forward" : "arrow.down.forward")
                                .resizable()
                                .frame(width: 15, height: 15)
                                .foregroundColor(quote.d >= 0 ? .green : .red)
                            
                            Text(String(format: "$%.2f", quote.d))
                                .foregroundColor(quote.d >= 0 ? .green : .red)
                            
                            Text("(\(String(format: "$%.2f", quote.dp))%)")
                                .foregroundColor(quote.d >= 0 ? .green : .red)
                        }
                        
                        TabView {
                            ChartView(options: hourlyChartOptions)
                                .tabItem {
                                    Label("Hourly", systemImage: "chart.xyaxis.line")
                                }
                                .frame(height: 420)
                            
                            WebView(resourceName: "chart")
                                .tabItem {
                                    Label("Historical", systemImage: "clock")
                                }
                                .frame(height: 420)
                        }
                        .frame(height: 450)
                    }
                    if let portfolio = portfolioData {
                        Section(header: Text("Portfolio").font(.title)) {
                            HStack(alignment: .top, spacing: 20) {
                                VStack(alignment: .leading) {
                                    let diff = (quoteData?.c ?? 0.00) - (Double(portfolio.buyPrice) ?? 0.00)
                                    let price = diff * (Double(portfolio.quantity) ?? 0.00)

                                    Text("Shares Owned: ")
                                        .font(.headline) + Text("\(portfolio.quantity)")
                                    Text("Avg. Cost/Share: ")
                                        .font(.headline) + Text("$\(portfolio.buyPrice)")
                                    Text("Total Price: ")
                                        .font(.headline) + Text("\(portfolio.buyTotal)")
                                    Text("Change: ")
                                        .font(.headline) + Text(changeText(price: price, diff: diff))
                                    Text("Market Value: ")
                                        .font(.headline) + Text(marketValueText(portfolio: portfolio, price: quoteData?.c ?? 0.0, diff: diff))
                                }
                                
                                Button(action: {
                                    showingTradeSheet = true
                                    print("Trade button tapped!")
                                }) {
                                    Text("Trade")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .frame(width: 150, height: 50)
                                        .background(Color.green)
                                        .cornerRadius(22)
                                }.frame(maxHeight: .infinity)
                                    .sheet(isPresented: $showingTradeSheet) {
                                        PortfolioView(symbol: symbol, name: companyData?.name ?? "", current_price: quoteData?.c ?? 0.00, shares_owned:portfolio.quantity ?? "0")
                                    }
                                
                            }
                        }
                        .padding(.vertical, 5)
                    } else {
                        Section(header: Text("Portfolio").font(.title)) {
                            HStack(alignment: .top, spacing: 20) {  // Ensures vertical alignment at top and spacing between elements
                                VStack(alignment: .leading) {
                                    Text("You have 0 shares of \(symbol). Start trading!")
                                }
                                
                                Button(action: {
                                    showingTradeSheet = true
                                }) {
                                    Text("Trade")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .frame(width: 150, height: 50)
                                        .background(Color.green)
                                        .cornerRadius(22)
                                }.frame(maxHeight: .infinity)
                                    .sheet(isPresented: $showingTradeSheet) {
                                        PortfolioView(symbol: symbol, name: companyData?.name ?? "", current_price: quoteData?.c ?? 0.00, shares_owned: "0")
                                    }
                                
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    if let quote = quoteData {
                        Section(header: Text("Stats").font(.title)) {
                            HStack{
                                VStack{
                                    Text("High Price: ")
                                        .font(.subheadline)
                                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                        .padding(.vertical, 1)
                                    Text("Low Price: ")
                                        .font(.subheadline)
                                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                        .padding(.vertical, 1)
                                    
                                }
                                VStack {
                                    Text("\(String(format: "$%.2f", quote.h))")
                                        .font(.subheadline)
                                        .padding(.vertical, 1)
                                    Text("\(String(format: "$%.2f", quote.l))")
                                        .font(.subheadline)
                                        .padding(.vertical, 1)
                                }
                                Spacer()
                                VStack{
                                    Text("Open Price: ")
                                        .font(.subheadline)
                                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                        .padding(.vertical, 1)
                                    
                                    Text("Prev. Close: ")
                                        .font(.subheadline)
                                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                        .padding(.vertical, 1)
                                }
                                VStack {
                                    Text("\(String(format: "$%.2f", quote.o))")
                                        .font(.subheadline)
                                        .padding(.vertical, 1)
                                    Text("\(String(format: "$%.2f", quote.pc))")
                                        .font(.subheadline)
                                        .padding(.vertical, 1)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    if let company = companyData {
                        Section(header: Text("About").font(.title)) {
                            HStack() {
                                VStack(alignment: .leading) {
                                    Text("IPO Start Date: ")
                                        .font(.subheadline)
                                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                        .padding(.vertical, 1)
                                    Text("Industry: ")
                                        .font(.subheadline)
                                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                        .padding(.vertical, 1)
                                    Text("Webpage: ")
                                        .font(.subheadline)
                                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                        .padding(.bottom, 2)
                                    Text("Company Peers: ")
                                        .font(.subheadline)
                                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                        .padding(.vertical, 1)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("\(company.ipo)")
                                        .font(.subheadline)
                                        .padding(.vertical, 1)
                                    Text("\(company.finnhubIndustry)")
                                        .font(.subheadline)
                                        .padding(.vertical, 1)
                                    Link(company.weburl, destination: URL(string: company.weburl)!)
                                        .font(.subheadline)
                                        .padding(.vertical, 1)
                                    if let peers = peersData {
                                        HStack {
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack() {
                                                    ForEach(peers, id: \.self) { peer in
                                                        NavigationLink(destination: StockDetailsView(symbol: peer)) {
                                                            Text("\(peer), ")
                                                                .font(.subheadline)
                                                                .padding(.vertical, -3)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        }
                        .padding(.vertical, 5)
                    }
                    Section(header: Text("Insights").font(.title)) {
                        if let insider = insiderSentiments {
                            VStack {
                                Section(header: Text("Insider Sentiments").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).padding(.vertical, 2)) {
                                    HStack{
                                        VStack{
                                            Text(companyData?.name ?? "")
                                                .fontWeight(.bold)
                                            Divider()
                                            Text("Total")
                                                .fontWeight(.bold)
                                            Divider()
                                            Text("Positive")
                                                .fontWeight(.bold)
                                            Divider()
                                            Text("Negative")
                                                .fontWeight(.bold)
                                            Divider()
                                        }
                                        VStack {
                                            Text("MSPR")
                                                .fontWeight(.bold)
                                            Divider()
                                            Text(String(format: "%.2f", insider.avgMspr))
                                            Divider()
                                            Text(String(format: "%.2f", insider.positiveMspr))
                                            Divider()
                                            Text(String(format: "%.2f", insider.negativeMspr))
                                            Divider()
                                        }
                                        VStack {
                                            Text("Change")
                                                .fontWeight(.bold)
                                            Divider()
                                            Text(String(format: "%.2f", insider.avgChange))
                                            Divider()
                                            Text(String(format: "%.2f", insider.positiveChange))
                                            Divider()
                                            Text(String(format: "%.2f", insider.negativeChange))
                                            Divider()
                                        }
                                    }
                                }.padding(.vertical, 5)
                                Section() {
                                    ChartView(options: recommendationChartOptions)
                                        .frame(height: 400)
                                } .padding(.vertical, 5)
                                Section() {
                                    ChartView(options: epsChartOptions)
                                        .frame(height: 400)
                                } .padding(.vertical, 5)
                            }
                            
                        }
                    }.padding(.vertical, 5)
                    Section(header: Text("News").font(.title)) {
                        VStack(spacing: 12) {
                            if let firstArticle = newsData.first {
                                FirstArticleView(article: firstArticle).onTapGesture {
                                    self.selectedArticle = firstArticle
                                    self.showingSheet = true
                                }.sheet(isPresented: $showingSheet) {
                                        SheetView(news: firstArticle)
                                }
                            }
                            Divider()
                            ForEach(newsData.dropFirst(), id: \.id) { article in
                                ArticleView(article: article).onTapGesture {
                                    self.selectedArticle = article
                                    self.showingSheet = true
                                }.sheet(isPresented: $showingSheet) {
                                        SheetView(news: article)
                                }
                            }
                        }
                    }
                }
            }
            .toastView(toast: $toast)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.horizontal, 10)
            .onAppear {
                    Task {
                        do {
                            isLoading = true
                            let companyDetails = try await fetchCompanyDetails(for: symbol)
                            DispatchQueue.main.async {
                                self.companyData = companyDetails.companyProfileData
                                self.quoteData = companyDetails.quotesData
                                self.peersData = companyDetails.peersData
                            }
                            
                            let newsData = try await fetchCompanyNews(for: symbol)
                            DispatchQueue.main.async {
                                self.newsData = newsData
                            }

                            let chartData = try await fetchHourlyChartData(for: symbol)
                            DispatchQueue.main.async {
                                self.hourlyChartData = chartData
                            }
                            
                            let sentimentsDetails = try await fetchSentimentsDetails(for: symbol)
                            DispatchQueue.main.async {
                                self.insiderSentiments = sentimentsDetails.insiderSentiments
                                self.earningsData = sentimentsDetails.earningsData
                                self.recommendationsData = sentimentsDetails.recommendationsData
                            }
                            
                            let portfolioData = try await fetchOnePortfolioData(for: symbol)
                            DispatchQueue.main.async {
                                self.portfolioData = portfolioData
                            }

                            let isInWatchlist = try await checkWatchlistData(for: symbol)
                            DispatchQueue.main.async {
                                self.inWatchlist = isInWatchlist
                            }
                        } catch {
                            print("Error loading data: \(error)")
                        }
                        isLoading = false
                    }
            }
            .navigationTitle(symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if inWatchlist {
                            deleteWatchlistData(for: symbol)
                        } else {
                            addToWatchlist(symbol: symbol)
                        }
                    }) {
                        Image(systemName: inWatchlist ? "plus.circle.fill" : "plus.circle")
                    }
                }
            }
        }
        .toastView(toast: $toast)
    }
    
    func changeText(price: Double, diff: Double) -> AttributedString {
        var str = AttributedString("\(String(format: "$%.2f", price))")
        if let range = str.range(of: String(format: "$%.2f", price)) {
            str[range].foregroundColor = colorForValue(diff)
        }
        return str
    }
    
    func marketValueText(portfolio: PortfolioItem, price: Double, diff: Double) -> AttributedString {
        let value = (price ?? 0.00) * (Double(portfolio.quantity) ?? 0.00)
        var str = AttributedString("\(String(format: "$%.2f", value))")
        if let range = str.range(of: String(format: "$%.2f", value)) {
            str[range].foregroundColor = colorForValue(diff)
        }
        return str
    }
    
    private func colorForValue(_ diff: Double) -> Color {
        if diff > 0 {
            return .green
        } else if diff < 0 {
            return .red
        } else {
            return .gray
        }
    }
    
    func fetchCompanyDetails(for symbol: String) async throws -> CompanyDetailsResponse {
        let urlString = "https://clean-yew-418817.uc.r.appspot.com/company_data?symbol=\(symbol)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(CompanyDetailsResponse.self, from: data)
    }

    func fetchChartDetails(for symbol: String) async throws -> ChartData {
        let urlString = "https://clean-yew-418817.uc.r.appspot.com/chart_data?symbol=\(symbol)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(ChartData.self, from: data)
    }

    func fetchOnePortfolioData(for symbol: String) async throws -> PortfolioItem {
        let urlString = "https://clean-yew-418817.uc.r.appspot.com/select_ticker_stock_data?symbol=\(symbol)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(PortfolioItem.self, from: data)
    }

    func fetchSentimentsDetails(for symbol: String) async throws -> CompanyInsights {
        let urlString = "https://clean-yew-418817.uc.r.appspot.com/company_insights?symbol=\(symbol)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(CompanyInsights.self, from: data)
    }

    func fetchCompanyNews(for symbol: String) async throws -> [CompanyNewsItem] {
        let urlString = "https://clean-yew-418817.uc.r.appspot.com/company_news?symbol=\(symbol)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([CompanyNewsItem].self, from: data)
    }

    func fetchHourlyChartData(for symbol: String) async throws -> HourlyChartData {
        let urlString = "https://clean-yew-418817.uc.r.appspot.com/hourly_chart_data?symbol=\(symbol)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("chart error")
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode == 200 {
//                if let json = String(data: data, encoding: .utf8) {
//                    print("Received chart JSON string: \(json)")
//                }
                return try JSONDecoder().decode(HourlyChartData.self, from: data)
            } else {
                print("Received non-200 HTTP status code")
                throw URLError(.badServerResponse)
            }
        
        return try JSONDecoder().decode(HourlyChartData.self, from: data)
    }

    func checkWatchlistData(for symbol: String) async throws -> Bool {
        let urlString = "https://clean-yew-418817.uc.r.appspot.com/select_data"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let watchlistItems = try JSONDecoder().decode([WatchlistItem].self, from: data)
        return watchlistItems.contains { $0.symbol == symbol }
    }
    
    func deleteWatchlistData(for symbol: String) {
        guard let url = URL(string: "https://clean-yew-418817.uc.r.appspot.com/remove_data?symbol=\(symbol)") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error deleting watchlist data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
//            if let jsonString = String(data: data, encoding: .utf8) {
//                    print("Received data as string: \(jsonString)")
//            }
            
            do {
                try JSONDecoder().decode([WatchlistItem].self, from: data)
                self.inWatchlist = false
                self.toast = Toast(message: "Removing \(symbol) from Favorites", duration: 3)
                self.showToast = true

            } catch {
                print("Error decoding watchlist data: \(error.localizedDescription)")
            }
            self.inWatchlist = false
            self.toast = Toast(message: "Removing \(symbol) from Favorites", duration: 3)
            self.showToast = true
        }.resume()
    }
    
    func addToWatchlist(symbol: String) {
        let urlString = "https://clean-yew-418817.uc.r.appspot.com/insert_watchlist_data?symbol=\(symbol)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("No data received or bad status code")
                return
            }
            self.inWatchlist = true
            self.toast = Toast(message: "Adding \(symbol) to Favorites", duration: 3)
            self.showToast = true
            print("Data inserted successfully")
            DispatchQueue.main.async {
                self.inWatchlist = true
                self.toast = Toast(message: "Adding \(symbol) to Favorites", duration: 3)
                self.showToast = true
            }
        }.resume()
        self.inWatchlist = true
        self.toast = Toast(message: "Adding \(symbol) to Favorites", duration: 3)
        self.showToast = true
    }


    func convertToJSONData<T: Encodable>(_ value: T) -> Data? {
        return try? JSONEncoder().encode(value)
    }
    
    func convertToJSONString<T: Encodable>(_ value: T) -> String? {
        guard let data = convertToJSONData(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func dateString(from unixTime: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}

struct FirstArticleView: View {
    var article: CompanyNewsItem
    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: article.image)) { image in
                image.resizable()
            } placeholder: {
                Color.gray
            }
            .aspectRatio(contentMode: .fill)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack {
                Text(article.source)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(0)
                    .fontWeight(.bold)
                Text(timeDifference(from: TimeInterval(article.datetime)))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(0)
            }

            Text(article.headline)
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 3)
    }
    
    func timeDifference(from epochTime: TimeInterval) -> String {
        let targetDate = Date(timeIntervalSince1970: epochTime)
        let now = Date()
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.hour, .minute], from: targetDate, to: now)
        
        // Handle optional components safely
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        // Create a formatted string
        var result = ""
        if hours > 0 {
            result += "\(hours)hr, "
        }
        if minutes > 0 {
            result += "\(minutes) min"
        }
        
        return result.isEmpty ? "Just now" : result
    }
}

struct ArticleView: View {
    var article: CompanyNewsItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(article.source)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(0)
                        .fontWeight(.bold)
                    Text(timeDifference(from: TimeInterval(article.datetime)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(0)
                }
                Text(article.headline)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .padding(0)
            }.padding(0)

            AsyncImage(url: URL(string: article.image)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(0)
        }
    }
    
    func timeDifference(from epochTime: TimeInterval) -> String {
        let targetDate = Date(timeIntervalSince1970: epochTime)
        let now = Date()
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.hour, .minute], from: targetDate, to: now)
        
        // Handle optional components safely
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        // Create a formatted string
        var result = ""
        if hours > 0 {
            result += "\(hours) hr, "
        }
        if minutes > 0 {
            result += "\(minutes) min"
        }
        
        return result.isEmpty ? "Just now" : result
    }
}

struct ChartView: UIViewRepresentable {
    var options: HIOptions
    
    func makeUIView(context: Context) -> HIChartView {
        let chartView = HIChartView()
        chartView.options = options
        return chartView
    }
    
    func updateUIView(_ uiView: HIChartView, context: Context) {
        uiView.options = options
    }
}

struct SheetView: View {
    @Environment(\.dismiss) var dismiss
    var news: CompanyNewsItem
    let twitterLogoURL = "https://img.freepik.com/free-vector/twitter-new-2023-x-logo-white-background-vector_1017-45422.jpg?size=338&ext=jpg&ga=GA1.1.1700460183.1713052800&semt=ais"
    
    let facebookLogoURL = "https://cdn.logojoy.com/wp-content/uploads/20230921104408/Facebook-logo-600x319.png"
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
              Spacer()
              Button(action: {
                dismiss()
              }) {
                Image(systemName: "xmark")
                      .foregroundColor(.black)
                      .padding()
              }
            }
            Text(news.source)
                .font(.title2)
                .bold()
                .foregroundColor(.primary)
                .padding(.vertical, 0)
            
            Text(dateString(from: news.datetime))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text(news.headline)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(news.summary)
                .font(.subheadline)
                .padding(.top, 0)
            
            HStack {
                Text("For more details, click")
                    .font(.subheadline)
                    .padding(.top, 0)
                    .foregroundColor(.gray)
                Link("here", destination: URL(string: news.url)!)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Button(action: {
                    openTwitter()
                }) {
                    if let url = URL(string: twitterLogoURL) {
                        AsyncImage(url:url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }.padding()
                    .clipShape(Circle())
                
                // Dismiss button
                Button(action: {
                    openFacebook()
                }) {
                    if let url = URL(string: facebookLogoURL) {
                        AsyncImage(url:url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .padding(.horizontal, -20)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }.padding()
                    .clipShape(Circle())
            }
            Spacer()
        }
        .padding()
    }
    
    func openTwitter() {
        let twitterUrl = "https://twitter.com/intent/tweet"
        let text = news.headline
        let postUrl = news.url
        guard let url = URL(string: "\(twitterUrl)?text=\(text)&url=\(postUrl)") else { return }
        
        // Check if the device is able to open the URL
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print("Cannot open Twitter")
        }
    }
    
    func openFacebook() {
        let facebookURL = "https://www.facebook.com/sharer/sharer.php"
        let postUrl = news.url
        guard let url = URL(string: "\(facebookURL)?u=\(postUrl)") else { return }
        
        // Check if the device is able to open the URL
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print("Cannot open Facebook")
        }
    }
    
    func dateString(from unixTime: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        return dateFormatter.string(from: date)
    }
}

struct PortfolioView: View {
    let symbol: String
    let name: String
    let current_price: Double
    let shares_owned: String
    @State private var quantity: String = ""
    @State private var walletAmount: Double?
    @State private var showDialog = false
    @State private var toast: Toast? = nil
    @State private var showToast: Bool = false
    @State private var sold = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    Text("Trade \(name) shares")
                        .font(.headline)
                        .padding()
                    Spacer()
                    HStack {
                        TextField("0", text: $quantity)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 80))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100, alignment: .trailing)
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(quantity == "0" || quantity == "1" || quantity == "" ? "Share" : "Shares")
                                .font(.title)
                                .padding()
                            Text("x \(String(format: "$%.2f", current_price))/share = \(String(format: "$%.2f", calculatedValue))")
                        }
                        .padding(.trailing, 20)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    
                    Spacer()
                    Text("\(String(format: "$%.2f", walletAmount ?? 0.00)) available to buy \(symbol)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Button("Buy") {
                            handleTrade(ticker: symbol, name: name, currentPrice: current_price, quantity: quantity ?? "0", total: calculatedValue, action: "buy")
                        }
                        .buttonStyle(CustomActionButton())
                        
                        Button("Sell") {
                            handleTrade(ticker: symbol, name: name, currentPrice: current_price, quantity: quantity ?? "0", total: calculatedValue, action: "sell")
                        }
                        .buttonStyle(CustomActionButton())
                    }
                    .padding()
                }.toastView(toast: $toast)
                
                if showDialog {
                    Color.green.opacity(1)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Spacer()
                        
                        Text("Congratulations!")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                        
                        Text(sold ? "You have successfully sold \(quantity) \(quantity == "0" || quantity == "1" ? "share" : "shares") of \(symbol)" : "You have successfully bought \(quantity) \(quantity == "0" || quantity == "1" ? "share" : "shares") of \(symbol)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()

                        Spacer()
                        
                        Button(action: {
                            showDialog = false
                        }) {
                            Text("Done")
                                .foregroundColor(.green)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(20)
                        }.padding(.horizontal, 20)
                    }
                }
                
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {dismiss()}) {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .onAppear {
            fetchWalletAmount()
        }
    }
    
    var calculatedValue: Double {
        (Double(quantity) ?? 0) * current_price
    }
    
    func handleTrade(ticker: String, name: String, currentPrice: Double, quantity: String, total: Double, action: String) {
        
        if quantity.allSatisfy({ $0.isLetter }) {
            toast = Toast(message: "Please enter a valid amount", duration: 3)
            showToast = true
            return
        }
        
        if Int(quantity) ?? 0 <= 0 {
            toast = Toast(message: "Cannot \(action) non-positive shares", duration: 3)
            showToast = true
            return
        }
        
        switch action {
        case "buy":
            if total > (walletAmount ?? 0.00) {
                toast = Toast(message: "Not enough money to buy", duration: 2)
                showToast = true
            } else {
                updatePortfolioData(ticker: ticker, name: name, currentPrice: currentPrice, quantity: String(quantity), total: total, buyOrSell: "buy")
            }
        case "sell":
            if Double(quantity) ?? 0.00 > Double(shares_owned) ?? 0.00 {
                toast = Toast(message: "Not enough shares to sell", duration: 2)
                self.sold = true
                showToast = true
            } else {
                updatePortfolioData(ticker: ticker, name: name, currentPrice: currentPrice, quantity: String(quantity), total: total, buyOrSell: "sell")
            }
        default:
            break
        }
    }
    
    
    func fetchWalletAmount() {
        guard let url = URL(string: "https://clean-yew-418817.uc.r.appspot.com/get_wallet_money") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching wallet amount: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let walletInfo = try JSONDecoder().decode(WalletInfo.self, from: data)
                //                print("Received walletInfo: \(walletInfo)")
                DispatchQueue.main.async {
                    self.walletAmount = walletInfo.wallet
                }
            } catch {
                print("Error decoding wallet data: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func updatePortfolioData(ticker: String, name: String, currentPrice: Double, quantity: String, total: Double, buyOrSell: String) {
        print(type(of: quantity))
        let queryString = "ticker=\(ticker)&name=\(name)&price=\(currentPrice)&quantity=\(quantity)&total=\(total)&buyOrSell=\(buyOrSell)"
        
        guard let encodedString = queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://clean-yew-418817.uc.r.appspot.com/insert_stock_data?\(encodedString)") 
                
        else {
            print("Invalid URL")
            return
        }
        print(url)
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching portfolio data: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
//                print("Received data: \(responseString)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showDialog = true
                }
            } else {
                print("Error decoding updated portfolio data")
                
            }
        }.resume()
    }
}

struct CustomActionButton: ButtonStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .frame(width: 150, height: 50)
            .background(.green)
            .cornerRadius(22)
    }
}


