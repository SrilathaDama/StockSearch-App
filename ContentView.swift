//
//  ContentView.swift
//  StocksApp
//
//  Created by Swathi Asok on 4/9/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel = ViewModel()
    
    @State private var isLoading = false
    
    @State private var searchText: String = ""
    @State private var date: Date = Date()
    
    @State private var walletAmount: Double?
    @State private var portfolioItems: [PortfolioItem] = []
    @State var watchlistItems: [WatchlistItem] = []
    @State private var currentQuoteData: QuoteData?
    
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading{
                    Spacer()
                    ProgressView("Fetching Data...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    Spacer()
                }
                else {
                    List {
                        ForEach(viewModel.searchResults, id: \.self) { result in
                            NavigationLink(destination: StockDetailsView(symbol: result.symbol)) {
                                VStack(alignment: .leading) {
                                    Text(result.displaySymbol).font(.headline)
                                    Text(result.description).font(.subheadline).foregroundColor(.gray)
                                }
                            }
                        }
                        if searchText.isEmpty {
                            Text(Date.now, format: .dateTime.month().day().year())
                                .font(.system(size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            Section (
                                header: Text("Portfolio")
                            ){
                                HStack {
                                    VStack(alignment: .leading) {
                                        let totalBuyTotal = portfolioItems.reduce(0.0) { $0 + (Double($1.buyTotal) ?? 0.0) }
                                        let netWorth = (walletAmount ?? 0.0) + totalBuyTotal
                                        
                                        Text("Net Worth")
                                        Text(String(format: "$%.2f", netWorth))
                                            .fontWeight(.bold)
                                    }
                                    Spacer()
                                    VStack(alignment: .leading) {
                                        Text("Cash Balance")
                                        if let amount = walletAmount {
                                            Text(String(format: "$%.2f", amount))
                                                .fontWeight(.bold)
                                        }
                                    }
                                }
                                ForEach(portfolioItems, id: \.symbol) { item in
                                    NavigationLink(destination: StockDetailsView(symbol: item.symbol)) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(item.symbol)
                                                    .fontWeight(.bold)
                                                Text("\(String(item.quantity)) shares")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            if let quoteData = item.quoteData {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(String(format: "$%.2f", quoteData.c * (Double(item.quantity) ?? 0.00)))
                                                        .foregroundColor(.primary)
                                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                                    HStack {
                                                        let diff = (quoteData.c) - (Double(item.buyPrice) ?? 0.00)
                                                        let price = diff * (Double(item.quantity) ?? 0.00   )
                                                        let percent = (price / quoteData.c) * 100
                                                        
                                                        if symbolName(for: diff) != "minus" {
                                                            Image(systemName: symbolName(for: diff))
                                                                .resizable()
                                                                .frame(width: 15, height: 15)
                                                                .foregroundColor(colorForValue(diff))
                                                        }
                                                        else {
                                                            Image(systemName: symbolName(for: diff))
                                                                .resizable()
                                                                .frame(width: 10, height: 3)
                                                                .foregroundColor(colorForValue(diff))
                                                        }
                                                        
                                                        
                                                        
                                                        Text(String(format: "$%.2f", price))
                                                            .foregroundColor(colorForValue(diff))
                                                        
                                                        Text("(\(String(format: "%.2f%%", percent)))") // Fixed the format string
                                                            .foregroundColor(colorForValue(diff))
                                                    }
                                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                                }
                                                
                                            } else {
                                                Text("Loading...")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .onDrag {
                                        NSItemProvider(object: String(item.symbol) as NSString)
                                    }
                                }
                                .onDelete(perform: deletePortfolio)
                                .onMove(perform: movePortfolio)
                            }
                            Section(
                                header: Text("Favorites")
                            ){
                                ForEach(watchlistItems, id: \.symbol) { item in
                                    NavigationLink(destination: StockDetailsView(symbol: item.symbol)) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(item.symbol)
                                                    .fontWeight(.bold)
                                                Text(item.name ?? "")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            if let quoteData = item.quoteData {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(String(format: "$%.2f", quoteData.c))
                                                        .foregroundColor(.primary)
                                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                                    HStack {
                                                        Image(systemName: symbolName(for: quoteData.d))
                                                            .resizable()
                                                            .frame(width: 15, height: 15)
                                                            .foregroundColor(colorForValue(quoteData.d))
                                                        Text(String(format: "$%.2f", quoteData.d))
                                                            .foregroundColor(colorForValue(quoteData.d))
                                                        Text("(\(String(format: "%.2f", quoteData.dp))%)")
                                                            .foregroundColor(colorForValue(quoteData.d))
                                                    }.frame(maxWidth: .infinity, alignment: .trailing)
                                                }
                                            } else {
                                                Text("Loading...")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .onDrag {
                                        NSItemProvider(object: String(item.symbol) as NSString)
                                    }
                                }
                                .onDelete(perform: deleteWatchlist)
                                .onMove(perform: moveWatchlist)
                                
                            }
                            Link("Powered by Finnhub.io",
                                 destination: URL(string: "https://finnhub.io")!)
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.gray)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    do {
                        isLoading = true
                        walletAmount = try await fetchWalletAmount()
                        portfolioItems = try await fetchPortfolioData()
                        watchlistItems = try await fetchWatchlistData()
                        isLoading = false
                    } catch {
                        print("Error fetching data: \(error)")
                    }
                }
            }
            .navigationTitle("Stocks")
            .searchable(text: $searchText)
            .onChange(of: searchText) { newValue in
                viewModel.searchSymbols(query: newValue)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func symbolName(for diff: Double) -> String {
            if diff > 0 {
                return "arrow.up.forward"
            } else if diff < 0 {
                return "arrow.down.forward"
            } else {
                return "minus" // Symbol for no change
            }
        }

        // Determines the color based on `diff`
        private func colorForValue(_ diff: Double) -> Color {
            if diff > 0 {
                return .green
            } else if diff < 0 {
                return .red
            } else {
                return .gray // Neutral color for no change
            }
        }
    
    func fetchWatchlistData() async throws -> [WatchlistItem] {
        let urlString = "https://clean-yew-418817.uc.r.appspot.com/select_data"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let watchlistItems = try JSONDecoder().decode([WatchlistItem].self, from: data)
        
        // Fetch quote data and company data for each watchlist item asynchronously
        await withTaskGroup(of: Void.self) { group in
            for item in watchlistItems {
                group.addTask {
                    await self.fetchQuoteData(for: item.symbol)
                    await self.fetchCompanyData(for: item.symbol)
                }
            }
        }
        
        return watchlistItems
    }


    func fetchPortfolioData() async throws -> [PortfolioItem] {
        let urlString = "https://clean-yew-418817.uc.r.appspot.com/select_stock_data"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let portfolioItems = try JSONDecoder().decode([PortfolioItem].self, from: data)
        await withTaskGroup(of: Void.self) { group in
            for item in portfolioItems {
                group.addTask {
                    await self.fetchQuoteData(for: item.symbol)
                }
            }
        }
        
        return portfolioItems
    }


    func fetchWalletAmount() async throws -> Double {
        let urlString = "https://clean-yew-418817.uc.r.appspot.com/get_wallet_money"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let walletInfo = try JSONDecoder().decode(WalletInfo.self, from: data)
        return walletInfo.wallet
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

            } catch {
                print("Error decoding watchlist data: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func fetchCompanyData(for symbol: String) {
            guard let url = URL(string: "https://clean-yew-418817.uc.r.appspot.com/company_data?symbol=\(symbol)") else {
                print("Invalid URL")
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error fetching company data: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
    //                        if let jsonString = String(data: data, encoding: .utf8) {
    //                            print("Received data as string: \(jsonString)")
    //                        }
                
                do {
                    let companyData = try JSONDecoder().decode(CompanyDetailsResponse.self, from: data)
                    DispatchQueue.main.async {
                        
                        if let index = self.watchlistItems.firstIndex(where: { $0.symbol == symbol }) {
                            self.watchlistItems[index].name = companyData.companyProfileData.name
                        }
                    }
                } catch {
                    print("Error decoding company data: \(error.localizedDescription)")
                }
            }.resume()
        }
        
        func fetchQuoteData(for symbol: String) {
            guard let url = URL(string: "https://clean-yew-418817.uc.r.appspot.com/company_data?symbol=\(symbol)") else {
                print("Invalid URL")
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error fetching company data: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                //            if let jsonString = String(data: data, encoding: .utf8) {
                //                print("Received data as string: \(jsonString)")
                //            }
                
                do {
                    let companyData = try JSONDecoder().decode(CompanyDetailsResponse.self, from: data)
                    DispatchQueue.main.async {
                        
                        if let index = self.portfolioItems.firstIndex(where: { $0.symbol == symbol }) {
                            self.portfolioItems[index].quoteData = companyData.quotesData
                        }
                        
                        if let index = self.watchlistItems.firstIndex(where: { $0.symbol == symbol }) {
                            self.watchlistItems[index].quoteData = companyData.quotesData
                        }
                    }
                } catch {
                    print("Error decoding company data: \(error.localizedDescription)")
                }
            }.resume()
        }
            
    
    func deletePortfolio(at offsets: IndexSet) {
        portfolioItems.remove(atOffsets: offsets)
    }
    
    func deleteWatchlist(at offsets: IndexSet) {
        let s = offsets.map { watchlistItems[$0] }
        deleteWatchlistData(for: s[0].symbol)
        print("the wathclist is",
              offsets.map { watchlistItems[$0] })
        watchlistItems.remove(atOffsets: offsets)
    }
    
    func movePortfolio(from source: IndexSet, to destination: Int) {
        portfolioItems.move(fromOffsets: source, toOffset: destination )
    }
    
    func moveWatchlist(from source: IndexSet, to destination: Int) {
        watchlistItems.move(fromOffsets: source, toOffset: destination )
    }
}

struct QuoteDataView: View {
    var quoteData: QuoteData?
    
    var body: some View {
        if let quoteData = quoteData {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "$%.2f", quoteData.c))
                    .foregroundColor(.primary)
                Text(String(format: "$%.2f", quoteData.d))
                    .foregroundColor(quoteData.d >= 0 ? .green : .red)
                Text(String(format: "%.2f%", quoteData.dp))
                    .foregroundColor(quoteData.dp >= 0 ? .green : .red)
            }
        } else {
            Text("Loading...")
                .foregroundColor(.gray)
        }
    }
}

class ViewModel: ObservableObject {
    @Published var searchResults: [Symbol] = []
    
    func searchSymbols(query: String) {
        guard !query.isEmpty, let url = URL(string: "https://clean-yew-418817.uc.r.appspot.com/lookup_symbol?q=\(query)") else {
            self.searchResults = []
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Received data as string: \(jsonString)")
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                DispatchQueue.main.async {
                    self.searchResults = decodedResponse.result
                        .filter { !$0.displaySymbol.contains(".")}
                }
            } catch {
                print("Failed to decode response: \(error)")
            }
        }.resume()
    }
}
