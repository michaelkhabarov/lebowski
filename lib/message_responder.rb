require "./models/user"
require "./lib/message_sender"

class MessageResponder
  attr_reader :message
  attr_reader :bot
  attr_reader :user

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = User.find_or_create_by(tg_id: @message.from.id)
  end

  def respond
    on(/^\/start/) do
      start_bot
    end

    on(/^\/stop/) do
      stop_bot
    end
  end

  private

  def on regex, &block
    regex =~ message.text

    if $~
      case block.arity
      when 0
        yield
      when 1
        yield $1
      when 2
        yield $1, $2
      end
    end
  end

  def start_bot
    user.enable!
    answer_with_message <<~EOF
      Как только в банкомат привезут $$$, я тебе скажу
      Где что есть сейчас можешь посмотреть на карте: https://www.tinkoff.ru/maps/atm/
    EOF
  end

  def stop_bot
    user.disable!
    answer_with_message "Пока-пока"
  end

  def answer_with_message(text)
    MessageSender.new(bot: bot, chat: message.chat, text: text).send
  end
end
