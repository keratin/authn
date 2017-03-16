PasswordExpirer = Struct.new(:id)
class PasswordExpirer
  def perform
    if (account = Account.find_by_id(id))
      account.update(require_new_password: true)
      account.sessions.each{|hex| RefreshToken.revoke(hex) }
      true
    else
      false
    end
  end
end
