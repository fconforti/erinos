# frozen_string_literal: true

require "thor"
require "erinos_client"
require_relative "commands/models"
require_relative "commands/agents"
require_relative "commands/tools"
require_relative "commands/chat"

class Erin < Thor
  desc "chat", "Start an interactive chat with Erin"
  subcommand "chat", Commands::Chat

  desc "models SUBCOMMAND", "Manage models"
  subcommand "models", Commands::Models

  desc "agents SUBCOMMAND", "Manage agents"
  subcommand "agents", Commands::Agents

  desc "tools SUBCOMMAND", "Manage tools"
  subcommand "tools", Commands::Tools
end

$PROGRAM_NAME = "erin"
Erin.start(ARGV)
