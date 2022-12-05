require 'faraday'
require 'faraday/net_http'
require 'nokogiri'
require 'date'

class PriceRetriever

  attr_reader :base_url, :petrol_price_uri, :diesel_price_uri
  @@base_url = "https://anre.md/"
  @@petrol_price_uri = "benzina-95-3-2"
  @@diesel_price_uri = "motorina-3-3"

  # @return [Array<Hash{Symbol => String, nil | Float, nil}>]
  def self.get_petrol_prices
    link = "#{@@base_url}#{@@petrol_price_uri}"
    response = Faraday.get(link)
    self.get_doc(response)
  end

  # @return [Array<Hash{Symbol => String, nil | Float, nil}>]
  def self.get_diesel_prices
    link = "#{@@base_url}#{@@diesel_price_uri}"
    response = Faraday.get(link)
    self.get_doc(response)
  end

  # @param [Faraday::Response] response
  # @return [Array<Hash{Symbol => String, nil | Float, nil}>]
  def self.get_doc(response)
    doc = Nokogiri::HTML(response.body)

    table = []

    doc.css('.calculator__table>table>tbody>tr').each do |row|
      data = self.pull_fields row
      table.push data
    end

    return table
  end

  # @param [Nokogiri::XML::Element] row
  # @return [Hash{Symbol => String, nil | Float, nil}]
  def self.pull_fields(row)

    # @type [String]
    date = row.css('td:nth-child(1)').first.content

    # @type [Float]
    price = row.css('.pl_price').first.content.sub(",", ".").to_f

    return {"date": date, "price": price}
  end

end