# frozen_string_literal: true

class UserContactsAPI < BaseAPI
  get "/users/:user_id/contacts" do
    user = find_user!
    user.user_contacts.map { |c| serialize(c) }.to_json
  end

  get "/users/:user_id/contacts/:id" do
    user = find_user!
    contact = user.user_contacts.find(params[:id])
    serialize(contact).to_json
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  post "/users/:user_id/contacts" do
    user = find_user!
    data = json_body
    contact = user.user_contacts.new(data.slice(:first_name, :last_name, :email, :phone))
    halt 422, { errors: contact.errors.full_messages }.to_json unless contact.save
    [201, serialize(contact).to_json]
  end

  patch "/users/:user_id/contacts/:id" do
    user = find_user!
    contact = user.user_contacts.find(params[:id])
    contact.assign_attributes(json_body.slice(:first_name, :last_name, :email, :phone))
    halt 422, { errors: contact.errors.full_messages }.to_json unless contact.save
    serialize(contact).to_json
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  delete "/users/:user_id/contacts/:id" do
    user = find_user!
    contact = user.user_contacts.find(params[:id])
    contact.destroy
    [204, ""]
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  private

  def find_user!
    if params[:user_id] == "me"
      current_user
    else
      User.find(params[:user_id])
    end
  rescue ActiveRecord::RecordNotFound
    halt 404, { error: "not found" }.to_json
  end

  def serialize(contact)
    {
      id: contact.id,
      first_name: contact.first_name,
      last_name: contact.last_name,
      email: contact.email,
      phone: contact.phone
    }
  end
end
