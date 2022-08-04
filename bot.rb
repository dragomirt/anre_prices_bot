require 'rubygems'
require 'telegram/bot'
require_relative './price_retriever'
require 'rufus-scheduler'
require 'dotenv'

Dotenv.load

# @type [String]
TOKEN = ENV["TOKEN"]

module Labels
  PETROL = "⛽️ Petrol Price"
  PETROL_TABLE = "📊 Petrol Table"
  DIESEL = "⛽ Diesel Price"
  DIESEL_TABLE = "📊 Diesel Table"
  REMIND_DAILY = "⏰ Remind me daily"
  REMOVE_REMINDER = "❌ Dont remind me anymore"
end

class Bot
  attr_writer :token, :petrol_prices, :diesel_prices
  attr_reader :storage, :scheduled_chats, :scheduler, :sessions

  # @attr [Array<Hash{Symbol => String, nil | Float, nil}>] petrol_prices
  @petrol_prices = []

  # @attr [Array<Hash{Symbol => String, nil | Float, nil}>] diesel_prices
  @diesel_prices = []

  # @attr [Rufus::Scheduler, nil] scheduler
  @scheduler = nil

  # @attr [Array<Integer>] scheduled_chats
  @scheduled_chats = []

  # @attr [Array<Integer>] sessions
  @sessions = []

  # @attr [Storage, nil] storage
  @storage = nil

  # @param [String, nil] token
  def initialize(token)
    @token = token
    @scheduled_chats = []

    @storage = Storage.new File.expand_path('scheduled_chats.txt', __dir__), File.expand_path('sessions.txt', __dir__)
    @scheduled_chats = @storage.get_chats
    @sessions = @storage.get_sessions
  end

  def init_pull
    @petrol_prices = PriceRetriever.get_petrol_prices
    @diesel_prices = PriceRetriever.get_diesel_prices
  end

  # @param [Telegram::Bot::Client] bot
  # @param [Telegram::Bot::Types::ReplyKeyboardMarkup] markup
  def init_scheduler(bot, markup)
    @scheduler = Rufus::Scheduler.new

    @scheduler.cron '00 10 * * *' do
      init_pull # update the values

      @scheduled_chats.each { |chat_id|
        self.send_petrol_price bot, chat_id, markup
        self.send_diesel_price bot, chat_id, markup
      }
    end
  end

  # @param [Telegram::Bot::Client] bot
  # @param [String] chat_id
  # @param [Telegram::Bot::Types::ReplyKeyboardMarkup] markup
  # @return [void]
  def send_petrol_price(bot, chat_id, markup)
    # @type [Hash{Symbol => String, nil | Float, nil}]
    latest_petrol_row = @petrol_prices.first

    # @type [Hash{Symbol => String, nil | Float, nil}]
    last_before_last = @petrol_prices[1]

    if latest_petrol_row.nil? || last_before_last.nil?
      return # ignore method
    end

    # @type [Float]
    diff = latest_petrol_row[:price].to_f - last_before_last[:price].to_f
    diff = diff.truncate 3

    bot.api.send_message(chat_id: chat_id, text: "#{self.get_price_emoji(diff)} Petrol: #{latest_petrol_row[:date]} #{latest_petrol_row[:price]} (#{diff.to_s})", reply_markup: markup)
  end

  # @param [Telegram::Bot::Client] bot
  # @param [String] chat_id
  # @param [Telegram::Bot::Types::ReplyKeyboardMarkup] markup
  # @return [void]
  def send_petrol_price_table(bot, chat_id, markup)
    # @type [Array[Hash{Symbol => String, nil | Float, nil}]]
    petrol_rows = @petrol_prices

    if petrol_rows.empty?
      return # ignore method
    end

    table = petrol_rows.each_with_index.map { |row, index| "#{row[:date]}\t\t #{row[:price]} #{get_price_emoji(row[:price].to_f - petrol_rows[index + 1][:price].to_f) unless petrol_rows[index + 1].nil?}" } * "\n" # concat table
    bot.api.send_message(chat_id: chat_id, text: "*Petrol prices table*\n\n```\n#{table}```", reply_markup: markup, parse_mode: "MarkdownV2")
  end

  # @param [Telegram::Bot::Client] bot
  # @param [String] chat_id
  # @param [Telegram::Bot::Types::ReplyKeyboardMarkup] markup
  # @return [void]
  def send_diesel_price(bot, chat_id, markup)
    # @type [Hash{Symbol => String, nil | Float, nil}]
    latest_diesel_row = @diesel_prices.first
    # @type [Hash{Symbol => String, nil | Float, nil}]
    last_before_last = @diesel_prices[1]

    if latest_diesel_row.nil? || last_before_last.nil?
      return # ignore method
    end

    # @type [Float]
    diff = latest_diesel_row[:price].to_f - last_before_last[:price].to_f
    diff = diff.truncate 3

    bot.api.send_message(chat_id: chat_id, text: "#{self.get_price_emoji(diff)} Diesel: #{latest_diesel_row[:date]} #{latest_diesel_row[:price]} (#{diff.to_s})", reply_markup: markup)
  end

  # @param [Telegram::Bot::Client] bot
  # @param [String] chat_id
  # @param [Telegram::Bot::Types::ReplyKeyboardMarkup] markup
  # @return [void]
  def send_diesel_price_table(bot, chat_id, markup)
    # @type [Array[Hash{Symbol => String, nil | Float, nil}]]
    diesel_rows = @diesel_prices

    if diesel_rows.empty?
      return # ignore method
    end

    table = diesel_rows.each_with_index.map { |row, index| "#{row[:date]}\t\t #{row[:price]} #{get_price_emoji(row[:price].to_f - diesel_rows[index + 1][:price].to_f) unless diesel_rows[index + 1].nil?}" } * "\n" # concat table
    bot.api.send_message(chat_id: chat_id, text: "*Diesel prices table*\n\n```\n#{table}```", reply_markup: markup, parse_mode: "MarkdownV2")
  end

  # @return [void]
  def run

    if @token.nil?
      puts "No token!"
      return
    end

    puts "Pulling latest data ..."
    self.init_pull

    puts "Running the BOT! ..."

    # @type [Telegram::Bot::Client] bot
    Telegram::Bot::Client.run(@token) do |bot|

      kb_default = [
        [
          Telegram::Bot::Types::KeyboardButton.new(text: Labels::PETROL),
          Telegram::Bot::Types::KeyboardButton.new(text: Labels::PETROL_TABLE),
        ],
        [
          Telegram::Bot::Types::KeyboardButton.new(text: Labels::DIESEL),
          Telegram::Bot::Types::KeyboardButton.new(text: Labels::DIESEL_TABLE)
        ]
      ]

      kb_unsubscribed = kb_default + [Telegram::Bot::Types::KeyboardButton.new(text: Labels::REMIND_DAILY)]
      kb_subscribed = kb_default + [Telegram::Bot::Types::KeyboardButton.new(text: Labels::REMOVE_REMINDER)]

      markup_unsubscribed = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb_unsubscribed, resize_keyboard: true)
      markup_subscribed = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb_subscribed, resize_keyboard: true)

      init_scheduler bot, markup_subscribed

      # @type [Telegram::Bot::Types::Message] message
      bot.listen do |message|

        reply_markup = self.is_subscribed?(chat: message.chat) ? markup_subscribed : markup_unsubscribed

        if message.instance_of? Telegram::Bot::Types::Message
          case message.text
          when "/start"
            bot.api.send_message(chat_id: message.chat.id, text: "Tell me what do you want to know!", reply_markup: reply_markup)

            begin
              @sessions.push message.chat.id
              @sessions.uniq!

              @storage.save_sessions @sessions
            rescue StandardError => e
              puts e.message
            end

          when Labels::PETROL
            self.send_petrol_price bot, message.chat.id, reply_markup
          when Labels::PETROL_TABLE
            self.send_petrol_price_table bot, message.chat.id, reply_markup
          when Labels::DIESEL
            self.send_diesel_price bot, message.chat.id, reply_markup
          when Labels::DIESEL_TABLE
            self.send_diesel_price_table bot, message.chat.id, reply_markup
          when Labels::REMIND_DAILY
            @scheduled_chats.push message.chat.id
            @scheduled_chats.uniq!

            @storage.save_chats @scheduled_chats

            bot.api.send_message(chat_id: message.chat.id, text: "Now you will be reminded daily at 13:00 GMT+3", reply_markup: markup_subscribed)
          when Labels::REMOVE_REMINDER
            @scheduled_chats.delete message.chat.id
            @scheduled_chats.uniq!
            @storage.save_chats @scheduled_chats

            bot.api.send_message(chat_id: message.chat.id, text: "You won't be reminded anymore :(", reply_markup: markup_unsubscribed)
          else
            # type code here
          end
        end

        if message.instance_of? Telegram::Bot::Types::ChatMemberUpdated
          begin
            bot.api.send_message(chat_id: message.chat.id, text: "Glad to be a part of the group!", reply_markup: markup_unsubscribed)
          rescue Telegram::Bot::Exceptions::ResponseError => e
            puts e.message
          end
        end

      end
    end
  end

  private

  # @type [Telegram::Bot::Types::Chat] chat:
  # @return [Boolean]
  def is_subscribed? (chat:)
    @scheduled_chats.include? chat.id
  end

  # Append a small image to ease the readability of the report
  # @type [Float] price_diff
  # @return [String]
  def get_price_emoji (price_diff)
    price_diff < 0 ? "📉" : "📈"
  end
