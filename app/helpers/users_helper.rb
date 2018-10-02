module UsersHelper
  def confirmation_status user
    user.confirmed_at? ? "Confirmed" : "Unconfirmed"
  end

  def activation_status user
    user.deleted_at? ? "Deactivated" : "Activated"
  end
end
