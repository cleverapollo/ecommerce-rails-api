module SectoralAlgorythms
  class Service

    def self.all_virtual_profile_fields
      # [Wear::Gender, Wear::Size, ]
      [VirtualProfile::Gender, VirtualProfile::Size, VirtualProfile::Physiology, VirtualProfile::Periodicly]
    end

    def initialize(user, algorythms=[])
      @profile = user.profile
      @algorythms = algorythms.map {|algorythm| algorythm.new(@profile)}
    end

    def trigger_action(action, items)
      changes = {}
      @algorythms.each do |algorythm|
        algorythm.trigger_action(action, items)
        algorythm.recalculate
        changes.merge!(algorythm.attributes_for_update)
      end

      @profile.update(changes)
    end

    def merge(slave)
      changes = {}
      @algorythms.each do |algorythm|
        algorythm.merge(slave)
       # algorythm.recalculate
        changes.merge!(algorythm.attributes_for_update)
      end

      @profile.update(changes) if changes.any?
    end




  end
end
