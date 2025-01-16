module MainAccountsHelper
  def balance_badge_class(balance)
    if balance < 100
      'bg-danger'
    elsif balance < 1000
      'bg-warning'
    else
      'bg-success'
    end
  end

  def available_percentage_badge_class(available_percentage)
    available_percentage.zero? ? 'bg-success' : 'bg-warning'
  end
end