end


class Storage
  attr_accessor :file_name

  # @attr [String] file_name
  @file_name = ""
  @sessions_file_name = ""

  # @param [String] file_name
  def initialize(file_name, sessions_file_name)
    @file_name = file_name
    @sessions_file_name = sessions_file_name
  end

  # @param [Array<Integer>] chats
  # @return [Integer]
  def save_chats(chats)
    File.open(@file_name, "w") do |f|
      chats.each { |element| f.puts(element) }
    end

    chats.count
  end

  # @param [Array<Integer>] sessions
  # @return [Integer]
  def save_sessions(sessions)
    File.open(@sessions_file_name, "w") do |f|
      sessions.each { |element| f.puts(element) }
    end

    sessions.count
  end

  # @return [Array<Integer>]
  def get_chats

    # @type [Array<Integer>]
    chats = []

    if nil == @file_name
      return []
    end

    if false == File.exists?(@file_name)
      return []
    end

    File.foreach(@file_name) { |line| chats.push line.to_i }

    chats.uniq
  end

  # @return [Array<Integer>]
  def get_sessions

    # @type [Array<Integer>]
    sessions = []

    if nil == @sessions_file_name
      return []
    end

    if false == File.exists?(@sessions_file_name)
      return []
    end

    File.foreach(@sessions_file_name) { |line| sessions.push line.to_i }

    sessions.uniq
  end
end


bot = Bot.new TOKEN

bot.run
