# == Schema Information
#
# Table name: subscribers
#
#  id         :bigint           not null, primary key
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :bigint           not null
#
# Indexes
#
#  index_subscribers_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#
class Subscriber < ApplicationRecord
  belongs_to :product
  generates_token_for :unsubscribe
end
