 
# spec/tasks/populate_data_spec.rb
require 'spec_helper'
require 'rake'

describe 'populate_data task' do
  it 'populates data without errors' do
    expect { Rake::Task['data:populate_data'].invoke }.not_to raise_error
  # Consider adding more specific tests to verify the data was populated as expected.
  end
end
