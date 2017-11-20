
require 'pry'
def get_markets(exchange)
  markets = Dir.foreach("./exchange_data/#{exchange}")
  markets = markets.reject{ |m| m == '.' || m == '..' }
  markets = markets.map { |m| m.sub(".json", '') }
end
cryptopia_markets = get_markets('cryptopia')
binance_markets = get_markets('binance')

cryptopia_markets.each do |market1|
  next if !binance_markets.include?(market1)
  p "exchanges have both market #{market1}"
end

def buy(market, amount_usd) {

}
