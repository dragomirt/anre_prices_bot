require 'rubygems'
require 'telegram/bot'
require_relative './price_retriever'
require 'rufus-scheduler'
require 'dotenv'

Dotenv.load

# @type [String]
TOKEN = ENV["TOKEN"]

module Labels
  PETROL = "Petrol Price"
  DIESEL = "Diesel Price"
  REMIND_DAILY = "Remind me daily"
  REMOVE_REMINDER = "Dont remind me anymore"
end

class Bot
  attr_writer :token, :petrol_prices, :diesel_prices
  attr_reader :storage, :scheduled_chats, :scheduler

  # @attr [Array<Hash{Symbol => String, nil | Float, nil}>] petrol_prices
  @petrol_prices = []

  # @attr [Array<Hash{Symbol => String, nil | Float, nil}>] diesel_prices
  @diesel_prices = []

  # @attr [Rufus::Scheduler, nil] scheduler
  @scheduler = nil

  # @attr [Array<Integer>] scheduled_chats
  @scheduled_chats = []

  # @attr [Storage, nil] storage
  @storage = nil

  # @param [String, nil] token
  def initialize(token)
    @token = token
    @scheduled_chats = []

    @storage = Storage.new File.expand_path('scheduled_chats.txt', __dir__)
    @scheduled_chats = @storage.get_chats
  end

  def init_pull
    @petrol_prices = PriceRetriever.get_petrol_prices
    @diesel_prices = PriceRetriever.get_diesel_prices
  end

  # @param [Telegram::Bot::Client] bot
  # @param [Telegram::Bot::Types::ReplyKeyboardMarkup] markup
  def init_scheduler(bot, markup)
    @scheduler = Rufus::Scheduler.new

    @scheduler.cron '00 14 * * *' do
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

    # @type [Float]
    diff = latest_petrol_row[:price].to_f - last_before_last[:price].to_f
    diff = diff.truncate 3

    bot.api.send_message(chat_id: chat_id, text: "Petrol: #{latest_petrol_row[:date]} #{latest_petrol_row[:price]} (#{diff.to_s})", reply_markup: markup)
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

    # @type [Float]
    diff = latest_diesel_row[:price].to_f - last_before_last[:price].to_f
    diff = diff.truncate 3

    bot.api.send_message(chat_id: chat_id, text: "Diesel: #{latest_diesel_row[:date]} #{latest_diesel_row[:price]} (#{diff.to_s})", reply_markup: markup)
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

      kb = [
        Telegram::Bot::Types::KeyboardButton.new(text: Labels::PETROL),
        Telegram::Bot::Types::KeyboardButton.new(text: Labels::DIESEL),
        Telegram::Bot::Types::KeyboardButton.new(text: Labels::REMIND_DAILY),
        Telegram::Bot::Types::KeyboardButton.new(text: Labels::REMOVE_REMINDER),
      ]

      markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)

      init_scheduler bot, markup

      # @type [Telegram::Bot::Types::Message] message
      bot.listen do |message|

        case message.text
        when "/start"
          bot.api.send_message(chat_id: message.chat.id, text: "Tell me what do you want to know!", reply_markup: markup)
        when Labels::PETROL
          self.send_petrol_price bot, message.chat.id, markup
        when Labels::DIESEL
          self.send_diesel_price bot, message.chat.id, markup
        when Labels::REMIND_DAILY
          @scheduled_chats.push message.chat.id
          @scheduled_chats.uniq!

          @storage.save_chats @scheduled_chats
        when Labels::REMOVE_REMINDER
          @scheduled_chats.delete message.chat.id
          @scheduled_chats.uniq!
          @storage.save_chats @scheduled_chats
        else
          # type code here
        end

      end
    end
  end
end


class Storage
  attr_accessor :file_name

  # @attr [String] file_name
  @file_name = ""

  # @param [String] file_name
  def initialize(file_name)
    @file_name = file_name
  end

  # @param [Array<Integer>] chats
  # @return [Integer]
  def save_chats(chats)
    File.open(@file_name, "w") do |f|
      chats.each { |element| f.puts(element) }
    end

    chats.count
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
end


bot = Bot.new TOKEN

loop do
  puts 'Spawn a bot!'
  bot.run

  puts 'Bot dead ... Sleep for 5 seconds.'
  sleep(5)
end
