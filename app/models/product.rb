# == Schema Information
#
# Table name: products
#
#  id              :integer          not null, primary key
#  inventory_count :integer
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Product < ApplicationRecord
  include Notifications

  has_one_attached :featured_image
  has_rich_text :description

  validates :name, presence: true
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }
end
