# lib/tasks/extract_static_data.rake
require 'json'
require 'yaml'
require 'dotenv'

namespace :data do
  desc "Extract static data from coredata.json to YAML"
  task "extract_static_data" do
    Dotenv.load

    # Updated coredata_file_path as per the specified style
    coredata_file_path = File.join('lib', 'coredata.json')
    output_yaml_path = File.join('config', 'static_data.yml')

    begin
      coredata = JSON.parse(File.read(coredata_file_path))
      static_data = {
        'sport_types' => coredata['sport_types'],
        'league_groups' => coredata['league_groups'],
        'leagues' => coredata['leagues'],
        'bet_groups' => coredata['bet_groups'],
        'bet_types' => coredata['bet_types']
      }

      File.write(output_yaml_path, static_data.to_yaml)
      puts "Static data successfully extracted to #{output_yaml_path}"
    rescue JSON::ParserError => e
      puts "JSON Parsing Error: #{e.message}"
    rescue Errno::ENOENT => e
      puts "File not found: #{e.message}"
    rescue StandardError => e
      puts "An unexpected error occurred: #{e.message}"
    end
  end
end
