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
      "契約期限" => "expires_on"
    }
  end

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
      status: row["status"].presence || "active"
    )

    save_record(saas, result, line_num)
  end
end
