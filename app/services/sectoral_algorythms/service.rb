module SectoralAlgorythms
  class Service

    def self.all_algorythms
      # [Wear::Gender, Wear::Size, Cosmetic::Physiology, Cosmetic::Periodicly]
      [Wear::Gender, Wear::Size]
    end

    def initialize(user, algorythms=[])
      @user = user
      @algorythms = algorythms.map {|algorythm| algorythm.new(@user)}
    end

    def trigger_action(action, items)
      changes = {}
      @algorythms.each do |algorythm|
        algorythm.trigger_action(action, items)
        algorythm.recalculate
        changes.merge!(algorythm.attributes_for_update)
      end

      @user.update(changes)
    end

    def merge(slave)
      changes = {}
      @algorythms.each do |algorythm|
        algorythm.merge(slave)
        algorythm.recalculate
        changes.merge!(algorythm.attributes_for_update)
      end

      @user.update(changes) if changes.any?
    end




  end
end
