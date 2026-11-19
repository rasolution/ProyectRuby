class User < ActiveRecord::Base
  has_secure_password reset_token: false
  before_validation { self.username = username.to_s.strip }
  before_save { self[:password] = nil if password_digest_changed? }
  validates :username, presence: true, length: { maximum: 100 }, uniqueness: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validate :username_is_stable, on: :update

  # Upgrade an existing MD5 record only after proving the original password.
  # Oversized legacy passwords remain usable without silently truncating them.
  def authenticate_compatible(candidate)
    return false if candidate.include?("\0")
    if password_digest.present?
      return false if candidate.bytesize > 72
      return authenticate(candidate)
    end
    legacy = self[:password].to_s
    return false unless legacy.match?(/\A[0-9a-f]{32}\z/i)
    return false unless ActiveSupport::SecurityUtils.secure_compare(legacy.downcase, Digest::MD5.hexdigest(candidate))
    if candidate.bytesize <= 72 && !candidate.include?("\0")
      self.password = candidate
      save!(validate: false)
    end
    self
  rescue BCrypt::Errors::InvalidHash
    false
  end

  private

  def username_is_stable
    errors.add(:username, 'no se puede cambiar una vez creada la cuenta') if username_changed?
  end
end
