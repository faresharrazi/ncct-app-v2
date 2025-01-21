module ApplicationHelper
  def owner_or_partner?(main_account)
    main_account.owners.include?(current_user)
  end

  def toggle_sort(current_sort, column)
    if current_sort == "#{column}_asc"
      "#{column}_desc"
    else
      "#{column}_asc"
    end
  end
end