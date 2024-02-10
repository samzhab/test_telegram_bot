# lib/tasks/fetch_api_data.rake
require 'httparty'
require 'dotenv'

namespace :data do
  desc "Fetch data from API and save locally"
  task "fetch_api_data" do
    Dotenv.load

    coredata_url = ENV['COREDATA_API_URL']
    matches_url = ENV['MATCHES_API_URL']

    # Updated file paths using File.join
    coredata_file_path = File.join('lib', 'coredata.json')
    matches_file_path = File.join('lib', 'matches.json') # Corrected file path

    begin
      coredata_response = HTTParty.get(coredata_url)
      File.write(coredata_file_path, coredata_response.body)

      matches_response = HTTParty.get(matches_url)
      File.write(matches_file_path, matches_response.body)

      puts "Data fetched and saved successfully."
    rescue StandardError => e
      puts "Error fetching API data: #{e.message}"
    end
  end
end
 
