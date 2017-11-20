
require './app/currency_converter'
require 'pry'
require 'json'
class OrderBook
  attr_accessor :bids, :asks, :market, :base
  def initialize(exchange, market)
    @market = market
    @exchange = exchange
    @base = market.split('-')[-1]
    self
  end

  def load
    data = JSON.parse(open("./exchange_data/#{@exchange}/#{@market}.json").read)
    @bids = data["bids"]
    @asks = data["asks"]
    self
  end

  def empty?
    @bids.empty? && @asks.empty?
  end

  def buy(amount_to_buy_usd)
    total_bought_usd = 0.0
    prices = []
    quantities = []
    @asks.each do |ask|
      #binding.pry
      price_usd = CurrencyConverter.to_usd(ask["price"], @base)
      amount_left_to_buy_usd = amount_to_buy_usd - total_bought_usd
      # buy enough so that we hit amount_to_buy_usd
      quantity_to_buy = amount_left_to_buy_usd / price_usd
      quantity_to_buy = [quantity_to_buy, ask["quantity"]].min
      total_bought_usd += price_usd * quantity_to_buy
      prices.push(price_usd)
      quantities.push(quantity_to_buy)
      if total_bought_usd >= amount_to_buy_usd
        break
      end
    end
    average_price = calcAveragePrice(prices, quantities)
    {average_price: average_price, total_quantity: quantities.sum}
  end

  def calcAveragePrice(prices, quantities)
    sumproduct = 0.0
    prices.each_with_index do |price, i|
      sumproduct += price * quantities[i]
    end
    sumproduct / quantities.sum
  end

end

if __FILE__ == $0
  book = OrderBook.new('cryptopia', 'CTR-BTC')
  p book.buy(6000)

end
