# frozen_string_literal: true

class ModelsAPI < BaseAPI
  get "/models" do
    Model.all.map { |m| serialize(m) }.to_json
  end

  get "/models/:id" do
    serialize(find_model!).to_json
  end

  post "/models" do
    model = Model.new(json_body.slice(:provider, :name, :credentials))
    halt 422, { errors: model.errors.full_messages }.to_json unless model.save
    [201, serialize(model).to_json]
  end

  patch "/models/:id" do
    model = find_model!
    halt 422, { errors: model.errors.full_messages }.to_json unless model.update(json_body.slice(:provider, :name, :credentials))
    serialize(model).to_json
  end

  delete "/models/:id" do
    find_model!.destroy
    [204, ""]
  end

  private

  def find_model!
    Model.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  def serialize(model)
    { id: model.id, provider: model.provider, name: model.name,
      credentials: model.credentials,
      created_at: model.created_at, updated_at: model.updated_at }
  end
end
