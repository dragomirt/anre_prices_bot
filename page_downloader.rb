require_relative 'price_retriever'
require 'yaml'
require 'rufus-scheduler'

class PageDownloader

  attr_reader :petrol_table, :diesel_table

  # @attr [String] petrol_file_name
  PETROL_FILE_NAME = "petrol_table.yml"

  # @attr [String] diesel_file_name
  DIESEL_FILE_NAME = "diesel_table.yml"

  def run
    @petrol_table = PriceRetriever.get_petrol_prices
    @diesel_table = PriceRetriever.get_diesel_prices

    self.save_tables
  end

  def schedule
    scheduler = Rufus::Scheduler.new

    # check thrice for good measure
    scheduler.cron '30 8,9,10 * * *' do
      self.run # update the values
    end
  end

  # @return [Bool]
  def save_tables
    if @petrol_table.nil? || @diesel_table.nil?
      return false
    end

    # save petrol
    File.write(PETROL_FILE_NAME, @petrol_table.to_yaml)

    # save diesel
    File.write(DIESEL_FILE_NAME, @diesel_table.to_yaml)
    true
  end

  # @return [Array<Integer>]
  def self.get_petrol_table

    if nil == PETROL_FILE_NAME
      return []
    end

    if false == File.exists?(PETROL_FILE_NAME)
      return []
    end

    YAML.load_file(PETROL_FILE_NAME)
  end

  # @return [Array<Integer>]
  def self.get_diesel_table
    if nil == DIESEL_FILE_NAME
      return []
    end

    if false == File.exists?(DIESEL_FILE_NAME)
      return []
    end

    YAML.load_file(DIESEL_FILE_NAME)
  end
end

def run_console
  dl = PageDownloader.new
  dl.run
  dl.schedule
end

if ARGV.any? && ARGV.first == '--run'
  running = true
  Signal.trap('INT') { running = false }
  run_console while running
  exit
end