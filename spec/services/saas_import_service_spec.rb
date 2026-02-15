require "rails_helper"

RSpec.describe SaasImportService do
  let(:valid_file) { Rails.root.join("spec/fixtures/files/saas_import.csv") }
  let(:error_file) { Rails.root.join("spec/fixtures/files/saas_import_with_errors.csv") }

  describe "#call" do
    it "CSVからSaaSを一括登録する" do
      result = SaasImportService.new(valid_file).call
      expect(result[:success_count]).to eq(3)
      expect(result[:error_count]).to eq(0)
      expect(Saas.find_by(name: "Slack")).to be_present
      expect(Saas.find_by(name: "Zoom")).to be_present
      expect(Saas.find_by(name: "いえらぶCLOUD")).to be_present
    end

    it "カテゴリとURLが正しく設定される" do
      SaasImportService.new(valid_file).call
      slack = Saas.find_by(name: "Slack")
      expect(slack.category).to eq("一般")
      expect(slack.url).to eq("https://slack.com")
    end

    it "エラー行をスキップしてレポートを返す" do
      result = SaasImportService.new(error_file).call
      expect(result[:success_count]).to eq(2)
      expect(result[:error_count]).to eq(1)
      expect(result[:errors].first).to include("3")
    end

    it "重複するSaaS名はスキップする" do
      create(:saas, name: "Slack")
      result = SaasImportService.new(valid_file).call
      expect(result[:success_count]).to eq(2)
      expect(result[:error_count]).to eq(1)
    end

    it "日本語ヘッダー（エクスポート形式）のCSVをインポートできる" do
      file = Tempfile.new([ "saas_jp", ".csv" ])
      file.write("\uFEFFSaaS名,カテゴリ,ステータス,URL,担当者,プラン,月額,請求サイクル,契約期限\n")
      file.write("TestSaaS,一般IT,active,https://test.com,,,,,\n")
      file.rewind

      result = SaasImportService.new(file.path).call
      expect(result[:success_count]).to eq(1)
      expect(result[:error_count]).to eq(0)
      expect(Saas.find_by(name: "TestSaaS")).to be_present
    ensure
      file.close!
    end

    it "テンプレートCSVをそのままインポートできる" do
      file = Tempfile.new([ "saas_tpl", ".csv" ])
      file.write("\uFEFFSaaS名,カテゴリ,ステータス,URL,管理画面URL,説明\n")
      file.write("サンプルSaaS,一般,active,https://example.com,,サービスの説明\n")
      file.rewind

      result = SaasImportService.new(file.path).call
      expect(result[:success_count]).to eq(1)
      expect(result[:error_count]).to eq(0)
    ensure
      file.close!
    end

    it "テンプレートCSVでもSaaS名の重複はエラーになる" do
      create(:saas, name: "サンプルSaaS")
      file = Tempfile.new([ "saas_dup", ".csv" ])
      file.write("\uFEFFSaaS名,カテゴリ,ステータス,URL,管理画面URL,説明\n")
      file.write("サンプルSaaS,一般,active,https://example.com,,サービスの説明\n")
      file.rewind

      result = SaasImportService.new(file.path).call
      expect(result[:success_count]).to eq(0)
      expect(result[:error_count]).to eq(1)
    ensure
      file.close!
    end
  end
end
