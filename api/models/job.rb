require "active_record"

module Erinos
  class Job < ActiveRecord::Base
    serialize :params, coder: JSON
    serialize :result, coder: JSON
  end
end
