require "rails_helper"
require "csv"

# テスト用の具象クラス
class TestImportService < BaseCsvImportService
  def header_mapping
    { "名前" => "name", "メール" => "email" }
  end

  def import_row(row, line_num, result)
    user = User.new(
      display_name: row["name"],
      email: row["email"],
      entra_id_sub: SecureRandom.uuid,
      role: "viewer"
    )
    save_record(user, result, line_num)
  end
end

RSpec.describe BaseCsvImportService, type: :service do
  let(:csv_dir) { Rails.root.join("tmp", "test_csv") }

  before { FileUtils.mkdir_p(csv_dir) }
  after { FileUtils.rm_rf(csv_dir) }

  def write_csv(filename, content)
    path = csv_dir.join(filename)
    File.write(path, "\xEF\xBB\xBF" + content) # BOM付きUTF-8
    path.to_s
  end

  describe "#call" do
    it "CSVを読み込んでインポートする" do
      path = write_csv("test.csv", "名前,メール\n田中太郎,tanaka@example.com\n")
      result = TestImportService.new(path).call
      expect(result[:success_count]).to eq(1)
      expect(result[:error_count]).to eq(0)
      expect(User.find_by(email: "tanaka@example.com")).to be_present
    end

    it "複数行を処理する" do
      path = write_csv("test.csv", "名前,メール\n田中,a@example.com\n鈴木,b@example.com\n")
      result = TestImportService.new(path).call
      expect(result[:success_count]).to eq(2)
    end

    it "バリデーションエラーの行をスキップして残りを処理する" do
      create(:user, email: "dup@example.com")
      path = write_csv("test.csv", "名前,メール\n重複,dup@example.com\n正常,ok@example.com\n")
      result = TestImportService.new(path).call
      expect(result[:success_count]).to eq(1)
      expect(result[:error_count]).to eq(1)
      expect(result[:errors].first).to include("2行目")
    end
  end

  describe "#normalize_headers" do
    it "日本語ヘッダーを英語キーにマッピングする" do
      path = write_csv("jp.csv", "名前,メール\nテスト,test@example.com\n")
      result = TestImportService.new(path).call
      expect(result[:success_count]).to eq(1)
    end

    it "マッピングにないヘッダーはそのまま使用する" do
      path = write_csv("mixed.csv", "名前,email\n混在,mixed@example.com\n")
      result = TestImportService.new(path).call
      expect(result[:success_count]).to eq(1)
    end

    it "英語ヘッダーもそのまま処理できる" do
      path = write_csv("en.csv", "name,email\n英語,en@example.com\n")
      result = TestImportService.new(path).call
      expect(result[:success_count]).to eq(1)
    end
  end

  describe "エラー記録" do
    it "行番号付きのエラーメッセージを記録する" do
      path = write_csv("err.csv", "名前,メール\n,\n")
      result = TestImportService.new(path).call
      expect(result[:error_count]).to eq(1)
      expect(result[:errors].first).to match(/2行目/)
    end
  end
end
