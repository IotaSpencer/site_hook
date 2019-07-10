require 'rspec'
require 'rspec/expectations'

RSpec.configure do |t|
  t.color = true
  t.libs = ['lib']
  t.expect_with(:rspec) do |c|
    c.syntax = :expect
  end
  t.mock_with(:rspec) do |c|
    c.syntax = :expect
  end
end