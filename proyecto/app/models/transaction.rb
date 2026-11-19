class Transaction < ActiveRecord::Base
  belongs_to :offered_product, class_name: 'Product', foreign_key: :offert_product_id, optional: true
  belongs_to :required_product, class_name: 'Product', foreign_key: :require_product_id, optional: true
  before_validation do
    value = require_product_id.to_s.strip
    self.require_product_id = value.to_i.to_s if value.match?(/\A\d+\z/)
  end
  validates :offert_product_id, :require_product_id, numericality: { only_integer: true, greater_than: 0 }
  validates :offered_product, :required_product, presence: true
  validates :require_product_id, uniqueness: { scope: :offert_product_id }
  validate do
    if offert_product_id.present? && require_product_id.present? && offert_product_id.to_s == require_product_id
      errors.add(:require_product_id, 'debe ser distinto del producto ofrecido')
    end
  end
end
