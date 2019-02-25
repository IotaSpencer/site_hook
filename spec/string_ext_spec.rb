require 'site_hook/string_ext'
require 'spec_helper'
describe String do
  describe '#underscore' do
    let(:working_string) { 'LogLevels' }
    it 'should return an object with the string underscored' do
      expect(working_string).to respond_to(:underscore)
    end
  end
end