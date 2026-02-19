# frozen_string_literal: true

require "thor"
require_relative "core_client"
require_relative "commands/models"
require_relative "commands/agents"
require_relative "commands/tools"

class Erin < Thor
  desc "models SUBCOMMAND", "Manage models"
  subcommand "models", Commands::Models

  desc "agents SUBCOMMAND", "Manage agents"
  subcommand "agents", Commands::Agents

  desc "tools SUBCOMMAND", "Manage tools"
  subcommand "tools", Commands::Tools
end

$PROGRAM_NAME = "erin"
Erin.start(ARGV)
