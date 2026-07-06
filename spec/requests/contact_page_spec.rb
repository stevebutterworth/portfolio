require "rails_helper"

RSpec.describe "Contact page", type: :request do
  it "renders the pitch, availability chip and a web3forms contact form" do
    get "/contact"
    expect(response).to have_http_status(:ok)

    expect(response.body).to include("Let&rsquo;s build something.")
    expect(response.body).to include("AVAILABLE FOR WORK")
    expect(response.body).to include("steve@steveb.io")
    expect(response.body).to include("Ipswich, Suffolk")
    expect(response.body).to include("https://www.linkedin.com/in/stevebutterworth/")

    expect(response.body).to include('action="https://api.web3forms.com/submit"')
    expect(response.body).to include('method="POST"')
    expect(response.body).to include('name="access_key"')
    expect(response.body).to include('name="name"')
    expect(response.body).to include('name="email"')
    expect(response.body).to include('name="message"')
    expect(response.body).to include('name="botcheck"')
    expect(response.body).to include('name="subject"')
    expect(response.body).to include('value="New message from steveb.io"')
    expect(response.body).to include('name="from_name"')
    expect(response.body).to include('value="steveb.io contact form"')
  end
end
