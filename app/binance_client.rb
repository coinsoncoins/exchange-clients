
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


def parse_base(name)
  base = /BTC$|ETH$|LTC$|EUR$|CAD$|GBP$|JPY$|USD$|USTD$|USDT$|BNB$/.match(name).to_s
  if base.to_s.strip.empty?
    raise BadMarketNameError.new("Poorly formatted Market name: #{name}", name)
  end
  crypto = name.sub(base, '')
  [crypto, base]
end


class BinanceClient
  attr_accessor :url, :exchange, :order_book_url
  def initialize()
    @url = "https://www.binance.com/api/v1/ticker/allBookTickers"
    @order_book_url = "https://www.binance.com/api/v1/depth?symbol=%s"
  end

  def market_symbols()
    @market_symbols ||= _market_symbols
  end

  def _market_symbols()
    response = HTTParty.get(url, { timeout: 10 })
    entries = JSON.parse(response.body)
    #binding.pry
    market_symbols = entries.map { |e| e["symbol"] }
    market_symbols = market_symbols.reject { |m| m == '123456' || m == 'ETC' } # errors in binance API
    market_symbols = market_symbols.map { |m| parse_base(m).join('-') }
  end

  def save_order_book(market)
    url = @order_book_url % market_name_on_service(market)
    response = HTTParty.get(url, { timeout: 10 })
    entries = JSON.parse(response.body)
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

    File.open("./exchange_data/etherdelta/#{market}.json", "w") do |f|
      f.write(order_book.to_json)
    end
  end

  def market_name_on_service(market)
    market.sub('-', '')
  end

end


if __FILE__ == $0
  client = BinanceClient.new
  markets = client.market_symbols
  markets.each do |market|
    p "saving #{market}"
    client.save_order_book(market)
  end
  client.save_order_book(markets[0])
end
