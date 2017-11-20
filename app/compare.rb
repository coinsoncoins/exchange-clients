
require 'pry'
require './app/currency_converter'
require './app/order_book'

AMOUNT_TO_BUY_USD = 6000

def get_markets(exchange)
  markets = Dir.foreach("./exchange_data/#{exchange}")
  markets = markets.reject{ |m| m == '.' || m == '..' }
  markets = markets.map { |m| m.sub(".json", '') }
end



def compare_exchanges(exchange1, exchange2)
  markets1 = get_markets(exchange1)
  markets2 = get_markets(exchange2)
  markets1.each do |market|
    next if !markets2.include?(market)
    p "exchanges have both market #{market}"
    book1 = OrderBook.new(exchange1, market).load
    book2 = OrderBook.new(exchange2, market).load
    next if book1.empty? || book2.empty?
    amount_to_buy_usd = AMOUNT_TO_BUY_USD
    r = book1.buy(amount_to_buy_usd)
    average_price = r[:average_price]
    lowest_offer = CurrencyConverter.to_usd(book2.asks[0]["price"], book2.base)
    spread_percent = (lowest_offer - average_price) / average_price * 100.0
    p "#{exchange1}/#{exchange2}: buy #{market} at avg price #{average_price} on and sell at offer #{lowest_offer} for #{'%.1f%' % spread_percent}"
  end
end

compare_exchanges('cryptopia', 'binance')
compare_exchanges('liqui', 'binance')
