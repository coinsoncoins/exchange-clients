
require 'open-uri'
require 'json'
require './app/order_book'
require 'httparty'



class LiquiClient
  attr_accessor :url, :exchange, :order_book_url
  def initialize()
    @url = "https://api.liqui.io/api/3/info"
    @order_book_url = "https://api.liqui.io/api/3/depth/%s"
  end

  def market_symbols()
    @market_symbols ||= _market_symbols
  end

  def _market_symbols()
    response = HTTParty.get(url, { timeout: 10 })
    entries = JSON.parse(response.body)["pairs"]
    market_symbols = entries.keys()
    market_symbols = market_symbols.map { |m| m.upcase.sub('_', '-') }
    market_symbols = market_symbols.reject{ |m| !%w[BTC ETH].include?(m.split('-')[-1]) }
  end

  def save_order_book(market)
    url = @order_book_url % market_name_on_service(market)
    response = HTTParty.get(url, { timeout: 10 })
    entries = JSON.parse(response.body)
    entries = entries[entries.keys.first]
    bids = entries["bids"]
    asks = entries["asks"]
    order_book = {bids: [], asks: []}
    bids.each do |bid|
      order_book[:bids].push({quantity: bid[1], price: bid[0].to_f})
    end
    asks.each do |ask|
      order_book[:asks].push({quantity: ask[1], price: ask[0].to_f})
    end
    order_book[:bids] = order_book[:bids].sort_by { |bid| bid[:price] }.reverse
    order_book[:asks] = order_book[:asks].sort_by { |ask| ask[:price] }

    File.open("./exchange_data/liqui/#{market}.json", "w") do |f|
      f.write(order_book.to_json)
    end
  end

  def market_name_on_service(market)
    market.sub('-', '_').downcase
  end

end


if __FILE__ == $0
  client = LiquiClient.new
  markets = client.market_symbols
  markets.each do |market|
    p "saving #{market}"
    client.save_order_book(market)
  end
  client.save_order_book(markets[0])
end
