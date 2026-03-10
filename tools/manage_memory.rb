class ManageMemory < RubyLLM::Tool
  description "Save, list, or delete things to remember about the user across conversations."

  param :action, desc: "One of: save, list, delete"
  param :content, desc: "What to remember (for save)", required: false
  param :memory_id, desc: "Memory ID to delete (for delete)", required: false

  def initialize(user:)
    @user = user
  end

  def execute(action:, content: nil, memory_id: nil)
    case action
    when "save" then save(content)
    when "list" then list
    when "delete" then delete(memory_id)
    else "Unknown action: #{action}. Use save, list, or delete."
    end
  end

  private

  def save(content)
    return "Content is required." unless content

    memory = @user.memories.create!(content: content)
    "Saved memory ##{memory.id}."
  end

  def list
    memories = @user.memories.order(:created_at)
    return "No memories stored." if memories.empty?

    memories.map { |m| "##{m.id} | #{m.content}" }.join("\n")
  end

  def delete(memory_id)
    return "A memory_id is required." unless memory_id

    memory = @user.memories.find_by(id: memory_id)
    return "Memory ##{memory_id} not found." unless memory

    memory.destroy!
    "Deleted memory ##{memory_id}."
  end
end
