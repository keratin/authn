AccountArchiver = Struct.new(:id)
class AccountArchiver
  def perform
    if (account = Account.active.find_by_id(id))
      account.update(
        username: nil,
        password: nil,
        deleted_at: Time.zone.now
      )

      true
    else
      false
    end
  end
end
