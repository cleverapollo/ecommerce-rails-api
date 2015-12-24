module SectoralAlgorythms
  class Service

    def self.all_virtual_profile_fields
      # Список отраслевых, реагирующих на действия пользователя
      [
          VirtualProfile::Gender,
          VirtualProfile::Size,
          VirtualProfile::Physiology,
          VirtualProfile::Periodicly
      ]
    end

    def initialize(user, algorythms=[])
      @profile = user.profile
      @algorythms = algorythms.map {|algorythm| algorythm.new(@profile)}
    end

    def trigger_action(action, items)
      changes = {}

      # Обновляем информацию по профилю
      @algorythms.each do |algorythm|
        algorythm.trigger_action(action, items)
        algorythm.recalculate
        changes.merge!(algorythm.attributes_for_update)
      end

      @profile.update(changes) if changes.any?
      @profile.reload
    end

    def merge(slave)
      changes = {}
      slave_profile = slave.profile
      if slave_profile
        @algorythms.each do |algorythm|
          algorythm.merge(slave_profile)
          algorythm.recalculate
          changes.merge!(algorythm.attributes_for_update)
        end
        @profile.update(changes) if changes.any?
        @profile.reload
      end

    end


  end
end
