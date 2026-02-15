require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#weekday_label" do
    it "日付の曜日を返す" do
      date = Date.new(2026, 2, 15) # 日曜日
      expect(helper.weekday_label(date)).to eq("(日)")
    end

    it "nilの場合は空文字を返す" do
      expect(helper.weekday_label(nil)).to eq("")
    end
  end

  describe "#format_date_with_weekday" do
    it "日付と曜日を返す" do
      date = Date.new(2026, 2, 16) # 月曜日
      expect(helper.format_date_with_weekday(date)).to eq("2026/02/16 (月)")
    end

    it "nilの場合は空文字を返す" do
      expect(helper.format_date_with_weekday(nil)).to eq("")
    end
  end

  describe "#safe_url_link" do
    it "http URLの場合はリンクを返す" do
      result = helper.safe_url_link("https://example.com")
      expect(result).to include('href="https://example.com"')
      expect(result).to include('target="_blank"')
    end

    it "空文字の場合はハイフンを返す" do
      expect(helper.safe_url_link("")).to eq("-")
    end

    it "nilの場合はハイフンを返す" do
      expect(helper.safe_url_link(nil)).to eq("-")
    end

    it "不正なスキームの場合はエスケープして返す" do
      result = helper.safe_url_link("javascript:alert(1)")
      expect(result).not_to include("href")
    end

    it "不正なURIの場合はエスケープして返す" do
      result = helper.safe_url_link("ht tp://invalid url")
      expect(result).not_to include("href")
    end
  end
end
