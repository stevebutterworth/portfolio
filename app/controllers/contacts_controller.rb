class ContactsController < ApplicationController
  def show
    @web3forms_access_key = Rails.application.credentials.dig(:web3forms, :access_key) ||
      ENV["WEB3FORMS_ACCESS_KEY"] ||
      "REPLACE-ME"
  end
end
