class TestJob < ApplicationJob
  queue_as :default

  def perform
    p Product.all
  end
end
