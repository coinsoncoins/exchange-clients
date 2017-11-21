
require 'open-uri'
require 'json'
require 'httparty'
require 'pry'


class BittrexClient
  attr_accessor :url, :exchange, :order_book_url
  def initialize()
    @client_name = 'bittrex'
    @url = "https://bittrex.com/api/v1.1/public/getmarketsummaries"
    @order_book_url = "https://bittrex.com/api/v1.1/public/getorderbook?market=%s&type=both"
  end

  def market_symbols()
    @market_symbols ||= _market_symbols
  end

  def _market_symbols()
    response = HTTParty.get(url, { timeout: 10 })
    entries = JSON.parse(response.body)["result"]
    market_symbols = entries.map { |e| e["MarketName"].split('-').reverse.join('-') }
    market_symbols = market_symbols.reject{ |m| !%w[BTC ETH].include?(m.split('-')[-1]) }
  end


  def save_order_book(market)
    url = @order_book_url % market_name_on_service(market)
    response = HTTParty.get(url, { timeout: 10 })
    entries = JSON.parse(response.body)["result"]
    bids = entries["buy"]
    asks = entries["sell"]
    order_book = {bids: [], asks: []}
    if !bids || !asks
      p "no bids or asks for #{market}"
      return
    end
    bids.each do |bid|
      order_book[:bids].push({quantity: bid["Quantity"], price: bid["Rate"].to_f})
    end
    asks.each do |ask|
      order_book[:asks].push({quantity: ask["Quantity"], price: ask["Rate"].to_f})
    end
    order_book[:bids] = order_book[:bids].sort_by { |bid| bid[:price] }.reverse
    order_book[:asks] = order_book[:asks].sort_by { |ask| ask[:price] }

    File.open("./exchange_data/#{@client_name}/#{market}.json", "w") do |f|
      f.write(order_book.to_json)
    end
  end

  def market_name_on_service(market)
    market.split('-').reverse.join('-')
  end

end


if __FILE__ == $0
  client = BittrexClient.new
  markets = client.market_symbols
  markets.each do |market|
    p "saving #{market}"
    client.save_order_book(market)
  end
  client.save_order_book(markets[0])
end
