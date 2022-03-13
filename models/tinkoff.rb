require "faraday"
require "json"

class Tinkoff
  def available_atms
    atms.filter { _1.atmInfo.available }.map do |atm|
      OpenStruct.new atm.to_h.symbolize_keys
        .slice(:address, :floor)
        .merge({
          uid: atm.id,
          location: atm.installPlace,
          amount_usd: atm.limits.find { _1.currency == "USD" }.amount.to_i,
          work_periods: atm.workPeriods.each_with_object({}) do |period, periods|
            start_time = "#{period.openTime[0..1]}:#{period.openTime[2..-1]}"
            end_time = "#{period.closeTime[0..1]}:#{period.closeTime[2..-1]}"
            periods[period.openDay.to_i + 1] = [start_time, end_time]
          end
        })
    end
  end

  private

  # 1. Go to https://www.tinkoff.ru/maps/atm/?currency=USD&amount=100&latitude=59.97859546238357&longitude=30.23062308106806&zoom=11&partner=tcs
  # 2. Move map as you need
  # 3. Open devtools, reload page and go to Network => clusters => Copy as cURL
  def fetch_atms
    # rubocop:disable all
    headers = {
      "authority": "api.tinkoff.ru",
      "pragma": "no-cache",
      "cache-control": "no-cache",
      "accept": "*/*",
      "access-control-request-method": "POST",
      "access-control-request-headers": "content-type",
      "origin": "https://www.tinkoff.ru",
      "user-agent": user_agent,
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-site",
      "sec-fetch-dest": "empty",
      "referer": "https://www.tinkoff.ru/",
      "accept-language": "en-US,en;q=0.9,ru;q=0.8",
      "content-type": "application/json"
    }
    # rubocop:enable all

    lat_bl = coordinate(:lat_bl)
    lng_bl = coordinate(:lng_bl)
    lat_tr = coordinate(:lat_tr)
    lng_tr = coordinate(:lng_tr)
    zoom = ENV["LEBOWSKI_TCS_MAP_ZOOM"] || raise("No LEBOWSKI_TCS_MAP_ZOOM provided")
    body = "{\"bounds\":{\"bottomLeft\":{\"lat\":#{lat_bl},\"lng\":#{lng_bl}},\"topRight\":{\"lat\":#{lat_tr},\"lng\":#{lng_tr}}},\"filters\":{\"banks\":[\"tcs\"],\"showUnavailable\":true,\"currencies\":[\"USD\"]},\"zoom\":#{zoom}}"

    # response format: { payload: { clusters: [{points: [...]}] }}
    response = Faraday.post("https://api.tinkoff.ru/geo/withdraw/clusters", body, headers)
    raise StandardError.new("Error fetching atms: #{response.inspect}") unless response.success?
    JSON.parse(response.body, object_class: OpenStruct)
  end

  def coordinate(dir)
    dir = dir.to_s
    raise ArgumentError.new("Wrong dir") unless %w[lat_bl lng_bl lat_tr lng_tr].include?(dir)
    env_name = "LEBOWSKI_TCS_MAP_#{dir.upcase}"
    coordinate = ENV[env_name]&.to_f || raise("No #{env_name} provided")
    randomize_coordinate(coordinate)
  end

  def randomize_coordinate(coordinate)
    diff = coordinate / 1000 # Vary coordinate by 0.1%
    coordinate + rand(-diff..diff)
  end

  def atms
    # point format: {"id":"003225","brand":{"id":"tcs","name":"Тинькофф Банк","logoFile":"tcs.png","roundedLogo":false},"pointType":"ATM","location":{"lat":59.925464,"lng":30.319585},"address":"ТЦ \\"Сенная\\", 1 этаж, рядом с \\"Эльдорадо\\", Ефимова ул., 3С","phone":["88007557424"],"limits":[{"currency":"USD","max":20000,"denominations":[100],"amount":5000},{"currency":"RUB","max":1000000,"denominations":[100,1000,5000],"amount":300000}],"workPeriods":[{"openDay":0,"openTime":"1000","closeDay":0,"closeTime":"2200"},{"openDay":1,"openTime":"1000","closeDay":1,"closeTime":"2200"},{"openDay":2,"openTime":"1000","closeDay":2,"closeTime":"2200"},{"openDay":3,"openTime":"1000","closeDay":3,"closeTime":"2200"},{"openDay":4,"openTime":"1000","closeDay":4,"closeTime":"2200"},{"openDay":5,"openTime":"1000","closeDay":5,"closeTime":"2200"},{"openDay":6,"openTime":"1000","closeDay":6,"closeTime":"2200"}],"installPlace":"ТЦ \\"Сенная\\", 1 этаж, рядом с \\"Эльдорадо\\"","atmInfo":{"available":true,"isTerminal":false,"statuses":{"criticalFailure":false,"qrOperational":true,"nfcOperational":true,"cardReaderOperational":true,"cashInAvailable":true},"limits":[{"currency":"USD","amount":5000,"withdrawMaxAmount":20000,"depositionMaxAmount":15000,"depositionMinAmount":50,"withdrawDenominations":[100],"depositionDenominations":[50,100],"overTrustedLimit":false},{"currency":"EUR","amount":0,"withdrawMaxAmount":20000,"depositionMaxAmount":15000,"depositionMinAmount":50,"withdrawDenominations":[],"depositionDenominations":[50,100],"overTrustedLimit":false},{"currency":"RUB","amount":300000,"withdrawMaxAmount":1000000,"depositionMaxAmount":750000,"depositionMinAmount":100,"withdrawDenominations":[100,1000,5000],"depositionDenominations":[100,200,500,1000,2000,5000],"overTrustedLimit":false}]}}
    # { id, address, installPlace, limits: [{ currency, max, amount }], workPeriods: [] }
    fetch_atms.payload.clusters.map(&:points).flatten
  end

  def user_agent
    [
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36",
      "Mozilla/5.0 (X11; Ubuntu; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2919.83 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.2 Safari/605.1.15",
      "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.3",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/43.4",
      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36 Edge/18.19582",
      "Mozilla/5.0 (Windows NT 10.0; WOW64; rv:77.0) Gecko/20100101 Firefox/77.0",
    ].sample
  end
end
