require "erb"
require "./models/atm"
require "./models/user"
require "./lib/app_configurator"

module AtmNotifier
  class << self
    def notify_about_refills(bot)
      Atm.refilled_atms.each do |atm|
        User.enabled.find_each do |user|
          bot.api.send_message(
            chat_id: user.tg_id,
            text: message(atm),
            parse_mode: "HTML",
            disable_web_page_preview: true
          )
        end
      end
    end

    private

    def message(atm)
      map_url = "https://yandex.ru/maps/2/saint-petersburg/search/#{ERB::Util.url_encode(atm.address)}"

      <<~EOF
        Похоже завезли $#{atm.amount_usd}:
        Адрес: #{atm.address}
        Как найти: #{atm.location}
        Режим работы сегодня: #{atm.work_periods&.fetch(Date.today.cwday, nil)&.join(" – ")}
        <a href="#{map_url}">Найти на Яндекс Картах</a>
      EOF
    end
  end
end
