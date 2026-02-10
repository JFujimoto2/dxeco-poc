puts "=== Seeding data ==="

# --- Users ---
users_data = [
  { display_name: "管理者 太郎", email: "admin@example.com", department: "情報システム部", job_title: "部長", role: "admin" },
  { display_name: "鈴木 花子", email: "suzuki@example.com", department: "情報システム部", job_title: "主任", role: "manager" },
  { display_name: "田中 一郎", email: "tanaka@example.com", department: "営業本部", job_title: "課長", role: "viewer" },
  { display_name: "佐藤 美咲", email: "sato@example.com", department: "営業本部", job_title: "主任", role: "viewer" },
  { display_name: "山田 健太", email: "yamada@example.com", department: "管理部", job_title: "係長", role: "viewer" },
]

users = users_data.map do |data|
  User.find_or_create_by!(email: data[:email]) do |u|
    u.entra_id_sub = SecureRandom.uuid
    u.display_name = data[:display_name]
    u.department = data[:department]
    u.job_title = data[:job_title]
    u.role = data[:role]
  end
end
puts "  Users: #{User.count}"

# --- SaaS (一般) ---
general_saases = [
  { name: "Slack", url: "https://slack.com", description: "ビジネスチャットツール" },
  { name: "Google Workspace", url: "https://workspace.google.com", description: "メール・ドキュメント・カレンダー" },
  { name: "Microsoft 365", url: "https://www.microsoft.com/microsoft-365", description: "Office生産性スイート" },
  { name: "Salesforce", url: "https://www.salesforce.com", description: "CRM・営業管理" },
  { name: "Zoom", url: "https://zoom.us", description: "ビデオ会議" },
  { name: "Box", url: "https://www.box.com", description: "クラウドストレージ" },
  { name: "Notion", url: "https://www.notion.so", description: "ナレッジベース・プロジェクト管理" },
]

general_saases.each do |data|
  saas = Saas.find_or_create_by!(name: data[:name]) do |s|
    s.category = "一般"
    s.url = data[:url]
    s.description = data[:description]
    s.owner = users.first
    s.status = "active"
  end
  saas.create_saas_contract!(vendor: "#{data[:name]} Inc.", billing_cycle: "yearly") unless saas.saas_contract
end

# --- SaaS (不動産管理) ---
realestate_saases = [
  { name: "いえらぶCLOUD", url: "https://ielove-cloud.jp", description: "不動産業務支援クラウド" },
  { name: "賃貸革命", url: "https://www.n-create.co.jp", description: "賃貸管理システム" },
  { name: "ESいい物件One", url: "https://www.es-service.net", description: "不動産流通プラットフォーム" },
  { name: "@プロパティ", url: "https://at-property.com", description: "不動産管理システム" },
  { name: "ATBB", url: "https://atbb.athome.co.jp", description: "不動産業者間サイト" },
]

realestate_saases.each do |data|
  saas = Saas.find_or_create_by!(name: data[:name]) do |s|
    s.category = "不動産管理"
    s.url = data[:url]
    s.description = data[:description]
    s.owner = users.second
    s.status = "active"
  end
  saas.create_saas_contract!(vendor: data[:name], billing_cycle: "monthly") unless saas.saas_contract
end
puts "  SaaS: #{Saas.count}"

# --- SaaS Accounts ---
all_saases = Saas.all.to_a
users.each do |user|
  # 各ユーザーに3〜5個のSaaSアカウントを割り当て
  assigned = all_saases.sample(rand(3..5))
  assigned.each do |saas|
    SaasAccount.find_or_create_by!(saas: saas, user: user) do |a|
      a.account_email = user.email
      a.role = user.admin? ? "admin" : "member"
      a.status = "active"
    end
  end
end
puts "  SaaS Accounts: #{SaasAccount.count}"

puts "=== Done ==="
