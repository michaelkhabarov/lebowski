require "active_record"

class User < ActiveRecord::Base
  scope :enabled, -> { where.not(disabled: true) }

  def enable!
    update(disabled: false)
  end

  def disable!
    update(disabled: true)
  end
end
