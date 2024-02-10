# spec/tasks/create_schema_spec.rb
require 'spec_helper'
require 'rake'
RSpec.describe 'create_schema rake task' do
  it 'creates the schema without errors' do
    task = Rake::Task['data:create_schema']
    expect { task.invoke }.not_to raise_error
  end
end
