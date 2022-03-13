require "active_record"
require "./models/tinkoff"

class Atm < ActiveRecord::Base
  class << self
    def refilled_atms
      available_atms = Tinkoff.new.available_atms
      Atm.where.not(uid: available_atms.map(&:uid)).destroy_all
      result = []

      available_atms.each do |new_atm|
        atm = Atm.find_or_initialize_by(uid: new_atm.uid)
        atm.amount_usd ||= 0

        result.push(new_atm) if new_atm.amount_usd > atm.amount_usd && new_atm.amount_usd >= 300

        atm.update(amount_usd: new_atm.amount_usd)
      end

      result
    end
  end
end
