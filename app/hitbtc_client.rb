
require 'open-uri'
require 'json'
require 'httparty'
require 'pry'
require './app/market'


class HitbtcClient
  attr_accessor :url, :exchange, :order_book_url
  def initialize()
    @client_name = 'hitbtc'
    @url = "https://api.hitbtc.com/api/1/public/ticker"
    @order_book_url = "https://api.hitbtc.com/api/1/public/%s/orderbook"
  end

  def market_symbols()
    @market_symbols ||= _market_symbols
  end

  def _market_symbols()
    response = HTTParty.get(url, { timeout: 10 })
    entries = JSON.parse(response.body)
    market_symbols = entries.keys()
    market_symbols = market_symbols.map { |m| Market.parse_base(m).join('-') }
    market_symbols = market_symbols.reject{ |m| !%w[BTC ETH].include?(m.split('-')[-1]) }
  end


  def save_order_book(market)
    url = @order_book_url % market_name_on_service(market)
    response = HTTParty.get(url, { timeout: 10 })
    entries = JSON.parse(response.body)
    bids = entries["bids"]
    asks = entries["asks"]
    order_book = {bids: [], asks: []}
    if !bids || !asks
      p "no bids or asks for #{market}"
      return
    end
    bids.each do |bid|
      order_book[:bids].push({quantity: bid[1], price: bid[0].to_f})
    end
    asks.each do |ask|
      order_book[:asks].push({quantity: ask[1], price: ask[0].to_f})
    end
    order_book[:bids] = order_book[:bids].sort_by { |bid| bid[:price] }.reverse
    order_book[:asks] = order_book[:asks].sort_by { |ask| ask[:price] }

    File.open("./exchange_data/#{@client_name}/#{market}.json", "w") do |f|
      f.write(order_book.to_json)
    end
  end

  def market_name_on_service(market)
    market.sub('-', '')
  end

end


if __FILE__ == $0
  client = HitbtcClient.new
  markets = client.market_symbols
  markets.each do |market|
    p "saving #{market}"
    begin
      client.save_order_book(market)
    rescue Net::OpenTimeout => e
      p "timeout on market #{market}"
    end
  end
  client.save_order_book(markets[0])
end
