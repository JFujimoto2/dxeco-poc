class SaasAccountImportService < BaseCsvImportService
  private

  def header_mapping
    {
      "SaaS名" => "saas_name",
      "ユーザーメール" => "user_email",
      "メンバー名" => "member_name",
      "部署" => "department",
      "アカウントメール" => "account_email",
      "ロール" => "role",
      "ステータス" => "status",
      "最終ログイン" => "last_login_at"
    }
  end

  def import_row(row, line_num, result)
    saas = Saas.find_by(name: row["saas_name"])
    user = find_user(row)

    unless saas
      record_error(result, line_num, "SaaS '#{row['saas_name']}' が見つかりません")
      return
    end

    unless user
      record_error(result, line_num, "ユーザー '#{row['user_email'] || row['account_email']}' が見つかりません")
      return
    end

    account = SaasAccount.new(
      saas: saas,
      user: user,
      account_email: row["account_email"],
      role: row["role"],
      status: row["status"].presence || "active"
    )

    save_record(account, result, line_num)
  end

  def find_user(row)
    # テンプレート形式: user_email列あり / エクスポート形式: account_email列で検索
    if row["user_email"].present?
      User.find_by(email: row["user_email"])
    else
      User.find_by(email: row["account_email"])
    end
  end
end
