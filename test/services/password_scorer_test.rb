require 'test_helper'

class PasswordScorerTest < ActiveSupport::TestCase
  testing '#perform' do
    test 'with weak password' do
      scorer = PasswordScorer.new('password')
      assert_equal 0, scorer.perform
    end

    test 'with strong password' do
      scorer = PasswordScorer.new(SecureRandom.hex(16))
      assert_equal 4, scorer.perform
    end

    test 'with maliciously long password' do
      scorer = PasswordScorer.new(SecureRandom.hex(150))
      ms = Benchmark.ms{ scorer.perform }
      assert ms < 500, ms
    end
  end
end
