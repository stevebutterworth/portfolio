require "rails_helper"

RSpec.describe "Cv page", type: :request do
  it "renders the sidebar, experience and a copy-for-ai payload" do
    get "/cv"
    expect(response).to have_http_status(:ok)

    cv = Cv.load
    expect(response.body).to include(cv.name)
    expect(response.body).to include(cv.title)
    expect(response.body).to include("Core skills")
    expect(response.body).to include("// Experience")
    expect(response.body).to include("Select engagements")
    expect(response.body).to include("Additional experience")
    expect(response.body).to include(cv_pdf_path)
    expect(response.body).to include("data-clipboard-text=")
    expect(response.body).to include(CGI.escapeHTML(cv.to_markdown.lines.first.chomp))
  end

  it "serves the pdf as an attachment" do
    get "/cv.pdf"
    expect(response).to have_http_status(:ok)
    expect(response.headers["Content-Type"]).to eq("application/pdf")
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.headers["Content-Disposition"]).to include("Steve_Butterworth_CV.pdf")
  end
end
