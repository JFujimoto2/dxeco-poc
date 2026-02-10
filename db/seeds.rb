puts "=== Seeding data ==="

# --- Users ---
users_data = [
  { display_name: "管理者 太郎", email: "admin@example.com", department: "情報システム部", job_title: "部長", role: "admin" },
  { display_name: "鈴木 花子", email: "suzuki@example.com", department: "情報システム部", job_title: "主任", role: "manager" },
  { display_name: "田中 一郎", email: "tanaka@example.com", department: "営業本部", job_title: "課長", role: "viewer" },
  { display_name: "佐藤 美咲", email: "sato@example.com", department: "営業本部", job_title: "主任", role: "viewer" },
  { display_name: "山田 健太", email: "yamada@example.com", department: "管理部", job_title: "係長", role: "viewer" }
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
  { name: "Notion", url: "https://www.notion.so", description: "ナレッジベース・プロジェクト管理" }
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
  { name: "ATBB", url: "https://atbb.athome.co.jp", description: "不動産業者間サイト" }
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

# --- Task Presets ---
admin_user = users.first
it_user = users.second

offboarding_preset = TaskPreset.find_or_create_by!(name: "退職処理") do |p|
  p.task_type = "offboarding"
  p.description = "退職者のSaaSアカウント削除・備品返却・機密保持契約の手続き"
end
[
  { action_type: "account_delete", description: "全SaaSアカウントの削除", default_assignee: it_user, position: 1 },
  { action_type: "pc_return", description: "PC返却", default_assignee: admin_user, position: 2 },
  { action_type: "phone_return", description: "社用携帯返却", default_assignee: admin_user, position: 3 },
  { action_type: "nda", description: "機密保持契約締結", default_assignee: nil, position: 4 }
].each do |item_data|
  offboarding_preset.task_preset_items.find_or_create_by!(action_type: item_data[:action_type]) do |i|
    i.description = item_data[:description]
    i.default_assignee = item_data[:default_assignee]
    i.position = item_data[:position]
  end
end

onboarding_preset = TaskPreset.find_or_create_by!(name: "入社処理") do |p|
  p.task_type = "onboarding"
  p.description = "新入社員のSaaSアカウント作成・PC準備"
end
[
  { action_type: "account_create", description: "必要SaaSアカウントの作成", default_assignee: it_user, position: 1 },
  { action_type: "other", description: "PC準備・セットアップ", default_assignee: admin_user, position: 2 },
  { action_type: "other", description: "社用携帯の準備", default_assignee: admin_user, position: 3 }
].each do |item_data|
  offboarding_preset.task_preset_items.find_or_create_by!(description: item_data[:description]) do |i|
    i.action_type = item_data[:action_type]
    i.default_assignee = item_data[:default_assignee]
    i.position = item_data[:position]
  end
end

transfer_preset = TaskPreset.find_or_create_by!(name: "異動処理") do |p|
  p.task_type = "transfer"
  p.description = "異動に伴うSaaSアカウントの権限変更・追加・削除"
end
[
  { action_type: "other", description: "異動元部署のSaaSアカウント権限確認", default_assignee: it_user, position: 1 },
  { action_type: "other", description: "異動先部署の必要SaaSアカウント追加", default_assignee: it_user, position: 2 },
  { action_type: "other", description: "不要アカウントの削除", default_assignee: it_user, position: 3 }
].each do |item_data|
  transfer_preset.task_preset_items.find_or_create_by!(description: item_data[:description]) do |i|
    i.action_type = item_data[:action_type]
    i.default_assignee = item_data[:default_assignee]
    i.position = item_data[:position]
  end
end
puts "  Task Presets: #{TaskPreset.count}"

# --- Sample Task ---
target_user = users.fourth # 佐藤 美咲
unless Task.exists?(target_user: target_user, task_type: "offboarding")
  task = Task.create!(
    title: "#{target_user.display_name}の退職処理",
    task_type: "offboarding",
    target_user: target_user,
    created_by: admin_user,
    status: "in_progress",
    due_date: 1.week.from_now.to_date
  )
  target_user.saas_accounts.where(status: "active").includes(:saas).each_with_index do |account, i|
    task.task_items.create!(
      action_type: "account_delete",
      description: "#{account.saas.name} アカウント削除",
      saas: account.saas,
      assignee: it_user,
      status: i < 2 ? "completed" : "pending",
      completed_at: i < 2 ? 1.day.ago : nil
    )
  end
  task.task_items.create!(action_type: "pc_return", description: "PC返却", assignee: admin_user, status: "pending")
  task.task_items.create!(action_type: "nda", description: "機密保持契約締結", status: "pending")
end
puts "  Tasks: #{Task.count}"

# --- Sample Survey ---
unless Survey.exists?(survey_type: "account_review")
  survey = Survey.create!(
    title: "2026年Q1 アカウント棚卸し",
    survey_type: "account_review",
    created_by: admin_user,
    status: "active",
    sent_at: 3.days.ago,
    deadline: 1.week.from_now
  )
  SaasAccount.where(status: "active").includes(:user, :saas).each do |account|
    responded = [ true, true, false ].sample
    survey.survey_responses.create!(
      user: account.user,
      saas_account: account,
      response: responded ? [ "using", "using", "not_using" ].sample : nil,
      responded_at: responded ? rand(1..3).days.ago : nil
    )
  end
end
puts "  Surveys: #{Survey.count}"

# --- Sample Approval Requests ---
unless ApprovalRequest.any?
  ApprovalRequest.create!(
    request_type: "new_saas",
    requester: users.third, # 田中
    saas_name: "Figma",
    reason: "デザインチームで利用するUI/UXデザインツール。現在PowerPointで代用しているが効率が悪い。",
    estimated_cost: 5000,
    user_count: 3,
    status: "pending"
  )
  ApprovalRequest.create!(
    request_type: "add_account",
    requester: users.fourth, # 佐藤
    saas: Saas.find_by(name: "Notion"),
    reason: "営業本部のナレッジ共有のため、Notionアカウントを追加したい。",
    estimated_cost: 1000,
    user_count: 1,
    status: "approved",
    approved_by: admin_user,
    approved_at: 2.days.ago
  )
  ApprovalRequest.create!(
    request_type: "new_saas",
    requester: users.fifth, # 山田
    saas_name: "ChatGPT Enterprise",
    reason: "管理部の業務効率化のため、AIアシスタントを導入したい。",
    estimated_cost: 30000,
    user_count: 10,
    status: "rejected",
    approved_by: admin_user,
    approved_at: 1.day.ago,
    rejection_reason: "コストが予算を超過しているため、まずは無料プランで検証をお願いします。"
  )
end
puts "  Approval Requests: #{ApprovalRequest.count}"

puts "=== Done ==="
