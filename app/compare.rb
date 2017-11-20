
require 'pry'
require './app/currency_converter'
require './app/order_book'

def get_markets(exchange)
  markets = Dir.foreach("./exchange_data/#{exchange}")
  markets = markets.reject{ |m| m == '.' || m == '..' }
  markets = markets.map { |m| m.sub(".json", '') }
end
cryptopia_markets = get_markets('cryptopia')
binance_markets = get_markets('binance')

cryptopia_markets.each do |market|
  next if !binance_markets.include?(market)
  p "exchanges have both market #{market}"
  book1 = OrderBook.new('cryptopia', market).load
  book2 = OrderBook.new('binance', market).load
  next if book1.empty? || book2.empty?
  amount_to_buy_usd = 6000
  r = book1.buy(amount_to_buy_usd)
  average_price = r[:average_price]
  binding.pry if market == "ELC-BTC"
  lowest_offer = CurrencyConverter.to_usd(book2.asks[0]["price"], book2.base)
  spread_percent = (lowest_offer - average_price) / average_price * 100.0
  p "buy #{market} at avg price #{average_price} and sell at offer #{lowest_offer} for #{'%.1f%' % spread_percent}"
end
