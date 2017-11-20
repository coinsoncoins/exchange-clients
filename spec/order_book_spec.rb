
require './app/order_book'


RSpec.describe OrderBook do
  context "#buy" do
    it do
      order_book = OrderBook.new('exchange1', "PPL-BTC")
      order_book.asks = [
        {"quantity" => 100, "price" => 0.000125},
        {"quantity" => 100, "price" => 0.00025},
        {"quantity" => 100, "price" => 0.000375}
      ]
      p order_book.buy(220)
    end
  end
end
