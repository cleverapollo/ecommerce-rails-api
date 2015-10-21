module SectoralAlgorythms
  module VirtualProfile
    module GenderLinkable
      def link_create_gender(item)
        item_gender = item.try(:gender)
        profile_gender = current_gender
        if item_gender && profile_gender && item_gender!=profile_gender
          linked_profile = @profile.linked_gender_profile
          linked_profile ||= @profile.create_linked_profile(:gender)
          initialize(linked_profile) if linked_profile
        end
      end


      def link_gender(item)
        item_gender = item.try(:gender)
        profile_gender = current_gender
        if item_gender && profile_gender && item_gender!=profile_gender
          linked_profile = @profile.linked_gender_profile
          initialize(linked_profile) if linked_profile
        end
      end

      def current_gender
        cur_gender = @profile.gender
        return false if cur_gender['m']==cur_gender['f']
        cur_gender.delete 'history'
        cur_gender.max_by { |_, v| v }.first.to_sym
      end
    end
  end
end
