# frozen_string_literal: true

class Erin < RubyLLM::Agent
  def self.ollama_context
    @ollama_context ||= RubyLLM.context do |c|
      c.ollama_api_base = ENV.fetch("OLLAMA_API_BASE", "http://ollama:11434/v1")
    end
  end
  private_class_method :ollama_context

  context ollama_context
  model "gpt-oss:120b-cloud", provider: :ollama, assume_model_exists: true
  instructions

  def initialize(**kwargs)
    super(chat: self.class.context.chat(**self.class.chat_kwargs), **kwargs)
  end
end
