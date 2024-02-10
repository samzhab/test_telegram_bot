# spec/tasks/fetch_api_data_spec.rb
require 'spec_helper'
require 'rake'
require 'vcr'

# Assuming your rake tasks are defined in a directory at the root of your project, e.g., 'lib/tasks/'
TASKS_PATH = File.expand_path('../../../lib/tasks', __FILE__)

describe 'fetch_api_data task' do
  before(:all) do
    # Load the Rake environment
    Rake.application.rake_require 'fetch_api_data', [TASKS_PATH]
    Rake::Task.define_task(:environment)

    # Load the task to be available for RSpec
    Rake::Task['data:fetch_api_data'].reenable
  end

  it 'fetches API data without errors' do
    VCR.use_cassette('fetch_api_data') do
      expect { Rake::Task['data:fetch_api_data'].invoke }.not_to raise_error
    end
  end
end
