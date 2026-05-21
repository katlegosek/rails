# frozen_string_literal: true

if Rails.env.production?
  Doorkeeper::Application.create_with(
    scopes: %w[read write],
    redirect_uri: "http://localhost:3000",
    uid: Doorkeeper::OAuth::Helpers::UniqueToken.generate,
    secret: Doorkeeper::OAuth::Helpers::UniqueToken.generate
  ).find_or_create_by!(name: "Template")
else
  Doorkeeper::Application.create_with(
    scopes: %w[read write],
    redirect_uri: "http://localhost:3000",
    uid: "nqAFzOUUniN8PCCZfzsRfMkDPIyc9KgreM96MymzPMA",
    secret: "jmNJE31IYCEKLt5621YMw6LOCGkwbzaNL4U1SU-G__Y"
  ).find_or_create_by!(name: "RailsViewTemplate")

  # Public mobile client (password grant via custom /api/mobile/v1/auth/login — no client secret in the app).
  # TODO(production): set FETZA_MOBILE_OAUTH_UID / FETZA_MOBILE_OAUTH_SECRET via env for each environment.
  Doorkeeper::Application.create_with(
    confidential: false,
    redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
    scopes: "",
    secret: ENV.fetch("FETZA_MOBILE_OAUTH_SECRET", Doorkeeper::OAuth::Helpers::UniqueToken.generate)
  ).find_or_create_by!(
    name: "Fetza Mobile",
    uid: ENV.fetch("FETZA_MOBILE_OAUTH_UID", "fetza-mobile-dev")
  )

  User.create_with(
    first_name: "Default",
    last_name: "User",
    password: "Password1!",
    role: "admin",
    otp_secret_key: User.otp_random_secret,
    confirmed_at: Time.zone.now
  ).find_or_create_by!(email: "user@fetza.test")

  users = []
  99.times do
    users << User.new(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.email,
      password: SecureRandom.base36,
      otp_secret_key: User.otp_random_secret,
      confirmed_at: Time.zone.now
    )
  end
  User.import users

  # --- Bill-splitting demo data (safe to rerun in development) ---
  BILL_SEED_MODELS = [
    ItemAssignment,
    ReceiptItem,
    ReceiptAdjustment,
    ReceiptProcessingRun,
    ReceiptImage,
    Receipt,
    BillParticipant,
    Bill
  ].freeze

  BILL_SEED_MODELS.each(&:delete_all)

  User.create_with(
    first_name: "Katlego",
    last_name: "Mokoena",
    password: "Password1!",
    role: "user",
    otp_secret_key: User.otp_random_secret,
    confirmed_at: Time.zone.now
  ).find_or_create_by!(email: "katlego@fetza.test")

  User.create_with(
    first_name: "Dev",
    last_name: "User",
    password: "password123",
    role: "user",
    otp_secret_key: User.otp_random_secret,
    confirmed_at: Time.zone.now
  ).find_or_create_by!(email: "dev@fetza.local")

  # Demo bills belong to the mobile dev user (sign in via POST /api/mobile/v1/auth/login).
  bill_owner = User.find_by(email: "dev@fetza.local") || User.order(:id).first

  def assign_equal_split(receipt_item, participants)
    count = participants.size
    return if count.zero?

    base, remainder = receipt_item.total_cents.divmod(count)
    participants.each_with_index do |participant, index|
      ItemAssignment.create!(
        receipt_item: receipt_item,
        bill_participant: participant,
        amount_cents: base + (index < remainder ? 1 : 0),
        split_method: :equal
      )
    end
  end

  def create_receipt_item(bill:, receipt:, name:, unit_price_cents:, quantity: 1, category: nil, icon_key: nil, position:, confidence: 0.95)
    total_cents = (unit_price_cents * quantity).round
    ReceiptItem.create!(
      bill: bill,
      receipt: receipt,
      name: name,
      quantity: quantity,
      unit_price_cents: unit_price_cents,
      total_cents: total_cents,
      category: category,
      icon_key: icon_key,
      position: position,
      confidence: confidence
    )
  end

  def adjustment_affects_total?(kind)
    case kind.to_sym
    when :subtotal, :tax
      false
    else
      true
    end
  end

  def create_adjustments(receipt, rows)
    rows.each_with_index do |row, index|
      ReceiptAdjustment.create!(
        receipt: receipt,
        label: row[:label],
        kind: row[:kind],
        amount_cents: row[:amount_cents],
        affects_total: row.fetch(:affects_total, adjustment_affects_total?(row[:kind])),
        position: index
      )
    end
  end

  RECEIPT_IMAGE_SEED_PATH = Rails.root.join("spec/fixtures/files/receipt.jpg").freeze

  def create_receipt_image!(receipt:, position:, capture_type:)
    receipt_image = ReceiptImage.new(
      receipt: receipt,
      position: position,
      capture_type: capture_type
    )

    receipt_image.image.attach(
      io: StringIO.new(File.binread(RECEIPT_IMAGE_SEED_PATH)),
      filename: "receipt.jpg",
      content_type: "image/jpeg"
    )

    receipt_image.save!
    receipt_image
  end

  def update_receipt_totals!(receipt, merchant_name:, items:)
    adjustments = receipt.receipt_adjustments.reload
    subtotal_cents = items.sum(&:total_cents)
    service_fee_cents = adjustments.select { |a| a.kind == "service_fee" }.sum(&:amount_cents)
    tax_cents = adjustments.select { |a| a.kind == "tax" }.sum(&:amount_cents)
    tip_cents = adjustments.select { |a| a.kind == "tip" }.sum(&:amount_cents)
    discount_cents = adjustments.select { |a| a.kind == "discount" }.sum(&:amount_cents)
    affecting_total = adjustments.select(&:affects_total).sum(&:amount_cents)
    total_cents = subtotal_cents + affecting_total

    receipt.update!(
      merchant_name: merchant_name,
      receipt_date: Date.current,
      subtotal_cents: subtotal_cents,
      service_fee_cents: service_fee_cents,
      tax_cents: tax_cents,
      tip_cents: tip_cents,
      discount_cents: discount_cents,
      total_cents: total_cents,
      currency: "ZAR"
    )
  end

  # Bill 1: Observatory Small Plates (partially assigned)
  observatory_bill = Bill.create!(user: bill_owner, status: :active, title: "Observatory Small Plates")
  observatory_receipt = Receipt.create!(bill: observatory_bill, status: :confirmed)

  observatory_participants = [
    BillParticipant.create!(
      bill: observatory_bill, name: "Katlego", initials: "KM",
      avatar_background_color: "#4F46E5", avatar_text_color: "#FFFFFF",
      seat_index: 0, is_host: true, settled: false
    ),
    BillParticipant.create!(
      bill: observatory_bill, name: "Sam", initials: "S",
      avatar_background_color: "#059669", avatar_text_color: "#FFFFFF",
      seat_index: 1, is_host: false, settled: false
    ),
    BillParticipant.create!(
      bill: observatory_bill, name: "Jordan", initials: "J",
      avatar_background_color: "#D97706", avatar_text_color: "#FFFFFF",
      seat_index: 2, is_host: false, settled: false
    )
  ]

  observatory_items = [
    create_receipt_item(
      bill: observatory_bill, receipt: observatory_receipt,
      name: "Burrata & Heirloom Tomato", unit_price_cents: 9_500, position: 0,
      category: "starter", icon_key: "plate"
    ),
    create_receipt_item(
      bill: observatory_bill, receipt: observatory_receipt,
      name: "Lamb Meatballs", unit_price_cents: 14_500, position: 1,
      category: "main", icon_key: "meat"
    ),
    create_receipt_item(
      bill: observatory_bill, receipt: observatory_receipt,
      name: "Wild Mushroom Risotto", unit_price_cents: 12_500, position: 2,
      category: "main", icon_key: "bowl"
    ),
    create_receipt_item(
      bill: observatory_bill, receipt: observatory_receipt,
      name: "House Red Wine (750ml)", unit_price_cents: 22_000, position: 3,
      category: "drinks", icon_key: "wine"
    )
  ]

  observatory_subtotal = observatory_items.sum(&:total_cents)
  create_adjustments(observatory_receipt, [
    { label: "Subtotal", kind: :subtotal, amount_cents: observatory_subtotal },
    { label: "VAT (15%)", kind: :tax, amount_cents: (observatory_subtotal * 0.15).round },
    { label: "Service charge (10%)", kind: :service_fee, amount_cents: (observatory_subtotal * 0.10).round },
    { label: "Tip", kind: :tip, amount_cents: 5_000 }
  ])
  update_receipt_totals!(observatory_receipt, merchant_name: "Observatory Restaurant", items: observatory_items)

  create_receipt_image!(receipt: observatory_receipt, position: 0, capture_type: "camera")

  ReceiptProcessingRun.create!(
    receipt: observatory_receipt,
    provider: "openai",
    status: :completed,
    raw_ocr_text: "Observatory Restaurant\nBurrata & Heirloom Tomato  R95.00\n...",
    raw_ai_response: { title: "Observatory Small Plates", merchant: "Observatory Restaurant", currency: "ZAR", item_count: 4 },
    started_at: 2.hours.ago,
    completed_at: 1.hour.ago
  )

  # Partial: only first two items assigned
  assign_equal_split(observatory_items[0], observatory_participants)
  ItemAssignment.create!(
    receipt_item: observatory_items[1],
    bill_participant: observatory_participants[0],
    amount_cents: observatory_items[1].total_cents,
    split_method: :custom
  )

  # Bill 2: Friday Night Out (fully assigned)
  friday_bill = Bill.create!(user: bill_owner, status: :active, title: "Friday Night Out")
  friday_receipt = Receipt.create!(bill: friday_bill, status: :confirmed)

  friday_participants = [
    BillParticipant.create!(
      bill: friday_bill, name: "Katlego", initials: "KM",
      avatar_background_color: "#4F46E5", avatar_text_color: "#FFFFFF",
      seat_index: 0, is_host: true, settled: true
    ),
    BillParticipant.create!(
      bill: friday_bill, name: "Alex", initials: "A",
      avatar_background_color: "#7C3AED", avatar_text_color: "#FFFFFF",
      seat_index: 1, is_host: false, settled: true
    ),
    BillParticipant.create!(
      bill: friday_bill, name: "Priya", initials: "P",
      avatar_background_color: "#DB2777", avatar_text_color: "#FFFFFF",
      seat_index: 2, is_host: false, settled: true
    ),
    BillParticipant.create!(
      bill: friday_bill, name: "Morgan", initials: "M",
      avatar_background_color: "#0891B2", avatar_text_color: "#FFFFFF",
      seat_index: 3, is_host: false, settled: true
    )
  ]

  friday_items = [
    create_receipt_item(
      bill: friday_bill, receipt: friday_receipt,
      name: "Classic Craft Burger", unit_price_cents: 16_500, position: 0,
      category: "main", icon_key: "burger"
    ),
    create_receipt_item(
      bill: friday_bill, receipt: friday_receipt,
      name: "Beer-Battered Fish & Chips", unit_price_cents: 15_500, position: 1,
      category: "main", icon_key: "fish"
    ),
    create_receipt_item(
      bill: friday_bill, receipt: friday_receipt,
      name: "Buffalo Chicken Wings", unit_price_cents: 9_500, position: 2,
      category: "starter", icon_key: "wings"
    ),
    create_receipt_item(
      bill: friday_bill, receipt: friday_receipt,
      name: "Caesar Salad", unit_price_cents: 8_500, position: 3,
      category: "side", icon_key: "salad"
    ),
    create_receipt_item(
      bill: friday_bill, receipt: friday_receipt,
      name: "Craft Beer", unit_price_cents: 6_000, quantity: 4, position: 4,
      category: "drinks", icon_key: "beer"
    )
  ]

  friday_subtotal = friday_items.sum(&:total_cents)
  create_adjustments(friday_receipt, [
    { label: "Subtotal", kind: :subtotal, amount_cents: friday_subtotal },
    { label: "VAT (15%)", kind: :tax, amount_cents: (friday_subtotal * 0.15).round },
    { label: "Tip", kind: :tip, amount_cents: 8_000 },
    { label: "Rounding", kind: :rounding, amount_cents: -50, affects_total: true }
  ])
  update_receipt_totals!(friday_receipt, merchant_name: "The Local Grill", items: friday_items)

  create_receipt_image!(receipt: friday_receipt, position: 0, capture_type: "camera")
  create_receipt_image!(receipt: friday_receipt, position: 1, capture_type: "gallery")

  ReceiptProcessingRun.create!(
    receipt: friday_receipt,
    provider: "openai",
    status: :completed,
    raw_ocr_text: "The Local Grill\nFriday Night Out tab...",
    raw_ai_response: { title: "Friday Night Out", merchant: "The Local Grill", currency: "ZAR", item_count: 5 },
    started_at: 1.day.ago,
    completed_at: 1.day.ago + 45.seconds
  )

  friday_items.each { |item| assign_equal_split(item, friday_participants) }

  puts "\n--- Bill-splitting seed summary ---"
  puts "Bills:              #{Bill.count}"
  puts "Receipt items:      #{ReceiptItem.count}"
  puts "Participants:       #{BillParticipant.count}"
  puts "Assignments:        #{ItemAssignment.count}"
  puts "  Observatory (#{observatory_bill.id}): #{observatory_items.count} items, #{ItemAssignment.where(receipt_item_id: observatory_items.map(&:id)).count} assignments (partial)"
  puts "  Friday Night Out (#{friday_bill.id}): #{friday_items.count} items, #{ItemAssignment.where(receipt_item_id: friday_items.map(&:id)).count} assignments (full)"
  puts "Bill owner (mobile dev): #{bill_owner.email}"
  puts "Mobile login: dev@fetza.local / password123"
  puts "-----------------------------------\n"
end
