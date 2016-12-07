AccountUnlocker = Struct.new(:id)
class AccountUnlocker
  def perform
    if account = Account.active.find_by_id(id)
      account.update(locked: false) if account.locked?
    else
      false
    end
  end
end
