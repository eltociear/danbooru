# frozen_string_literal: true

class IpBan < ApplicationRecord
  belongs_to :creator, class_name: "User"

  validate :validate_ip_addr
  validates :reason, presence: true

  before_save :create_mod_action

  deletable
  enum category: {
    full: 0,
    partial: 100,
  }, _suffix: "ban"

  def self.visible(user)
    if user.is_moderator?
      all
    else
      none
    end
  end

  def self.ip_matches(ip_addr)
    where("ip_addr >>= ?", ip_addr)
  end

  def self.hit!(category, ip_addr)
    ip_ban = active.where(category: category).ip_matches(ip_addr).first
    return false unless ip_ban

    IpBan.increment_counter(:hit_count, ip_ban.id, touch: [:last_hit_at])
    true
  end

  def self.search(params, current_user)
    q = search_attributes(params, [:id, :created_at, :updated_at, :ip_addr, :reason, :is_deleted, :category, :hit_count, :last_hit_at, :creator], current_user: current_user)

    case params[:order]
    when /\A(created_at|updated_at|last_hit_at)(?:_(asc|desc))?\z/i
      column = $1
      dir = $2 || :desc
      q = q.order(Arel.sql("#{column} #{dir} NULLS LAST")).order(id: :desc)
    else
      q = q.apply_default_order(params)
    end

    q
  end

  def create_mod_action
    if new_record?
      ModAction.log("created ip ban for #{ip_addr}", :ip_ban_create, creator)
    elsif is_deleted? == true && is_deleted_was == false
      ModAction.log("deleted ip ban for #{ip_addr}", :ip_ban_delete)
    elsif is_deleted? == false && is_deleted_was == true
      ModAction.log("undeleted ip ban for #{ip_addr}", :ip_ban_undelete)
    end
  end

  def validate_ip_addr
    if ip_addr.blank?
      errors.add(:ip_addr, "is invalid")
    elsif ip_addr.private? || ip_addr.loopback? || ip_addr.link_local?
      errors.add(:ip_addr, "must be a public address")
    elsif full_ban? && ip_addr.ipv4? && ip_addr.prefix < 24
      errors.add(:ip_addr, "may not have a subnet bigger than /24")
    elsif partial_ban? && ip_addr.ipv4? && ip_addr.prefix < 8
      errors.add(:ip_addr, "may not have a subnet bigger than /8")
    elsif full_ban? && ip_addr.ipv6? && ip_addr.prefix < 48
      errors.add(:ip_addr, "may not have a subnet bigger than /48")
    elsif partial_ban? && ip_addr.ipv6? && ip_addr.prefix < 20
      errors.add(:ip_addr, "may not have a subnet bigger than /20")
    elsif new_record? && IpBan.active.where(category: category).ip_matches(subnetted_ip).exists?
      errors.add(:ip_addr, "is already banned")
    end
  end

  def has_subnet?
    (ip_addr.ipv4? && ip_addr.prefix < 32) || (ip_addr.ipv6? && ip_addr.prefix < 128)
  end

  def subnetted_ip
    str = ip_addr.to_s
    str += "/" + ip_addr.prefix.to_s if has_subnet?
    str
  end

  def ip_addr=(ip_addr)
    super(ip_addr.strip)
  end

  def self.available_includes
    [:creator]
  end
end
