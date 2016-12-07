AccountLocker = Struct.new(:id)
class AccountLocker
  def perform
    if account = Account.active.find_by_id(id)
      account.update(locked: true) unless account.locked?
      true
    else
      false
    end
  end
end
