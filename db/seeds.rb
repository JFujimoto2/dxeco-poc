puts "=== Seeding data ==="

# --- Users (15名) ---
users_data = [
  # 情シス (3名)
  { display_name: "管理者 太郎", email: "admin@example.com", department: "情報システム部", job_title: "部長", role: "admin" },
  { display_name: "鈴木 花子", email: "suzuki@example.com", department: "情報システム部", job_title: "主任", role: "manager" },
  { display_name: "高橋 大輔", email: "takahashi@example.com", department: "情報システム部", job_title: "担当", role: "viewer" },
  # 営業部 (4名)
  { display_name: "田中 一郎", email: "tanaka@example.com", department: "営業部", job_title: "課長", role: "viewer" },
  { display_name: "佐藤 美咲", email: "sato@example.com", department: "営業部", job_title: "主任", role: "viewer" },
  { display_name: "伊藤 健太", email: "ito@example.com", department: "営業部", job_title: "担当", role: "viewer" },
  { display_name: "渡辺 あゆみ", email: "watanabe@example.com", department: "営業部", job_title: "担当", role: "viewer" },
  # 管理部 (3名)
  { display_name: "山田 健太", email: "yamada@example.com", department: "管理部", job_title: "係長", role: "viewer" },
  { display_name: "中村 直子", email: "nakamura@example.com", department: "管理部", job_title: "主任", role: "viewer" },
  { display_name: "小林 誠", email: "kobayashi@example.com", department: "管理部", job_title: "担当", role: "viewer" },
  # 企画部 (3名)
  { display_name: "加藤 由美", email: "kato@example.com", department: "企画部", job_title: "課長", role: "manager" },
  { display_name: "吉田 翔太", email: "yoshida@example.com", department: "企画部", job_title: "主任", role: "viewer" },
  { display_name: "松本 さくら", email: "matsumoto@example.com", department: "企画部", job_title: "担当", role: "viewer" },
  # 役員 (2名)
  { display_name: "山本 浩二", email: "yamamoto@example.com", department: "経営企画室", job_title: "取締役", role: "admin" },
  { display_name: "井上 雅子", email: "inoue@example.com", department: "経営企画室", job_title: "執行役員", role: "manager" }
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

admin_user = users[0]  # 管理者 太郎
it_user    = users[1]  # 鈴木 花子

# --- SaaS (30件) ---

# 一般IT (14件)
general_saases_data = [
  { name: "Slack", url: "https://slack.com", description: "ビジネスチャットツール" },
  { name: "Google Workspace", url: "https://workspace.google.com", description: "メール・ドキュメント・カレンダー" },
  { name: "Microsoft 365", url: "https://www.microsoft.com/microsoft-365", description: "Office生産性スイート" },
  { name: "Zoom", url: "https://zoom.us", description: "ビデオ会議" },
  { name: "Box", url: "https://www.box.com", description: "クラウドストレージ" },
  { name: "Notion", url: "https://www.notion.so", description: "ナレッジベース・プロジェクト管理" },
  { name: "Salesforce", url: "https://www.salesforce.com", description: "CRM・営業管理" },
  { name: "GitHub", url: "https://github.com", description: "ソースコード管理" },
  { name: "Jira", url: "https://www.atlassian.com/software/jira", description: "プロジェクト管理・課題追跡" },
  { name: "Confluence", url: "https://www.atlassian.com/software/confluence", description: "社内Wiki・ドキュメント管理" },
  { name: "1Password", url: "https://1password.com", description: "パスワード管理" },
  { name: "DocuSign", url: "https://www.docusign.com", description: "電子署名" },
  { name: "Canva", url: "https://www.canva.com", description: "デザインツール" },
  { name: "ChatGPT Enterprise", url: "https://openai.com/chatgpt/enterprise", description: "AIアシスタント" }
]

general_saases_data.each do |data|
  saas = Saas.find_or_create_by!(name: data[:name]) do |s|
    s.category = "一般IT"
    s.url = data[:url]
    s.description = data[:description]
    s.owner = admin_user
    s.status = "active"
  end
  unless saas.saas_contract
    saas.create_saas_contract!(
      vendor: "#{data[:name]} Inc.",
      billing_cycle: "yearly",
      plan_name: "Business",
      price_cents: rand(500..5000) * 100,
      started_on: rand(6..24).months.ago.to_date,
      expires_on: rand(3..12).months.from_now.to_date
    )
  end
end

# 不動産管理 (11件)
realestate_saases_data = [
  { name: "いえらぶCLOUD", url: "https://ielove-cloud.jp", description: "不動産業務支援クラウド" },
  { name: "賃貸革命", url: "https://www.n-create.co.jp", description: "賃貸管理システム" },
  { name: "ESいい物件One", url: "https://www.es-service.net", description: "不動産流通プラットフォーム" },
  { name: "@プロパティ", url: "https://at-property.com", description: "不動産管理システム" },
  { name: "ATBB", url: "https://atbb.athome.co.jp", description: "不動産業者間サイト" },
  { name: "楽待", url: "https://www.rakumachi.jp", description: "投資用不動産ポータル" },
  { name: "SUUMO Business", url: "https://business.suumo.jp", description: "SUUMO掲載管理" },
  { name: "レインズ", url: "https://system.reins.jp", description: "不動産流通標準情報システム" },
  { name: "イタンジ", url: "https://www.itandi.co.jp", description: "不動産テックプラットフォーム" },
  { name: "きまRoom", url: "https://kimaroom.jp", description: "内見予約・顧客管理" },
  { name: "不動産BB", url: "https://www.fudousan.ne.jp", description: "不動産業者間物件流通" }
]

realestate_saases_data.each do |data|
  saas = Saas.find_or_create_by!(name: data[:name]) do |s|
    s.category = "不動産管理"
    s.url = data[:url]
    s.description = data[:description]
    s.owner = it_user
    s.status = "active"
  end
  unless saas.saas_contract
    saas.create_saas_contract!(
      vendor: data[:name],
      billing_cycle: "monthly",
      plan_name: "Standard",
      price_cents: rand(1000..10000) * 100,
      started_on: rand(6..24).months.ago.to_date,
      expires_on: rand(3..12).months.from_now.to_date
    )
  end
end

# バックオフィス (5件)
backoffice_saases_data = [
  { name: "freee会計", url: "https://www.freee.co.jp", description: "クラウド会計ソフト" },
  { name: "SmartHR", url: "https://smarthr.jp", description: "労務管理・年末調整" },
  { name: "KING OF TIME", url: "https://www.kingtime.jp", description: "勤怠管理" },
  { name: "バクラク", url: "https://bakuraku.jp", description: "請求書・経費精算" },
  { name: "マネーフォワード", url: "https://biz.moneyforward.com", description: "経理・人事クラウド" }
]

backoffice_saases_data.each do |data|
  saas = Saas.find_or_create_by!(name: data[:name]) do |s|
    s.category = "バックオフィス"
    s.url = data[:url]
    s.description = data[:description]
    s.owner = users[7] # 山田 (管理部)
    s.status = "active"
  end
  unless saas.saas_contract
    saas.create_saas_contract!(
      vendor: data[:name],
      billing_cycle: "yearly",
      plan_name: "Business",
      price_cents: rand(500..3000) * 100,
      started_on: rand(6..24).months.ago.to_date,
      expires_on: rand(3..12).months.from_now.to_date
    )
  end
end

puts "  SaaS: #{Saas.count}"

# --- SaaS Accounts ---
all_saases = Saas.all.to_a

# 全社共通SaaS（全員にアカウント割り当て）
common_saas_names = %w[Slack Google\ Workspace Microsoft\ 365 1Password KING\ OF\ TIME]
common_saases = all_saases.select { |s| common_saas_names.include?(s.name) }

users.each do |user|
  # 全社共通SaaS
  common_saases.each do |saas|
    SaasAccount.find_or_create_by!(saas: saas, user: user) do |a|
      a.account_email = user.email
      a.role = user.admin? ? "admin" : "member"
      a.status = "active"
      a.last_login_at = rand(1..30).days.ago
    end
  end

  # 部門別SaaS
  dept_saases = case user.department
  when "営業部"
    all_saases.select { |s| %w[Salesforce いえらぶCLOUD 賃貸革命 ATBB レインズ イタンジ].include?(s.name) }.sample(rand(3..5))
  when "情報システム部"
    all_saases.select { |s| %w[GitHub Jira Confluence Notion Box].include?(s.name) }
  when "管理部"
    all_saases.select { |s| %w[freee会計 SmartHR バクラク マネーフォワード DocuSign].include?(s.name) }.sample(rand(2..4))
  when "企画部"
    all_saases.select { |s| %w[Notion Canva Zoom ChatGPT\ Enterprise Confluence].include?(s.name) }.sample(rand(2..4))
  when "経営企画室"
    all_saases.select { |s| %w[Salesforce Notion freee会計 Box].include?(s.name) }
  else
    []
  end

  dept_saases.each do |saas|
    SaasAccount.find_or_create_by!(saas: saas, user: user) do |a|
      a.account_email = user.email
      a.role = "member"
      a.status = "active"
      a.last_login_at = rand(1..60).days.ago
    end
  end
end

puts "  SaaS Accounts: #{SaasAccount.count}"

# --- Task Presets ---
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
  onboarding_preset.task_preset_items.find_or_create_by!(description: item_data[:description]) do |i|
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

# --- Sample Tasks ---
# 完了済みタスク
unless Task.exists?(title: "伊藤 健太の退職処理")
  task1 = Task.create!(
    title: "伊藤 健太の退職処理",
    task_type: "offboarding",
    target_user: users[5], # 伊藤
    created_by: admin_user,
    status: "completed",
    due_date: 1.week.ago.to_date
  )
  users[5].saas_accounts.where(status: "active").includes(:saas).each do |account|
    task1.task_items.create!(
      action_type: "account_delete",
      description: "#{account.saas.name} アカウント削除",
      saas: account.saas,
      assignee: it_user,
      status: "completed",
      completed_at: 3.days.ago
    )
  end
  task1.task_items.create!(action_type: "pc_return", description: "PC返却", assignee: admin_user, status: "completed", completed_at: 2.days.ago)
  task1.task_items.create!(action_type: "nda", description: "機密保持契約締結", status: "completed", completed_at: 1.day.ago)
end

# 進行中タスク
unless Task.exists?(title: "松本 さくらの異動処理")
  task2 = Task.create!(
    title: "松本 さくらの異動処理",
    task_type: "transfer",
    target_user: users[12], # 松本
    created_by: admin_user,
    status: "in_progress",
    due_date: 1.week.from_now.to_date
  )
  task2.task_items.create!(action_type: "other", description: "企画部のSaaSアカウント権限確認", assignee: it_user, status: "completed", completed_at: 1.day.ago)
  task2.task_items.create!(action_type: "account_create", description: "営業部用SaaSアカウント追加", assignee: it_user, status: "pending")
  task2.task_items.create!(action_type: "account_delete", description: "不要アカウントの削除", assignee: it_user, status: "pending")
end

puts "  Tasks: #{Task.count}"

# --- Sample Surveys ---
# 完了済みサーベイ
unless Survey.exists?(title: "2025年Q4 アカウント棚卸し")
  survey1 = Survey.create!(
    title: "2025年Q4 アカウント棚卸し",
    survey_type: "account_review",
    created_by: admin_user,
    status: "closed",
    sent_at: 2.months.ago,
    deadline: 6.weeks.ago
  )
  SaasAccount.where(status: "active").limit(30).includes(:user, :saas).each do |account|
    survey1.survey_responses.create!(
      user: account.user,
      saas_account: account,
      response: %w[using using using not_using].sample,
      responded_at: rand(1..14).days.ago
    )
  end
end

# 進行中サーベイ
unless Survey.exists?(title: "2026年Q1 アカウント棚卸し")
  survey2 = Survey.create!(
    title: "2026年Q1 アカウント棚卸し",
    survey_type: "account_review",
    created_by: admin_user,
    status: "active",
    sent_at: 3.days.ago,
    deadline: 1.week.from_now
  )
  SaasAccount.where(status: "active").includes(:user, :saas).each do |account|
    responded = [ true, true, false ].sample
    survey2.survey_responses.create!(
      user: account.user,
      saas_account: account,
      response: responded ? %w[using using not_using].sample : nil,
      responded_at: responded ? rand(1..3).days.ago : nil
    )
  end
end

puts "  Surveys: #{Survey.count}"

# --- Sample Approval Requests ---
unless ApprovalRequest.count >= 4
  ApprovalRequest.delete_all

  # 承認済み (2件)
  ApprovalRequest.create!(
    request_type: "add_account",
    requester: users[3], # 田中
    saas: Saas.find_by(name: "Notion"),
    reason: "営業部のナレッジ共有のため、Notionアカウントを追加したい。",
    estimated_cost: 1000,
    user_count: 1,
    approver: it_user,
    status: "approved",
    approved_by: admin_user,
    approved_at: 1.week.ago
  )

  ApprovalRequest.create!(
    request_type: "add_account",
    requester: users[10], # 加藤
    saas: Saas.find_by(name: "ChatGPT Enterprise"),
    reason: "企画部でのAI活用推進のため、ChatGPTアカウントを追加したい。",
    estimated_cost: 3000,
    user_count: 3,
    approver: it_user,
    status: "approved",
    approved_by: admin_user,
    approved_at: 3.days.ago
  )

  # 却下 (1件)
  ApprovalRequest.create!(
    request_type: "new_saas",
    requester: users[7], # 山田
    saas_name: "Figma",
    reason: "デザインチームで利用するUI/UXデザインツール。現在PowerPointで代用しているが効率が悪い。",
    estimated_cost: 5000,
    user_count: 3,
    approver: it_user,
    status: "rejected",
    approved_by: admin_user,
    approved_at: 5.days.ago,
    rejection_reason: "コストが予算を超過しているため、まずはCanvaの無料プランで検証をお願いします。"
  )

  # 保留中 (1件)
  ApprovalRequest.create!(
    request_type: "new_saas",
    requester: users[11], # 吉田
    saas_name: "Miro",
    reason: "リモートでのブレスト・ワークショップ用にオンラインホワイトボードを導入したい。",
    estimated_cost: 2000,
    user_count: 5,
    approver: it_user,
    status: "pending"
  )
end

puts "  Approval Requests: #{ApprovalRequest.count}"

# --- Sample Audit Logs (20件程度) ---
unless AuditLog.count >= 10
  audit_data = [
    { user: admin_user, action: "create", resource_type: "Saas", resource_id: Saas.first.id, changes_data: {}, ip_address: "192.168.1.10" },
    { user: it_user, action: "update", resource_type: "Saas", resource_id: Saas.second.id, changes_data: { "status" => %w[trial active] }, ip_address: "192.168.1.20" },
    { user: admin_user, action: "create", resource_type: "SaasAccount", resource_id: SaasAccount.first&.id || 1, changes_data: {}, ip_address: "192.168.1.10" },
    { user: it_user, action: "update", resource_type: "User", resource_id: users[3].id, changes_data: { "department" => %w[営業本部 営業部] }, ip_address: "192.168.1.20" },
    { user: admin_user, action: "create", resource_type: "Survey", resource_id: Survey.first&.id || 1, changes_data: {}, ip_address: "192.168.1.10" },
    { user: admin_user, action: "update", resource_type: "Survey", resource_id: Survey.first&.id || 1, changes_data: { "status" => %w[draft active] }, ip_address: "192.168.1.10" },
    { user: nil, action: "update", resource_type: "User", resource_id: users[5].id, changes_data: { "account_enabled" => [ true, false ] }, ip_address: nil },
    { user: admin_user, action: "create", resource_type: "Task", resource_id: Task.first&.id || 1, changes_data: {}, ip_address: "192.168.1.10" },
    { user: it_user, action: "update", resource_type: "TaskItem", resource_id: 1, changes_data: { "status" => %w[pending completed] }, ip_address: "192.168.1.20" },
    { user: users[3], action: "create", resource_type: "ApprovalRequest", resource_id: ApprovalRequest.first&.id || 1, changes_data: {}, ip_address: "192.168.1.30" },
    { user: admin_user, action: "update", resource_type: "ApprovalRequest", resource_id: ApprovalRequest.first&.id || 1, changes_data: { "status" => %w[pending approved] }, ip_address: "192.168.1.10" },
    { user: it_user, action: "create", resource_type: "SaasAccount", resource_id: SaasAccount.second&.id || 2, changes_data: {}, ip_address: "192.168.1.20" },
    { user: admin_user, action: "destroy", resource_type: "SaasAccount", resource_id: 999, changes_data: {}, ip_address: "192.168.1.10" },
    { user: it_user, action: "update", resource_type: "Saas", resource_id: Saas.third&.id || 3, changes_data: { "description" => [ "旧説明", "新説明" ] }, ip_address: "192.168.1.20" },
    { user: admin_user, action: "create", resource_type: "User", resource_id: users.last.id, changes_data: {}, ip_address: "192.168.1.10" },
    { user: nil, action: "update", resource_type: "User", resource_id: users[6].id, changes_data: { "last_signed_in_at" => [ nil, 1.day.ago.to_s ] }, ip_address: nil },
    { user: admin_user, action: "update", resource_type: "Task", resource_id: Task.first&.id || 1, changes_data: { "status" => %w[open in_progress] }, ip_address: "192.168.1.10" },
    { user: it_user, action: "update", resource_type: "SaasAccount", resource_id: SaasAccount.third&.id || 3, changes_data: { "role" => %w[member admin] }, ip_address: "192.168.1.20" },
    { user: admin_user, action: "create", resource_type: "Saas", resource_id: Saas.last.id, changes_data: {}, ip_address: "192.168.1.10" },
    { user: users[10], action: "create", resource_type: "ApprovalRequest", resource_id: ApprovalRequest.last&.id || 2, changes_data: {}, ip_address: "192.168.1.40" }
  ]

  audit_data.each_with_index do |data, i|
    AuditLog.create!(
      user: data[:user],
      action: data[:action],
      resource_type: data[:resource_type],
      resource_id: data[:resource_id],
      changes_data: data[:changes_data],
      ip_address: data[:ip_address],
      created_at: (20 - i).hours.ago
    )
  end
end

puts "  Audit Logs: #{AuditLog.count}"

puts "=== Done ==="
