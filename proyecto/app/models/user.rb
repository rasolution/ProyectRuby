class User < ActiveRecord::Base
  before_create :encryptpassword

  def encryptpassword
    self.password = Digest::MD5.hexdigest(self.password)
  end
end
