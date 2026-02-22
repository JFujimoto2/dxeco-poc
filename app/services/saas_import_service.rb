class SaasImportService < BaseCsvImportService
  private

  def header_mapping
    {
      "SaaS名" => "name",
      "カテゴリ" => "category",
      "ステータス" => "status",
      "URL" => "url",
      "管理画面URL" => "admin_url",
      "担当者" => "owner",
      "説明" => "description",
      "プラン" => "plan_name",
      "月額" => "price_cents",
      "請求サイクル" => "billing_cycle",
      "契約期限" => "expires_on",
      "個人情報取扱い" => "handles_personal_data",
      "認証方式" => "auth_method",
      "データ保存先" => "data_location"
    }
  end

  AUTH_METHOD_MAP = { "SSO" => "sso", "sso" => "sso", "パスワード" => "password", "password" => "password", "MFA" => "mfa", "mfa" => "mfa", "その他" => "other_auth", "other" => "other_auth" }.freeze
  DATA_LOCATION_MAP = { "国内" => "domestic", "domestic" => "domestic", "海外" => "overseas", "overseas" => "overseas", "不明" => "unknown", "unknown" => "unknown" }.freeze

  def import_row(row, line_num, result)
    if Saas.exists?(name: row["name"])
      record_error(result, line_num, "SaaS '#{row['name']}' は既に存在します")
      return
    end

    saas = Saas.new(
      name: row["name"],
      category: row["category"],
      url: row["url"],
      admin_url: row["admin_url"],
      description: row["description"],
      status: row["status"].presence || "active",
      handles_personal_data: %w[あり true 1 はい].include?(row["handles_personal_data"]&.strip&.downcase || row["handles_personal_data"]&.strip),
      auth_method: AUTH_METHOD_MAP[row["auth_method"]&.strip],
      data_location: DATA_LOCATION_MAP[row["data_location"]&.strip]
    )

    save_record(saas, result, line_num)
  end
end
