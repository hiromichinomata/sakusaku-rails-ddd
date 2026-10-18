# 金額（円）。0以上の整数だけを持つ値オブジェクト
class Money
  include Comparable

  attr_reader :yen

  def initialize(yen)
    unless yen.is_a?(Integer) && yen >= 0
      raise ArgumentError, "金額は0以上の整数（円）で指定してください: #{yen.inspect}"
    end

    @yen = yen
    freeze
  end

  def +(other)
    Money.new(yen + other.yen)
  end

  def *(times)
    raise ArgumentError, "金額に掛けられるのは整数だけです: #{times.inspect}" unless times.is_a?(Integer)

    Money.new(yen * times)
  end

  def <=>(other)
    yen <=> other.yen if other.is_a?(Money)
  end

  def ==(other)
    other.is_a?(Money) && yen == other.yen
  end
  alias eql? ==

  def hash
    [ Money, yen ].hash
  end

  def zero?
    yen.zero?
  end

  def to_s
    "#{yen.to_s.reverse.scan(/\d{1,3}/).join(',').reverse}円"
  end

  def inspect
    "#<Money #{self}>"
  end
end
