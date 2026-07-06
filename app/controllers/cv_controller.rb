class CvController < ApplicationController
  def show
    @cv = Cv.load
  end

  def pdf
    send_file Rails.root.join("content/cv.pdf"),
              filename: "Steve_Butterworth_CV.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end
end
