# spec/tasks/extract_static_data_spec.rb
require 'spec_helper'
require 'rake'
describe 'extract_static_data task' do
  it 'extracts data without errors' do
    expect { Rake::Task['data:extract_static_data'].invoke }.not_to raise_error
  end
end
 
