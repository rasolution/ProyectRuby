class Product < ActiveRecord::Base
  has_many :offered_transactions, class_name: 'Transaction', foreign_key: :offert_product_id, dependent: :restrict_with_error
  has_many :requested_transactions, class_name: 'Transaction', foreign_key: :require_product_id, dependent: :restrict_with_error
  before_validation { self.name = name.to_s.strip }
  validates :name, presence: true, length: { maximum: 255 }
  validates :price, :state, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 2_147_483_647 }
end
