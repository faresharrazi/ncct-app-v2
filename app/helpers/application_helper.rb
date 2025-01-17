module ApplicationHelper
  def owner_or_partner?(main_account)
    main_account.owners.include?(current_user)
  end
end