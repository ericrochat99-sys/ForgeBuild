# frozen_string_literal: true

Dir[File.expand_path('**/*_test.rb', __dir__)]
  .reject { |file| file == __FILE__ }
  .sort
  .each { |file| require file }
