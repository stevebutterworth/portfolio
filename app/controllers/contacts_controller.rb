class ContactsController < ApplicationController
  # The Web3Forms access key is public-facing by design: it ships in the
  # rendered form HTML either way, so a committed default is fine here.
  DEFAULT_WEB3FORMS_ACCESS_KEY = "684b21da-92e9-4ed8-9d59-54db0c5f336c"

  def show
    @web3forms_access_key = Rails.application.credentials.dig(:web3forms, :access_key) ||
      ENV["WEB3FORMS_ACCESS_KEY"] ||
      DEFAULT_WEB3FORMS_ACCESS_KEY
  end
end
