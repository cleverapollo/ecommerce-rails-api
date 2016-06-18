class UserProfile::PropertyCalculator


  # Вычисляет пол пользователя по историческим данным
  # @param user [User]
  # @return String – m|f
  def calculate_gender(user)
    score = { male: 0, female: 0 }
    ProfileEvent.where(user_id: user.id, industry: ['fashion', 'cosmetic'], property: 'gender').each do |event|
      if event.value == 'm'
        score[:male] += event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5
      end
      if event.value == 'f'
        score[:female] += event.views.to_i + event.carts.to_i * 2 + event.purchases.to_i * 5
      end
    end
    return nil if score[:male] == score[:female]
    return 'm' if score[:male] > score[:female]
    return 'f' if score[:male] < score[:female]
  end


end