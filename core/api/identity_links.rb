# frozen_string_literal: true

class IdentityLinksAPI < BaseAPI
  post "/identity-links" do
    link = current_user.identity_links.create!
    [201, { code: link.code, expires_at: link.expires_at }.to_json]
  end

  patch "/identity-links/:code" do
    provider = request.env["HTTP_X_IDENTITY_PROVIDER"]
    uid = request.env["HTTP_X_IDENTITY_UID"]
    halt 401, { error: "unauthorized" }.to_json unless provider && uid

    link = IdentityLink.find_by(code: params[:code])
    halt 404, { error: "not found" }.to_json unless link

    unless link.status == "pending"
      halt 422, { error: "link already #{link.status}" }.to_json
    end

    if link.expires_at < Time.current
      link.update!(status: "expired")
      halt 422, { error: "link expired" }.to_json
    end

    identity = Identity.find_by(provider: provider, uid: uid)
    if identity
      if identity.user_id == link.user_id
        link.update!(status: "claimed")
      else
        halt 409, { error: "identity already belongs to another user" }.to_json
      end
    else
      Identity.create!(provider: provider, uid: uid, user: link.user)
      link.update!(status: "claimed")
    end

    { status: link.status, user_id: link.user_id }.to_json
  end
end
