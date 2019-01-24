require 'bundler'
Bundler.setup
require 'savon'
require 'yaml'
require 'csv'
require 'nokogiri'

class UpdateStatus

  def initialize()
    # Initialize data
    @config = YAML.load(File.open('config/config.yml').read)
    @success_count = @remain_unchanged = @fail_count = 0
  end

  def execute()
    @responses = []
    @errors = []

    # Initialize GetStatus SOAP client using the WSDL
    client = Savon.client(:wsdl => @config["get_status_wsdl"], log: false, ssl_verify_mode: :none)

    # Read csv file to update the status to LeasePak API
    CSV.foreach(@config["path_to_file"], { headers: true }) do |row|
      app_number = row["appNumber"]
      app_new_status = row["newStatus"]

      # Get status of corresponding appNumber from LeasePak API
      response = client.call(:get_status_transfer_data, message: { appNumber: app_number })

      # Format response data
      response = Nokogiri.XML(response.body[:get_status_transfer_data_response][:return])

      if response.search('ERROR').text.blank?
        # Store the response from LeasePak API in log file
        @responses << "Response for Application #{row[0]} from LeasePak GetStatusTransferData API: #{response}"

        get_status_response = format_response(response)

        # Update status of appNumber if statuses are different
        if get_status_response["curStatus"] != app_new_status
          update_status(row, get_status_response) 
        else
          @remain_unchanged = @remain_unchanged + 1
        end
      else
        @fail_count = @fail_count + 1
        @errors << "Error for Application #{row[0]} from LeasePak GetStatusTransferData API: #{response}"
      end
    end

    print_summary

  rescue Savon::Error => exception
    # Store message in log if client failes to connect with LeasePak API
    File.open('log/errors.log','a') do |line|
      line.puts "\r" + "An error occurred while calling the LeasePak: #{exception.message}"
    end
  end

  private

  def print_summary
    File.open('log/responses.log', 'a') do |line|
      line.puts "\r" + "Summary"
      line.puts "#{@success_count} Updated successfully"
      line.puts "#{@remain_unchanged} Remain Unchanged"
      line.puts "#{@fail_count} Errors"

      line.puts "\r" + "\n" + "Responses"
      @responses.each do |response|
        line.puts "#{response}"
      end

      line.puts "\r" + "\n" + "Errors"
      @errors.each do |error|
        line.puts "#{error}"
      end
    end
  end

  def update_status(row, get_status_response)
    client = Savon.client(:wsdl => @config["update_status_wsdl"], log: false, ssl_verify_mode: :none)

    # Update status of corresponding appNumber to LeasePak API
    response = client.call(:application_status_transfer, message: { "x_mlDoc" => generate_xml(row, get_status_response) })

    response = Nokogiri.XML(response.body[:application_status_transfer_response][:return])

    if response.search('ERROR').text.blank?
      @success_count = @success_count + 1
      @responses << "Response for Application #{row[0]} from LeasePak ApplicationStatusTransfer API: #{response}"
    else
      @fail_count = @fail_count + 1
      @errors << "Error for Application #{row[0]} from LeasePak ApplicationStatusTransfer API: #{response}"
    end
  end

  # generate XML data from the data got from getStatusTransferData API
  def generate_xml(row, response)
    xml = Builder::XmlMarkup.new

    xml.APP_STATUS_XFER do |d|
      d.appNumber(response["appNumber"])
      d.dapcksum(response["dapcksum"])
      d.ddmcksum(response["ddmcksum"])
      d.newStatus(row["newStatus"])
    end
  end

  def format_response(response)
    Hash[response.xpath('//APP_STATUS_XFER_FETCH').children.collect { |el| [el.name, el.text] } ]
  end
end

if __FILE__ == $0
  # Initialize the EchoService client and call operations
  status = UpdateStatus.new
  status.execute()
end
