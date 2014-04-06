require 'helper'

class TestBioBiostarsAnalytics < Test::Unit::TestCase
  should 'convert a relative time to an absolute time' do
    assert_contains([
      "#{BioBiostarsAnalytics::extract_date('3.5 years ago')}",
      "#{BioBiostarsAnalytics::extract_date('5 days ago')}",
      "#{BioBiostarsAnalytics::extract_date('8 months ago')}"
      ], /^\d{4}-\d+-\d+ \d+:\d+:\d+.*/)
  end
end

