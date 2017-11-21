
class BadMarketNameError < StandardError
  attr_reader :name
  def initialize(message, name)
    @name = name
    super(message)
  end
end


class Market
  class << self

    def supported_base?(market)
      %w[BTC ETH].include?(market.split('-')[-1])
    end

    def parse_base(name)
      base = /BTC$|ETH$|LTC$|EUR$|CAD$|GBP$|JPY$|USD$|USTD$|USDT$|BNB$/.match(name).to_s
      if base.to_s.strip.empty?
        raise BadMarketNameError.new("Poorly formatted Market name: #{name}", name)
      end
      crypto = name.sub(base, '')
      [crypto, base]
    end
  end
end
