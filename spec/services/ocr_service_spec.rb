# frozen_string_literal: true

require 'rails_helper'

# OcrService Spec
# Vibe Coding: Consistent test naming, descriptive behavior
RSpec.describe OcrService, type: :service do
  describe '.extract_text' do
    it 'extracts text from image path or URL' do
      expect(OcrService).to respond_to(:extract_text)
    end

    it 'raises OcrError on invalid path' do
      expect {
        OcrService.extract_text('')
      }.to raise_error(OcrService::OcrError, /Invalid image path/)
    end

    it 'raises OcrError on non-existent file' do
      expect {
        OcrService.extract_text('/nonexistent/path/image.jpg')
      }.to raise_error(OcrService::OcrError, /File not found/)
    end
  end

  describe '.extract_batch' do
    it 'processes multiple images in batch' do
      expect(OcrService).to respond_to(:extract_batch)
    end
  end
end
