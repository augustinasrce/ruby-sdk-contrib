# frozen_string_literal: true

class Service
  def self.run(**args)
    new(**args).run
  end

  def initialize(*)
    raise NotImplementedError, "must be defined by subclasses"
  end
end