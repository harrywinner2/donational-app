MoneyRails.configure do |config|
  config.locale_backend = :currency
  config.default_currency = :usd
  config.rounding_mode = BigDecimal::ROUND_HALF_UP
end
