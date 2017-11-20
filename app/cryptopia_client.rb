
require 'open-uri'
require 'json'
require 'httparty'
require 'pry'


class BadMarketNameError < StandardError
  attr_reader :name
  def initialize(message, name)
    @name = name
    super(message)
  end
end

class CryptopiaClient
  attr_accessor :url, :exchange, :order_book_url
  def initialize()
    @url = "https://www.cryptopia.co.nz/api/GetMarkets"
    @order_book_url = "https://www.cryptopia.co.nz/api/GetMarketOrders/%s"
  end

  def market_symbols()
    @market_symbols ||= _market_symbols
  end

  def _market_symbols()
    response = HTTParty.get(url, { timeout: 10 })

    entries = JSON.parse(response.body)["Data"]
    market_symbols = entries.map { |e| e["Label"].sub('/', '-') }
    market_symbols = market_symbols.reject{ |m| !%w[BTC ETH].include?(m.split('-')[-1]) }
  end


  def save_order_book(market)
    url = @order_book_url % market_name_on_service(market)
    response = HTTParty.get(url, { timeout: 10 })
    entries = JSON.parse(response.body)["Data"]
    bids = entries["Buy"]
    asks = entries["Sell"]
    order_book = {bids: [], asks: []}
    bids.each do |bid|
      order_book[:bids].push({quantity: bid["Volume"], price: bid["Price"].to_f})
    end
    asks.each do |ask|
      order_book[:asks].push({quantity: ask["Volume"], price: ask["Price"].to_f})
    end
    order_book[:bids] = order_book[:bids].sort_by { |bid| bid[:price] }.reverse
    order_book[:asks] = order_book[:asks].sort_by { |ask| ask[:price] }

    File.open("./exchange_data/cryptopia/#{market}.json", "w") do |f|
      f.write(order_book.to_json)
    end
  end

  def market_name_on_service(market)
    market.sub('-', '_')
  end

end


if __FILE__ == $0
  client = CryptopiaClient.new
  markets = client.market_symbols
  markets.each do |market|
    p "saving #{market}"
    client.save_order_book(market)
  end
  client.save_order_book(markets[0])
end
